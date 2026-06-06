import 'dart:async';

import 'package:azlistview/azlistview.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/pages/contacts/group_profile_panel/group_profile_panel_logic.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_working_circle/openim_working_circle.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../core/controller/im_controller.dart';
import '../home/home_logic.dart';
import 'select_contacts/select_contacts_logic.dart';

class ContactsLogic extends GetxController
    with WorkingCircleBridge
    implements ViewUserProfileBridge, SelectContactsBridge, ScanBridge {
  final imLogic = Get.find<IMController>();
  final homeLogic = Get.find<HomeLogic>();

  // final organizationLogic = Get.find<OrganizationLogic>();
  final friendApplicationList = <UserInfo>[];
  final friendList = <ISUserInfo>[].obs;
  final userIDList = <String>[];
  late StreamSubscription delSub;
  late StreamSubscription addSub;
  late StreamSubscription infoChangedSub;

  // 添加刷新控制器
  final refreshController = RefreshController();

  int get friendApplicationCount =>
      homeLogic.unhandledFriendApplicationCount.value;

  int get groupApplicationCount =>
      homeLogic.unhandledGroupApplicationCount.value;

  // String? get organizationName => organizationLogic.organizationName;
  //
  // RxList<UserInDept> get myDeptList => organizationLogic.myDeptList;

  @override
  void onInit() {
    // 监听好友变化
    delSub = imLogic.friendDelSubject.listen(_delFriend);
    addSub = imLogic.friendAddSubject.listen(_addFriend);
    infoChangedSub = imLogic.friendInfoChangedSubject.listen(_friendInfoChanged);
    imLogic.onBlacklistAdd = _delFriend;
    imLogic.onBlacklistDeleted = _addFriend;

    // imLogic.friendApplicationSubject.listen((value) {
    //
    // });
    // 收到新的好友申请
    // imLogic.onFriendApplicationListAdded = (u) {
    //   getFriendApplicationList();
    // };
    // 删除好友申请记录
    // imLogic.onFriendApplicationListDeleted = (u) {
    //   getFriendApplicationList();
    // };
    /// 我的申请被拒绝了
    // imLogic.onFriendApplicationListRejected = (u) {
    //   getFriendApplicationList();
    // };
    // 我的申请被接受了
    // imLogic.onFriendApplicationListAccepted = (u) {
    //   getFriendApplicationList();
    // };
    PackageBridge.selectContactsBridge = this;
    PackageBridge.viewUserProfileBridge = this;
    PackageBridge.workingCircleBridge = this;
    PackageBridge.scanBridge = this;

    imLogic.momentsSubject.listen((value) {
      onRecvNewMessageForWorkingCircle?.call(value);
    });
    super.onInit();
  }

  @override
  void onReady() {
    _getFriendList();
    super.onReady();
  }

  @override
  void onClose() {
    delSub.cancel();
    addSub.cancel();
    infoChangedSub.cancel();
    PackageBridge.selectContactsBridge = null;
    PackageBridge.viewUserProfileBridge = null;
    PackageBridge.workingCircleBridge = null;
    PackageBridge.scanBridge = null;
    super.onClose();
  }

  void newFriend() => AppNavigator.startFriendRequests();

  void newGroup() => AppNavigator.startGroupRequests();

  void myFriend() => AppNavigator.startFriendList();

  void myGroup() => AppNavigator.startGroupList();

  void searchContacts() => AppNavigator.startGlobalSearch();

  void addContacts() => AppNavigator.startAddContactsMethod();

  void tagGroup() => AppNavigator.startTagGroup();

  void notificationIssued() => AppNavigator.startNotificationIssued();

  // void workMoments() => WNavigator.startWorkMomentsList();

  @override
  Future<T?>? selectContacts<T>(
    int type, {
    List<String>? defaultCheckedIDList,
    List? checkedList,
    List<String>? excludeIDList,
    bool openSelectedSheet = false,
    String? groupID,
    String? ex,
  }) =>
      AppNavigator.startSelectContacts(
        action: type == 0
            ? SelAction.whoCanWatch
            : (type == 1 ? SelAction.remindWhoToWatch : SelAction.meeting),
        defaultCheckedIDList: defaultCheckedIDList,
        checkedList: checkedList,
        excludeIDList: excludeIDList,
        openSelectedSheet: openSelectedSheet,
        groupID: groupID,
        ex: ex,
      );

  @override
  viewUserProfile(String userID, String? nickname, String? faceURL,
          [String? groupID]) =>
      AppNavigator.startUserProfilePane(
        userID: userID,
        nickname: nickname,
        faceURL: faceURL,
        groupID: groupID,
      );

  @override
  scanOutGroupID(String groupID) => AppNavigator.startGroupProfilePanel(
        groupID: groupID,
        joinGroupMethod: JoinGroupMethod.qrcode,
        offAndToNamed: true,
      );

  @override
  scanOutUserID(String userID) =>
      AppNavigator.startUserProfilePane(userID: userID, offAndToNamed: true);

  // 获取好友列表
  _getFriendList() async {
    final list = await OpenIM.iMManager.friendshipManager
        .getFriendListMap()
        .then((list) => list.where(_filterBlacklist))
        .then((list) => list.map((e) {
              final fullUser = FullUserInfo.fromJson(e);
              final user = fullUser.friendInfo != null
                  ? ISUserInfo.fromJson(fullUser.friendInfo!.toJson())
                  : ISUserInfo.fromJson(fullUser.publicInfo!.toJson());
              return user;
            }).toList())
        .then((list) => IMUtils.convertToAZList(list));

    onUserIDList(userIDList);
    friendList.assignAll(list.cast<ISUserInfo>());
  }

  // 刷新好友列表
  void refreshFriendList() async {
    try {
      await _getFriendList();
      refreshController.refreshCompleted();
    } catch (e) {
      refreshController.refreshFailed();
    }
  }

  void onUserIDList(List<String> userIDList) {}

  bool _filterBlacklist(e) {
    final user = FullUserInfo.fromJson(e);
    final isBlack = user.blackInfo != null;

    if (isBlack) {
      return false;
    } else {
      userIDList.add(user.userID);
      return true;
    }
  }

  _addFriend(dynamic user) {
    if (user is FriendInfo || user is BlacklistInfo) {
      _addUser(user.toJson());
    }
  }

  _delFriend(dynamic user) {
    if (user is FriendInfo || user is BlacklistInfo) {
      friendList.removeWhere((e) => e.userID == user.userID);
    }
  }

  _friendInfoChanged(FriendInfo user) {
    friendList.removeWhere((e) => e.userID == user.userID);
    _addUser(user.toJson());
  }

  void _addUser(Map<String, dynamic> json) {
    final info = ISUserInfo.fromJson(json);
    friendList.add(IMUtils.setAzPinyinAndTag(info) as ISUserInfo);

    // A-Z sort.
    SuspensionUtil.sortListBySuspensionTag(friendList);

    // show sus tag.
    SuspensionUtil.setShowSuspensionStatus(friendList);
  }

  void viewFriendInfo(ISUserInfo info) => AppNavigator.startUserProfilePane(
        userID: info.userID!,
      );

  void searchFriend() => AppNavigator.startSearchFriend();
}
