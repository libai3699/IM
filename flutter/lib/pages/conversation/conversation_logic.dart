import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_meeting/openim_meeting.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/im_callback.dart';
import '../../routes/app_navigator.dart';
import '../contacts/add_by_search/add_by_search_logic.dart';
import '../home/home_logic.dart';

class ConversationLogic extends GetxController {
  final popCtrl = CustomPopupMenuController();
  final list = <ConversationInfo>[].obs;
  final imLogic = Get.find<IMController>();
  final homeLogic = Get.find<HomeLogic>();
  final appLogic = Get.find<AppController>();
  final refreshController = RefreshController();
  final tempDraftText = <String, String>{};
  final pageSize = 40;

  final imStatus = IMSdkStatus.connecting.obs;
  bool _isSwitchingLine = false; // 是否正在切换线路

  late AutoScrollController scrollController;
  int scrollIndex = -1;

  @override
  void onInit() {
    scrollController = AutoScrollController(axis: Axis.vertical);
    
    // 监听会话变化
    imLogic.conversationAddedSubject.listen((conversations) {
      onChanged(conversations);
      // 如果能收到消息，说明已经连接成功，同步状态
      _syncConnectionStatus();
    });
    
    imLogic.conversationChangedSubject.listen((conversations) {
      onChanged(conversations);
      // 如果能收到消息，说明已经连接成功，同步状态
      _syncConnectionStatus();
    });
    
    homeLogic.onScrollToUnreadMessage = scrollTo;
    
    // 监听 IM SDK 的连接状态变化（这是真实的连接状态）
    imLogic.imSdkStatusSubject.listen((value) {
      // Logger.print('[ConversationLogic] ========== 收到状态更新 ==========');
      // Logger.print('[ConversationLogic] 新状态: $value');
      // Logger.print('[ConversationLogic] 旧状态: ${imStatus.value}');
      // Logger.print('[ConversationLogic] 状态文本: ${_getStatusText(value)}');
      imStatus.value = value;
    });
    
    super.onInit();
  }


  

  
  /// 强制设置连接状态（用于测试）
  void forceSetConnectionStatus(IMSdkStatus status) {
    // Logger.print('强制设置连接状态: $status');
    imLogic.imSdkStatus(status);
  }

  /// 刷新线路配置（给UI调用）
  Future<void> refreshLineConfig() async {
    Logger.print('[线路配置] 手动刷新线路配置...');
    await _loadDynamicLineConfig();
  }
  
  /// 动态获取线路配置（竞速模式：哪个快用哪个）
  Future<void> _loadDynamicLineConfig() async {
    // 添加时间戳参数绕过缓存（确保获取最新配置）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final configUrls = [
      // Gitee（国内访问快，实时）
      'https://gitee.com/monday0052/app-config/raw/master/config/line-config.json?t=$timestamp',
      
      // GitHub（国外访问快，实时）
      'https://raw.githubusercontent.com/ondaym478-cell/app-config/main/config/line-config.json?t=$timestamp',
    ];

    Logger.print('[线路配置] 🏁 启动竞速模式，同时请求 ${configUrls.length} 个源...');
    
