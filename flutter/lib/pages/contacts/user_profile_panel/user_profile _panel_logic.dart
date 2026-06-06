import 'dart:async';

import 'package:collection/collection.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_live/openim_live.dart';
import 'package:openim_working_circle/openim_working_circle.dart';
import 'package:sprintf/sprintf.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/controller/im_controller.dart';
import '../../chat/chat_logic.dart';
import '../../conversation/conversation_logic.dart';
import '../select_contacts/select_contacts_logic.dart';

class UserProfilePanelLogic extends GetxController {
  final appLogic = Get.find<AppController>();
  final imLogic = Get.find<IMController>();
  final conversationLogic = Get.find<ConversationLogic>();
  late Rx<UserFullInfo> userInfo;
  GroupMembersInfo? groupMembersInfo;
  GroupInfo? groupInfo;
  String? groupID;
  bool? offAllWhenDelFriend = false;
  final iHasMutePermissions = false.obs;
  final iAmOwner = false.obs;
  final mutedTime = "".obs;
  final onlineStatus = false.obs;
  final onlineStatusDesc = ''.obs;
  final groupUserNickname = "".obs;
  final joinGroupTime = 0.obs;
  final joinGroupMethod = ''.obs;
  final hasAdminPermission = false.obs;
  final notAllowLookGroupMemberProfiles = false.obs;
  final notAllowAddGroupMemberFriend = false.obs;
  final iHaveAdminOrOwnerPermission = false.obs;
  late StreamSubscription _friendAddedSub;
  late StreamSubscription _friendInfoChangedSub;
  late StreamSubscription _memberInfoChangedSub;

  @override
  void onClose() {
    _friendAddedSub.cancel();
    _friendInfoChangedSub.cancel();
    _memberInfoChangedSub.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    userInfo = (UserFullInfo()
          ..userID = Get.arguments['userID']
          ..nickname = Get.arguments['nickname']
          ..faceURL = Get.arguments['faceURL'])
        .obs;
    groupID = Get.arguments['groupID'];
    offAllWhenDelFriend = Get.arguments['offAllWhenDelFriend'];

    _friendAddedSub = imLogic.friendAddSubject.listen((user) {
      if (user.userID == userInfo.value.userID) {
        userInfo.update((val) {
          val?.isFriendship = true;
        });
      }
    });
    _friendInfoChangedSub = imLogic.friendInfoChangedSubject.listen((user) {
      if (user.userID == userInfo.value.userID) {
        userInfo.update((val) {
          val?.nickname = user.nickname;
          val?.remark = user.remark;
        });
      }
    });
    // 禁言时间被改变，或群成员资料改变
    _memberInfoChangedSub = imLogic.memberInfoChangedSubject.listen((value) {
      if (value.userID == userInfo.value.userID) {
        if (null != value.muteEndTime) {
          _calMuteTime(value.muteEndTime!);
        }
        groupUserNickname.value = value.nickname ?? '';
      }
    });
    super.onInit();
  }

  @override
  void onReady() {
    _getUsersInfo();
    _queryGroupInfo();
    _queryGroupMemberInfo();
    // _queryUserOnlineStatus();
    super.onReady();
  }

  /// 是当前登录用户的资料页
  bool get isMyself => userInfo.value.userID == OpenIM.iMManager.userID;

  /// 当前是群成员资料页面
  bool get isGroupMemberPage => null != groupID && groupID!.isNotEmpty;

  bool get isFriendship => userInfo.value.isFriendship;

  ///用户是否允许添加好友
  /// 如果 allowAddFriend 为 null（网络请求失败或未加载），默认返回 true 以显示按钮
  /// 如果 allowAddFriend 为 0，返回 false（不允许添加）
  /// 如果 allowAddFriend 为 1，返回 true（允许添加）
  bool get isAllowAddFriend {
    final allowAddFriend = userInfo.value.allowAddFriend;
    // 如果为 null，默认允许显示按钮（避免因网络问题导致按钮不显示）
    if (allowAddFriend == null) return true;
    return allowAddFriend == 1;
  }

