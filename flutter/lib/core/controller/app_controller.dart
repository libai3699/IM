import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as im;
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';

import '../../utils/upgrade_manager.dart';
import 'im_controller.dart';
import 'push_controller.dart';

class AppController extends SuperController with UpgradeManger {
  var isRunningBackground = false;
  var isAppBadgeSupported = false;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    onDidReceiveLocalNotification: (
      int id,
      String? title,
      String? body,
      String? payload,
    ) async {},
  );

  MeetingBridge? meetingBridge = PackageBridge.meetingBridge;

  RTCBridge? rtcBridge = PackageBridge.rtcBridge;

  bool get shouldMuted => meetingBridge?.hasConnection == true || rtcBridge?.hasConnection == true;

  final _ring = 'assets/audio/message_ring.wav';
  final _audioPlayer = AudioPlayer(
      // Handle audio_session events ourselves for the purpose of this demo.
      // handleInterruptions: false,
      // androidApplyAudioAttributes: false,
      // handleAudioSessionActivation: false,
      );

  late BaseDeviceInfo deviceInfo;

  /// discoverPageURL
  /// ordinaryUserAddFriend,
  /// bossUserID,
  /// adminURL ,
  /// allowSendMsgNotFriend
  /// needInvitationCodeRegister
  /// robots
  final clientConfigMap = <String, dynamic>{}.obs;

  /// 与后端 isClientConfigEnabled 一致：值为 1 / true / yes 时视为开启
  bool isClientConfigEnabled(String key) {
    final val = clientConfigMap[key];
    if (val == null) return false;
    final s = val.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  /// 仅注册流程使用；找回密码始终走验证码页，不受此配置影响
  bool get needVerificationCodeRegister =>
      isClientConfigEnabled('needVerificationCodeRegister');

  bool get needInvitationCodeRegister =>
      isClientConfigEnabled('needInvitationCodeRegister');

  Future<void> runningBackground(bool run) async {
    // Logger.print('-----App running background : $run-------------');

    if (isRunningBackground && !run) {}
    isRunningBackground = run;
    Get.find<IMController>().backgroundSubject.sink.add(run);
    if (!run) {
      _cancelAllNotifications();
    }
  }

  @override
  void onInit() async {
    _requestPermissions();
    _initPlayer();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) {},
    );
    _startForegroundService();
    isAppBadgeSupported = await FlutterAppBadger.isAppBadgeSupported();
    super.onInit();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification(im.Message message, {bool showNotification = true}) async {
    if (_isGlobalNotDisturb() ||
            message.attachedInfoElem?.notSenderNotificationPush == true ||
            message.contentType == im.MessageType.typing ||
            message.sendID == OpenIM.iMManager.userID /* ||
        message.contentType! >= 1000*/
        ) return;

    // 开启免打扰的不提示
    var sourceID = message.sessionType == ConversationType.single ? message.sendID : message.groupID;
    if (sourceID != null && message.sessionType != null) {
      var i = await OpenIM.iMManager.conversationManager.getOneConversation(
        sourceID: sourceID,
        sessionType: message.sessionType!,
      );
      if (i.recvMsgOpt != 0) return;
    }

    if (showNotification) {
      promptSoundOrNotification(message.seq!);
    }
  }

  Future<void> promptSoundOrNotification(int seq) async {
    if (!isRunningBackground) {
      // 前台时：播放声音和震动
      _playMessageSound();
    } else {
      // 后台时：显示通知并播放声音和震动
      if (Platform.isAndroid) {
        final id = seq;

        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'chat',
          'OpenIM聊天消息',
          channelDescription: '来自OpenIM的信息',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(id, '您收到了一条新消息', '消息内容：.....', platformChannelSpecifics, payload: '');
      }
      // 后台时也播放声音和震动
      _playMessageSound();
    }
  }

  /// 显示好友申请通知
  Future<void> showFriendApplicationNotification(String nickname, String userID) async {
    if (_isGlobalNotDisturb()) return;

    if (!isRunningBackground) {
      // 前台时：播放声音和震动
      _playMessageSound();
    } else {
      // 后台时：显示通知并播放声音和震动（和消息接收逻辑一致）
      if (Platform.isAndroid) {
        final id = DateTime.now().millisecondsSinceEpoch % 100000;

        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'friend_request',
          '好友申请',
          channelDescription: '收到新的好友申请',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
          id,
          '新的好友申请',
          '${nickname.isNotEmpty ? nickname : userID} 请求添加您为好友',
          platformChannelSpecifics,
          payload: 'friend_request:$userID',
        );
      }
      // 后台时也播放声音和震动（和消息接收逻辑一致）
      _playMessageSound();
    }
  }

  /// 显示群组申请通知
  Future<void> showGroupApplicationNotification(String groupName, String groupID) async {
    if (_isGlobalNotDisturb()) return;

    if (!isRunningBackground) {
      // 前台时：播放声音和震动
      _playMessageSound();
    } else {
      // 后台时：显示通知并播放声音和震动（和消息接收逻辑一致）
      if (Platform.isAndroid) {
        final id = DateTime.now().millisecondsSinceEpoch % 100000;

        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'group_request',
          '群组申请',
          channelDescription: '收到新的入群申请',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
          id,
          '新的入群申请',
          '${groupName.isNotEmpty ? groupName : groupID} 有新的入群申请',
          platformChannelSpecifics,
          payload: 'group_request:$groupID',
        );
      }
      // 后台时也播放声音和震动（和消息接收逻辑一致）
      _playMessageSound();
    }
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _startForegroundService() async {
    await getAppInfo();
    const androidPlatformChannelSpecifics = AndroidNotificationDetails('pro', '番茄后台进程',
        channelDescription: '保证app能收到信息', importance: Importance.max, priority: Priority.high, ticker: 'ticker');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.startForegroundService(1, packageInfo!.appName, '正在运行...', notificationDetails: androidPlatformChannelSpecifics, payload: '');
  }

  Future<void> _stopForegroundService() async {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.stopForegroundService();
  }

  void showBadge(count) {
    if (isAppBadgeSupported) {
      OpenIM.iMManager.messageManager.setAppBadge(count);

      if (count == 0) {
        removeBadge();
        PushController.resetBadge();
      } else {
        FlutterAppBadger.updateBadgeCount(count);
        PushController.setBadge(count);
      }
    }
  }

  void removeBadge() {
    FlutterAppBadger.removeBadge();
  }

  @override
  void onClose() {
    // backgroundSubject.close();
    _stopForegroundService();
    closeSubject();
    _audioPlayer.dispose();
    super.onClose();
  }

  Locale? getLocale() {
    var local = Get.locale;
    var index = DataSp.getLanguage() ?? 0;
    switch (index) {
      case 1:
        local = const Locale('zh', 'CN');
        break;
      case 2:
        local = const Locale('en', 'US');
        break;
    }
    return local;
  }

  @override
  void onReady() {
    _startForegroundService();
    queryClientConfig();
    _getDeviceInfo();
    _cancelAllNotifications();
    // 禁用自动更新检查，避免弹窗干扰用户
    // autoCheckVersionUpgrade();
    super.onReady();
  }

  /// 全局免打扰
  bool _isGlobalNotDisturb() {
    bool isRegistered = Get.isRegistered<IMController>();
    if (isRegistered) {
      var logic = Get.find<IMController>();
      return logic.userInfo.value.globalRecvMsgOpt == 2;
    }
    return false;
  }

  void _initPlayer() {
    _audioPlayer.setAsset(_ring, package: 'openim_common');
    // _audioPlayer.setLoopMode(LoopMode.off);
    // _audioPlayer.setVolume(1.0);
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
        case ProcessingState.loading:
        case ProcessingState.buffering:
        case ProcessingState.ready:
          break;
        case ProcessingState.completed:
          _stopMessageSound();
          // _audioPlayer.seek(null);
          break;
      }
    });
  }

  /// 播放提示音
  void _playMessageSound() async {
    if (shouldMuted) {
      return;
    }
    bool isRegistered = Get.isRegistered<IMController>();
    bool isAllowVibration = true;
    bool isAllowBeep = true;
    if (isRegistered) {
      var logic = Get.find<IMController>();
      isAllowVibration = logic.userInfo.value.allowVibration == 1;
      isAllowBeep = logic.userInfo.value.allowBeep == 1;
    }
    // 获取系统静音、震动状态
    RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;

    if (!_audioPlayer.playerState.playing && isAllowBeep && (ringerStatus == RingerModeStatus.normal || ringerStatus == RingerModeStatus.unknown)) {
      _audioPlayer.setAsset(_ring, package: 'openim_common');
      _audioPlayer.setLoopMode(LoopMode.off);
      _audioPlayer.setVolume(1.0);
      _audioPlayer.play();
    }

    if (isAllowVibration &&
        (ringerStatus == RingerModeStatus.normal || ringerStatus == RingerModeStatus.vibrate || ringerStatus == RingerModeStatus.unknown)) {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate();
      }
    }
  }

  /// 关闭提示音
  void _stopMessageSound() async {
    if (_audioPlayer.playerState.playing) {
      _audioPlayer.stop();
    }
  }

  void _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    deviceInfo = await deviceInfoPlugin.deviceInfo;
  }

  Future queryClientConfig() async {
    final map = await Apis.getClientConfig();
    clientConfigMap.assignAll(map);

    return clientConfigMap;
  }

  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    // TODO: implement onPaused
  }

  @override
  void onResumed() {
    // TODO: implement onResumed
    // 禁用自动更新检查，避免弹窗干扰用户
    // autoCheckVersionUpgrade();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