    try {
      // 创建所有请求的 Future
      final futures = configUrls.map((url) => _fetchConfigFromUrl(url)).toList();
      
      // 使用 Future.any：哪个先成功就用哪个
      final result = await Future.any(futures);
      
      if (result != null && result.isNotEmpty) {
        await _updateLineConfig(result);
        Logger.print('[线路配置] ✅ 动态线路配置加载成功（竞速模式）');
        IMViews.showToast('线路配置已更新');
        return;
      }
    } catch (e) {
      Logger.print('[线路配置] ❌ 所有源都失败: $e');
      IMViews.showToast('获取线路配置失败');
    }
  }
  
  /// 从单个URL获取配置（用于竞速模式）
  Future<List<String>?> _fetchConfigFromUrl(String url) async {
    try {
      Logger.print('[线路配置] 🚀 竞速请求: $url');
      
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          responseType: ResponseType.json,
        ),
      );
      
      if (response.statusCode == 200) {
        Logger.print('[线路配置] ✅ $url 响应成功');
        
        final lines = _parseLineConfig(response.data);
        
        if (lines.isNotEmpty) {
          Logger.print('[线路配置] 🏆 $url 胜出！解析到 ${lines.length} 个域名');
          return lines;
        }
      }
    } catch (e) {
      // 超时是正常的（其他源已经成功），不需要详细日志
      if (e.toString().contains('timeout')) {
        Logger.print('[线路配置] ⏱️ $url 超时（其他源已响应）');
      } else {
        Logger.print('[线路配置] ❌ $url 失败: $e');
      }
    }
    
    throw Exception('Failed to fetch from $url');
  }
  
  /// 解析线路配置
  List<String> _parseLineConfig(dynamic responseData) {
    try {
      Logger.print('[线路配置] 开始解析响应数据...');
      
      dynamic jsonData;
      
      // 处理不同类型的响应数据
      if (responseData is String) {
        // 如果是字符串，尝试解析 JSON
        Logger.print('[线路配置] 响应数据类型: String');
        jsonData = json.decode(responseData);
      } else if (responseData is Map) {
        // 如果已经是 Map，直接使用
        Logger.print('[线路配置] 响应数据类型: Map');
        jsonData = responseData;
      } else {
        Logger.print('[线路配置] ⚠️ 未知的响应数据类型: ${responseData.runtimeType}');
        return [];
      }
      
      if (jsonData is Map && jsonData.containsKey('lines')) {
        final linesData = jsonData['lines'] as List;
        final domains = <String>[];
        
        for (var line in linesData) {
          if (line is Map && line.containsKey('domian')) {
            final domain = line['domian'].toString().trim();
            if (domain.isNotEmpty) {
              domains.add(domain);
              Logger.print('[线路配置] 解析到域名: $domain');
            }
          }
        }
        
        Logger.print('[线路配置] 共解析到 ${domains.length} 个域名');
        return domains;
      }
      
      Logger.print('[线路配置] ⚠️ 配置格式错误，缺少 lines 字段');
    } catch (e, stackTrace) {
      Logger.print('[线路配置] ❌ 解析失败: $e');
      Logger.print('[线路配置] StackTrace: $stackTrace');
    }
    
    return [];
  }
  
  /// 更新线路配置
  Future<void> _updateLineConfig(List<String> lines) async {
    try {
      if (lines.isEmpty) return;
      
      // 构建新的线路配置
      final newLines = <Map<String, String>>[];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineName = i == 0 ? '主线路' : '备用线路$i';
        
        newLines.add({
          'name': lineName,
          'serverIP': line,
          'authUrl': 'https://$line/chat',
          'apiUrl': 'https://$line/api',
          'wsUrl': 'wss://$line/msg_gateway',
        });
      }
      
      Logger.print('更新线路配置: $newLines');
      
      // 保存到本地存储
      await DataSp.putDynamicLineConfig(newLines);
      
      // 如果当前没有选择线路，默认选择第一个
      final currentIndex = DataSp.getCurrentLineIndex();
      if (currentIndex == null) {
        await Config.setCurrentLineIndex(0);
      }
    } catch (e) {
      Logger.print('更新线路配置失败: $e');
    }
  }

  /// 切换线路
  void switchLine(int index) async {
    // 防止重复切换
    if (_isSwitchingLine) {
      Logger.print('[ConversationLogic] 正在切换线路中，忽略新的切换请求');
      IMViews.showToast('切换线路中');
      return;
    }
    
    try {
      _isSwitchingLine = true;
      
      final lineConfig = Config.presetLines[index];
      Logger.print('[ConversationLogic] ========================================');
      Logger.print('[ConversationLogic] 用户手动切换线路到索引: $index');
      Logger.print('[ConversationLogic] 线路名称: ${lineConfig['name']}');
      Logger.print('[ConversationLogic] 目标API URL: ${lineConfig['apiUrl']}');
      
      // 立即显示切换提示
      IMViews.showToast('正在切换到${lineConfig['name']}...');
      
      // 清除可能存在的服务器配置缓存
      await DataSp.putServerConfig({});
      Logger.print('[ConversationLogic] 已清除服务器配置缓存');
      
      // 保存线路索引
      await Config.setCurrentLineIndex(index);
      
      // 验证保存是否成功
      final savedIndex = DataSp.getCurrentLineIndex();
      Logger.print('[ConversationLogic] 保存后的线路索引: $savedIndex');
      Logger.print('[ConversationLogic] 新的API URL: ${Config.imApiUrl}');
      Logger.print('[ConversationLogic] 新的WS URL: ${Config.imWsUrl}');
      Logger.print('[ConversationLogic] ========================================');
      
      // 调用 IMController 的重新初始化方法
      Logger.print('[ConversationLogic] 开始调用 IMController.reinitializeSDK()');
      await imLogic.reinitializeSDK();
      
      // 立即重置切换标志
      _isSwitchingLine = false;
      
      // 只显示线路名称，不显示域名/服务器信息
      IMViews.showToast('✓ 已切换到${lineConfig['name']}');
      // Logger.print('[ConversationLogic] ✓ 线路切换完成');
    } catch (e) {
      // Logger.print('[ConversationLogic] ✗ 切换线路失败: $e');
      IMViews.showToast('切换线路失败');
      _isSwitchingLine = false;
    }
  }

  /// 会话列表通过回调更新
  void onChanged(newList) {
    for (var newValue in newList) {
      // promptSoundOrNotification(newValue);
      list.remove(newValue);
    }
    list.insertAll(0, newList);
    _sortConversationList();
  }

  /// 提示音
  void promptSoundOrNotification(ConversationInfo info) {
    if (imLogic.userInfo.value.globalRecvMsgOpt == 0 &&
        info.recvMsgOpt == 0 &&
        info.unreadCount > 0 &&
        info.latestMsg?.sendID != OpenIM.iMManager.userID) {
      appLogic.promptSoundOrNotification(info.latestMsg!.seq!);
    }
  }

  @override
  void onReady() {
    onRefresh();
    super.onReady();
  }

  String getConversationID(ConversationInfo info) {
    return info.conversationID;
  }

  /// 标记会话已读
  void markMessageHasRead(ConversationInfo info) {
    _markMessageHasRead(conversationID: info.conversationID);
  }

  /// 置顶会话
  void pinConversation(ConversationInfo info) async {
    OpenIM.iMManager.conversationManager.pinConversation(
      conversationID: info.conversationID,
      isPinned: !info.isPinned!,
    );
  }

  /// 删除会话
  void deleteConversation(ConversationInfo info) async {
    await OpenIM.iMManager.conversationManager.deleteConversationAndDeleteAllMsg(
      conversationID: info.conversationID,
    );
    list.remove(info);
  }

  /// 根据id移除会话
  void removeConversation(String id) {
    list.removeWhere((e) => e.conversationID == id);
  }

  /// 设置草稿
  void setConversationDraft({required String cid, required String draftText}) {
    OpenIM.iMManager.conversationManager.setConversationDraft(
      conversationID: cid,
      draftText: draftText,
    );
  }

  /// 会话前缀标签
  String? getPrefixTag(ConversationInfo info) {
    String? prefix;
    try {
      // 草稿
      if (null != info.draftText && '' != info.draftText) {
        var map = json.decode(info.draftText!);
        String text = map['text'];
        if (text.isNotEmpty) {
          prefix = '[${StrRes.draftText}]';
        }
      } else {
        switch (info.groupAtType) {
          case GroupAtType.atAll:
            prefix = '[@${StrRes.everyone}]';
            break;
          case GroupAtType.atAllAtMe:
            prefix = '[@${StrRes.everyone} @${StrRes.you}]';
            break;
          case GroupAtType.atMe:
            prefix = '[@${StrRes.you}]';
            break;
          case GroupAtType.atNormal:
            break;
          case GroupAtType.groupNotification:
            prefix = '[${StrRes.groupAc}]';
            break;
        }
      }
    } catch (e, s) {
      // Logger.print('e: $e  s: $s');
    }

    return prefix;
  }

  /// 解析消息内容
  String getContent(ConversationInfo info) {
    try {
      if (null != info.draftText && '' != info.draftText) {
        var map = json.decode(info.draftText!);
        String text = map['text'];
        if (text.isNotEmpty) {
          return text;
        }
      }

      if (null == info.latestMsg) return "";

      final text = IMUtils.parseNtf(info.latestMsg!, isConversation: true);
      if (text != null) return text;
      if (info.isSingleChat || info.latestMsg!.sendID == OpenIM.iMManager.userID) return IMUtils.parseMsg(info.latestMsg!, isConversation: true);

      return "${info.latestMsg!.senderNickname}: ${IMUtils.parseMsg(info.latestMsg!, isConversation: true)} ";
    } catch (e, s) {
      // Logger.print('------e:$e s:$s');
    }
    return '[${StrRes.unsupportedMessage}]';
  }

  Map<String, String> getAtUserMap(ConversationInfo info) {
    if (null != info.draftText && '' != info.draftText!.trim()) {
      var map = json.decode(info.draftText!);
      var atMap = map['at'];
      if (atMap.isNotEmpty && atMap is Map) {
        var v = <String, String>{};
        atMap.forEach((key, value) {
          v.addAll({'$key': "$value"});
        });
        return v;
      }
    }
    if (info.isGroupChat) {
      final map = <String, String>{};
      var message = info.latestMsg;
      if (message?.contentType == MessageType.atText) {
        var list = message!.atTextElem!.atUsersInfo;
        list?.forEach((e) {
          map[e.atUserID!] = e.groupNickname ?? e.atUserID!;
        });
      }
      return map;
    }
    return {};
  }

  /// 头像
  String? getAvatar(ConversationInfo info) {
    return info.faceURL;
  }

  bool isGroupChat(ConversationInfo info) {
    return info.isGroupChat;
  }

  /// 显示名
  String getShowName(ConversationInfo info) {
    if (info.showName == null || info.showName.isBlank!) {
      return info.userID!;
    }
    return info.showName!;
  }

  /// 时间
  String getTime(ConversationInfo info) {
    return IMUtils.getChatTimeline(info.latestMsgSendTime!);
  }

  /// 未读数
  int getUnreadCount(ConversationInfo info) {
    return info.unreadCount ?? 0;
  }

  bool existUnreadMsg(ConversationInfo info) {
    return getUnreadCount(info) > 0;
  }

  /// 判断置顶
  bool isPinned(ConversationInfo info) {
    return info.isPinned!;
  }

  bool isNotDisturb(ConversationInfo info) {
    return info.recvMsgOpt != 0;
  }

  bool isUserGroup(int index) => list.elementAt(index).isGroupChat;

  /// 草稿
  /// 聊天页调用，不通过onWillPop事件返回，因为该事件会拦截ios的左滑返回上一页。
  void updateDartText({
    String? conversationID,
    required String text,
  }) {
    if (null != conversationID) tempDraftText[conversationID] = text;
  }

  /// 清空未读消息数
  void _markMessageHasRead({
    String? conversationID,
  }) {
    OpenIM.iMManager.conversationManager.markConversationMessageAsRead(
      conversationID: conversationID!,
    );
  }

  /// 设置草稿
  void _setupDraftText({
    required String conversationID,
    required String oldDraftText,
    required String newDraftText,
  }) {
    if (oldDraftText.isEmpty && newDraftText.isEmpty) {
      return;
    }

    /// 保存草稿
    // Logger.print('draftText:$newDraftText');
    OpenIM.iMManager.conversationManager.setConversationDraft(
      conversationID: conversationID,
      draftText: newDraftText,
    );
  }

  String? get imSdkStatus {
    switch (imStatus.value) {
      case IMSdkStatus.syncStart:
      case IMSdkStatus.synchronizing:
        return StrRes.synchronizing;
      case IMSdkStatus.syncFailed:
        return StrRes.syncFailed;
      case IMSdkStatus.connecting:
        return StrRes.connecting;
      case IMSdkStatus.connectionFailed:
        return StrRes.connectionFailed;
      case IMSdkStatus.connectionSucceeded:
        return '已连接';
      case IMSdkStatus.syncEnded:
        return null;
    }
  }

  bool get isFailedSdkStatus => imStatus.value == IMSdkStatus.connectionFailed || imStatus.value == IMSdkStatus.syncFailed;

  bool get isSuccessSdkStatus => imStatus.value == IMSdkStatus.connectionSucceeded || imStatus.value == IMSdkStatus.syncEnded;

  /// 同步连接状态（当检测到实际已连接时）
  void _syncConnectionStatus() async {
    // 只有在显示"连接中"时才检查
    if (imStatus.value != IMSdkStatus.connecting) return;
    
    try {
      // 检查真实的登录状态
      final loginStatus = await OpenIM.iMManager.getLoginStatus();
      // loginStatus: 3 = 已登录
      if (loginStatus == 3) {
        // 真实状态是已登录，同步状态
        imLogic.imSdkStatus(IMSdkStatus.connectionSucceeded);
      }
    } catch (e) {
      // 检查失败，忽略
    }
  }

  /// 获取状态文本（用于调试）
  String _getStatusText(IMSdkStatus status) {
    switch (status) {
      case IMSdkStatus.syncStart:
      case IMSdkStatus.synchronizing:
        return '同步中';
      case IMSdkStatus.syncFailed:
        return '同步失败';
      case IMSdkStatus.connecting:
        return '连接中';
      case IMSdkStatus.connectionFailed:
        return '连接失败';
      case IMSdkStatus.connectionSucceeded:
        return '连接成功';
      case IMSdkStatus.syncEnded:
        return '同步结束';
    }
  }

  /// 自定义会话列表排序规则
  void _sortConversationList() => OpenIM.iMManager.conversationManager.simpleSort(list);

  void onRefresh() async {
    late List<ConversationInfo> list;
    try {
      list = await _request(0);
      this.list.assignAll(list);
      if (list.isEmpty || list.length < pageSize) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    } finally {
      refreshController.refreshCompleted();
    }
  }

  void onLoading() async {
    late List<ConversationInfo> list;
    try {
      list = await _request(this.list.length);
      this.list.addAll(list);
    } finally {
      if (list.isEmpty || list.length < pageSize) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  _request(int offset) => OpenIM.iMManager.conversationManager.getConversationListSplit(
        offset: offset,
        count: pageSize,
      );

  bool isValidConversation(ConversationInfo info) {
    return info.isValid;
  }

  // use this if total item count is known
  int scrollListenerWithItemCount() {
    int itemCount = list.length;
    double scrollOffset = scrollController.position.pixels;
    double viewportHeight = scrollController.position.viewportDimension;
    double scrollRange = scrollController.position.maxScrollExtent - scrollController.position.minScrollExtent;
    int firstVisibleItemIndex = (scrollOffset / (scrollRange + viewportHeight) * itemCount).floor();
    return firstVisibleItemIndex;
  }

  void scrollTo() {
    if (list.isEmpty) return;
    // int first = scrollListenerWithItemCount();
    // int min = visibilityIndex.minOrNull ?? 0;
    // int start = max(first, min);
    int start = scrollListenerWithItemCount();
    if (start < scrollIndex) {
      start = scrollIndex;
    }
    if (scrollIndex == start) {
      start++;
    }
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      start = 0;
    }

    if (start > list.length - 1) return;
    final unreadItem = list.sublist(start).firstWhereOrNull((e) => e.unreadCount! > 0);
    if (null == unreadItem) {
      if (start > 0) {
        scrollController.scrollToIndex(
          scrollIndex = 0,
          preferPosition: AutoScrollPosition.begin,
        );
      }
      return;
    }
    final index = list.indexOf(unreadItem);
    scrollController.scrollToIndex(
      scrollIndex = index,
      preferPosition: AutoScrollPosition.begin,
    );
  }

  static Future<ConversationInfo> _createConversation({
    required String sourceID,
    required int sessionType,
  }) =>
      LoadingView.singleton.wrap(
          asyncFunction: () => OpenIM.iMManager.conversationManager.getOneConversation(
                sourceID: sourceID,
                sessionType: sessionType,
              ));

  /// 打开系统通知页面
  Future<bool> _jumpOANtf(ConversationInfo info) async {
    if (info.conversationType == ConversationType.notification) {
      // 系统通知
      await AppNavigator.startOANtfList(info: info);
      // 标记已读
      _markMessageHasRead(conversationID: info.conversationID);
      return true;
    }
    return false;
  }

  /// 进入聊天页面
  void toChat({
    bool offUntilHome = true,
    String? userID,
    String? groupID,
    String? nickname,
    String? faceURL,
    int? sessionType,
    ConversationInfo? conversationInfo,
    Message? searchMessage,
  }) async {
    // 获取会话信息，若不存在则创建
    conversationInfo ??= await _createConversation(
      sourceID: userID ?? groupID!,
      sessionType: userID == null ? sessionType! : ConversationType.single,
    );

    // 标记已读
    // _markMessageHasRead(conversationID: conversationInfo.conversationID);

    // 如果是系统通知
    if (await _jumpOANtf(conversationInfo)) return;

    // 保存旧草稿
    updateDartText(
      conversationID: conversationInfo.conversationID,
      text: conversationInfo.draftText ?? '',
    );

    // 打开聊天窗口，关闭返回草稿
    /*var newDraftText = */
    await AppNavigator.startChat(
      offUntilHome: offUntilHome,
      draftText: conversationInfo.draftText,
      conversationInfo: conversationInfo,
      searchMessage: searchMessage,
    );

    // 读取草稿
    var newDraftText = tempDraftText[conversationInfo.conversationID];

    // 标记已读
    _markMessageHasRead(conversationID: conversationInfo.conversationID);

    // 记录草稿
    _setupDraftText(
      conversationID: conversationInfo.conversationID,
      oldDraftText: conversationInfo.draftText ?? '',
      newDraftText: newDraftText!,
    );

    // 回到会话列表
    // homeLogic.switchTab(0);

    bool equal(e) => e.conversationID == conversationInfo?.conversationID;
    // 删除所有@标识/公告标识
    var groupAtType = list.firstWhereOrNull(equal)?.groupAtType;
    if (groupAtType != GroupAtType.atNormal) {
      OpenIM.iMManager.conversationManager.resetConversationGroupAtType(
        conversationID: conversationInfo.conversationID,
      );
    }
  }

  scan() => AppNavigator.startScan();

  addFriend() => AppNavigator.startAddContactsBySearch(searchType: SearchType.user);

  createGroup() => AppNavigator.startCreateGroup(defaultCheckedList: [OpenIM.iMManager.userInfo]);

  addGroup() => AppNavigator.startAddContactsBySearch(searchType: SearchType.group);

  void videoMeeting() => MNavigator.startMeeting();

  void viewCallRecords() => AppNavigator.startCallRecords();

  void globalSearch() => AppNavigator.startGlobalSearch();
  
  /// 测试连接状态显示
  void testConnectionStatus() {
    // Logger.print('测试连接状态显示');
    forceSetConnectionStatus(IMSdkStatus.connecting);
    
    // 3秒后设置为连接失败
    Timer(Duration(seconds: 3), () {
      forceSetConnectionStatus(IMSdkStatus.connectionFailed);
    });
  }
  
  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