  /// 是否能给非好友发送消息
  bool get allowSendMsgNotFriend =>
      null == appLogic.clientConfigMap['allowSendMsgNotFriend'] || appLogic.clientConfigMap['allowSendMsgNotFriend'] == '1';

  void _getUsersInfo() async {
    final userID = userInfo.value.userID!;
    final list = await OpenIM.iMManager.userManager.getUsersInfoWithCache(
      [userID],
    );
    final user = list.firstOrNull;

    final isFriendship = user?.friendInfo != null;
    final isBlack = user?.blackInfo != null;

    // 先更新用户基本信息（不依赖网络请求）
    if (null != user) {
      userInfo.update((val) {
        val?.nickname = user.nickname;
        val?.faceURL = user.faceURL;
        val?.remark = user.friendInfo?.remark;
        val?.isBlacklist = isBlack;
        val?.isFriendship = isFriendship;
      });
    }

    // 尝试获取用户完整信息（包括 allowAddFriend）
    // 如果网络请求失败，allowAddFriend 保持为 null，isAllowAddFriend 会返回 true 以显示按钮
    try {
      final list2 = await Apis.getUserFullInfo(userIDList: [userID]);
      final fullInfo = list2?.firstOrNull;
      if (null != fullInfo) {
        userInfo.update((val) {
          val?.allowAddFriend = fullInfo.allowAddFriend;
        });
      }
    } catch (e) {
      // 网络请求失败时，不更新 allowAddFriend，保持为 null
      // isAllowAddFriend 会返回 true，确保按钮能够显示
    }
  }

  _queryGroupInfo() async {
    if (isGroupMemberPage) {
      var list = await OpenIM.iMManager.groupManager.getGroupsInfo(
        groupIDList: [groupID!],
      );
      groupInfo = list.firstOrNull;
      // 不允许查看群成员资料
      notAllowLookGroupMemberProfiles.value = groupInfo?.lookMemberInfo == 1;
      // 不允许添加组成员为好友
      notAllowAddGroupMemberFriend.value = groupInfo?.applyMemberFriend == 1;
    }
  }

  /// 查询我与当前页面用户的群成员信息
  _queryGroupMemberInfo() async {
    if (isGroupMemberPage) {
      final list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
        groupID: groupID!,
        userIDList: [userInfo.value.userID!, if (!isMyself) OpenIM.iMManager.userID],
      );
      final other = list.firstWhereOrNull((e) => e.userID == userInfo.value.userID);
      groupMembersInfo = other;
      groupUserNickname.value = other?.nickname ?? '';
      joinGroupTime.value = other?.joinTime ?? 0;

      _getJoinGroupMethod(other);

      hasAdminPermission.value = other?.roleLevel == GroupRoleLevel.admin;

      // 是我查看其他人的资料
      if (!isMyself) {
        var me = list.firstWhereOrNull((e) => e.userID == OpenIM.iMManager.userID);
        // 只有群主可以设置管理员
        iAmOwner.value = me?.roleLevel == GroupRoleLevel.owner;
        // 群主禁言（取消禁言）管理员和普通成员，管理员只能禁言（取消禁言）普通成员
        iHasMutePermissions.value =
            me?.roleLevel == GroupRoleLevel.owner || (me?.roleLevel == GroupRoleLevel.admin && other?.roleLevel == GroupRoleLevel.member);
        // 我是管理员或群主
        iHaveAdminOrOwnerPermission.value = me?.roleLevel == GroupRoleLevel.owner || me?.roleLevel == GroupRoleLevel.admin;
      }

      if (null != other && null != other.muteEndTime && other.muteEndTime! > 0) {
        _calMuteTime(other.muteEndTime!);
      }
    }
  }

  _getJoinGroupMethod(GroupMembersInfo? other) async {
    // 入群方式 2：邀请加入 3：搜索加入 4：通过二维码加入
    if (other?.joinSource == 2) {
      if (other!.inviterUserID != null && other.inviterUserID != other.userID) {
        final list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
          groupID: groupID!,
          userIDList: [other.inviterUserID!],
        );
        var inviterUserInfo = list.firstOrNull;
        joinGroupMethod.value = sprintf(
          StrRes.byInviteJoinGroup,
          [inviterUserInfo?.nickname ?? ''],
        );
      }
    } else if (other?.joinSource == 3) {
      joinGroupMethod.value = StrRes.byIDJoinGroup;
    } else if (other?.joinSource == 4) {
      joinGroupMethod.value = StrRes.byQrcodeJoinGroup;
    }
  }

  /// 禁言时长
  _calMuteTime(int time) {
    var date = DateUtil.formatDateMs(time, format: IMUtils.getTimeFormat2());
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var diff = time - now;
    if (diff > 0) {
      mutedTime.value = date;
    } else {
      mutedTime.value = "";
    }
  }

  /// 在线状态
  _queryUserOnlineStatus() {
    Apis.queryUserOnlineStatus(
      uidList: [userInfo.value.userID!],
      onlineStatusCallback: (map) {
        onlineStatus.value = map[userInfo.value.userID!]!;
      },
      onlineStatusDescCallback: (map) {
        onlineStatusDesc.value = map[userInfo.value.userID!]!;
      },
    );
  }

  String getShowName() {
    if (isGroupMemberPage) {
      if (isFriendship) {
        // if (userInfo.value.nickname != groupUserNickname.value) {
        //   return '${groupUserNickname.value}(${IMUtils.emptyStrToNull(userInfo.value.remark) ?? userInfo.value.nickname})';
        // } else {
        //   if (userInfo.value.remark != null &&
        //       userInfo.value.remark!.isNotEmpty) {
        //     return '${groupUserNickname.value}(${IMUtils.emptyStrToNull(userInfo.value.remark)})';
        //   }
        // }
        if (null != IMUtils.emptyStrToNull(userInfo.value.remark)) {
          return '${groupUserNickname.value}(${IMUtils.emptyStrToNull(userInfo.value.remark)})';
        }
      }
      if (groupUserNickname.value.isEmpty) {
        return userInfo.value.nickname ??= "";
      }
      return groupUserNickname.value;
    }
    if (userInfo.value.remark != null && userInfo.value.remark!.isNotEmpty) {
      return '${userInfo.value.nickname}(${userInfo.value.remark})';
    }
    return userInfo.value.nickname ?? '';
  }

  /// 设置为管理员
  void toggleAdmin() async {
    final hasPermission = !hasAdminPermission.value;
    final roleLevel = hasPermission ? GroupRoleLevel.admin : GroupRoleLevel.member;
    await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.setGroupMemberRoleLevel(
              groupID: groupID!,
              userID: userInfo.value.userID!,
              roleLevel: roleLevel,
            ));

    groupMembersInfo?.roleLevel = roleLevel;
    hasAdminPermission.value = hasPermission;
    // 更新其他界面群成员权限
    if (null != groupMembersInfo) {
      imLogic.memberInfoChangedSubject.add(groupMembersInfo!);
    }
    IMViews.showToast(StrRes.setSuccessfully);
  }

  void toChat() {
    conversationLogic.toChat(
      userID: userInfo.value.userID,
      nickname: userInfo.value.showName,
      faceURL: userInfo.value.faceURL,
    );
  }

  void toCall() {
    IMViews.openIMCallSheet(userInfo.value.showName, (index) {
      imLogic.call(
        callObj: CallObj.single,
        callType: index == 0 ? CallType.audio : CallType.video,
        inviteeUserIDList: [userInfo.value.userID!],
      );
    });
  }

  /// 群主禁言（取消禁言）管理员和普通成员，管理员只能禁言（取消禁言）普通成员
  void setMute() => AppNavigator.startSetMuteForGroupMember(
        groupID: groupID!,
        userID: userInfo.value.userID!,
      );

  void copyID() {
    IMUtils.copy(text: userInfo.value.userID!);
  }

  void addFriend() => AppNavigator.startSendVerificationApplication(
        userID: userInfo.value.userID!,
      );

  void viewPersonalInfo() => AppNavigator.startPersonalInfo(
        userID: userInfo.value.userID!,
      );

  void friendSetup() => AppNavigator.startFriendSetup(
        userID: userInfo.value.userID!,
      );

  void viewDynamics() => WNavigator.startUserWorkMomentsList(
        userID: userInfo.value.userID!,
        nickname: userInfo.value.showName,
        faceURL: userInfo.value.faceURL,
      );

  // ==================== 好友设置功能 ====================

  void toggleBlacklist() {
    if (userInfo.value.isBlacklist == true) {
      removeBlacklist();
    } else {
      addBlacklist();
    }
  }

  /// 加入黑名单
  void addBlacklist() async {
    var confirm = await Get.dialog(CustomDialog(title: StrRes.areYouSureAddBlacklist));
    if (confirm == true) {
      await OpenIM.iMManager.friendshipManager.addBlacklist(
        userID: userInfo.value.userID!,
      );
      userInfo.update((val) {
        val?.isBlacklist = true;
      });
    }
  }

  /// 从黑名单移除
  void removeBlacklist() async {
    await OpenIM.iMManager.friendshipManager.removeBlacklist(
      userID: userInfo.value.userID!,
    );
    userInfo.update((val) {
      val?.isBlacklist = false;
    });
  }

  /// 解除好友关系
  void deleteFromFriendList() async {
    var confirm = await Get.dialog(CustomDialog(
      title: StrRes.areYouSureDelFriend,
      rightText: StrRes.delete,
    ));
    if (confirm) {
      await LoadingView.singleton.wrap(asyncFunction: () async {
        await OpenIM.iMManager.friendshipManager.deleteFriend(
          userID: userInfo.value.userID!,
        );
        userInfo.update((val) {
          val?.isFriendship = false;
        });
        final userIDList = [
          userInfo.value.userID,
          OpenIM.iMManager.userID,
        ];
        userIDList.sort();
        final conversationID = 'si_${userIDList.join('_')}';
        // 删除会话
        await OpenIM.iMManager.conversationManager.deleteConversationAndDeleteAllMsg(conversationID: conversationID);
        // 删除会话列表数据
        final conversationLogic = Get.find<ConversationLogic>();
        conversationLogic.list.removeWhere((e) => e.conversationID == conversationID);
      });
      // 如果从聊天窗口查看用户资料
      if (offAllWhenDelFriend == true) {
        AppNavigator.startBackMain();
      } else {
        Get.back();
      }
    }
  }

  /// 推荐给朋友
  recommendToFriend() async {
    // 检查是否在聊天页面，如果是则直接推荐
    final isRegistered = Get.isRegistered<ChatLogic>(tag: GetTags.chat);
    if (isRegistered) {
      final logic = Get.find<ChatLogic>(tag: GetTags.chat);
      logic.recommendFriendCarte(UserInfo.fromJson(userInfo.value.toJson()));
      return;
    }
    final result = await AppNavigator.startSelectContacts(
      action: SelAction.recommend,
      ex: '[${StrRes.carte}]${userInfo.value.nickname}',
    );
    if (null != result) {
      final customEx = result['customEx'];
      final checkedList = result['checkedList'];
      for (var info in checkedList) {
        final userID = IMUtils.convertCheckedToUserID(info);
        final groupID = IMUtils.convertCheckedToGroupID(info);
        if (customEx is String && customEx.isNotEmpty) {
          // 推荐备注消息
          OpenIM.iMManager.messageManager.sendMessage(
            message: await OpenIM.iMManager.messageManager.createTextMessage(
              text: customEx,
            ),
            userID: userID,
            groupID: groupID,
            offlinePushInfo: Config.offlinePushInfo,
          );
        }
        // 名片消息
        OpenIM.iMManager.messageManager.sendMessage(
          message: await OpenIM.iMManager.messageManager.createCardMessage(
            userID: userInfo.value.userID!,
            nickname: userInfo.value.showName,
            faceURL: userInfo.value.faceURL,
          ),
          userID: userID,
          groupID: groupID,
          offlinePushInfo: Config.offlinePushInfo,
        );
      }
    }
  }

  /// 设置好友备注
  void setFriendRemark() => AppNavigator.startSetFriendRemark();
}
