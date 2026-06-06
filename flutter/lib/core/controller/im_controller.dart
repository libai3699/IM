import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_live/openim_live.dart';
import 'package:permission_handler/permission_handler.dart';

import '../im_callback.dart';

class IMController extends GetxController with IMCallback, OpenIMLive {
  late Rx<UserFullInfo> userInfo;
  late String atAllTag;
  
  // SDK 实例版本号：每次重新初始化时递增，用于忽略旧实例的回调
  int _sdkInstanceVersion = 0;
  
  // 网络状态监听
  StreamSubscription? _connectivitySubscription;

  @override
  void onClose() {
    _connectionTimeoutTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.close();
    // OpenIM.iMManager.unInitSDK();
    onCloseLive();
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();
    onInitLive();
    // Initialize SDK
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initOpenIM();
      _startNetworkMonitoring(); // 启动网络监听
    });
  }

  void initOpenIM() async {
    final initialized = await _initSDKWithListeners();
    initializedSubject.sink.add(initialized);
  }

  /// 初始化 SDK 并设置所有监听器（供内部和切换线路时使用）
  Future<bool> _initSDKWithListeners() async {
    Logger.print('[IMController] ========== 开始初始化 SDK ==========');
    Logger.print('[IMController] API URL (图片上传使用): ${Config.imApiUrl}');
    Logger.print('[IMController] WS URL: ${Config.imWsUrl}');
    Logger.print('[IMController] 当前服务器IP: ${Config.serverIp}');
    
    final initialized = await OpenIM.iMManager.initSDK(
      platformID: IMUtils.getPlatform(),
      apiAddr: Config.imApiUrl,
      wsAddr: Config.imWsUrl,
      dataDir: Config.cachePath,
      logLevel: 6,
      logFilePath: Config.cachePath,
      listener: OnConnectListener(
        onConnecting: () {
          Logger.print('[IMController] ========== onConnecting 被调用 (SDK v$_sdkInstanceVersion) ==========');
          final currentStatus = imSdkStatusSubject.valueOrNull;
          
          // 如果当前已经连接成功，忽略新的 onConnecting（可能是旧连接的回调）
          if (currentStatus == IMSdkStatus.connectionSucceeded ||
              currentStatus == IMSdkStatus.syncStart ||
              currentStatus == IMSdkStatus.synchronizing ||
              currentStatus == IMSdkStatus.syncEnded) {
            Logger.print('[IMController] 当前已连接或同步中，忽略 onConnecting');
            return;
          }
          
          imSdkStatus(IMSdkStatus.connecting);
        },
        onConnectFailed: (code, error) {
          final callbackVersion = _sdkInstanceVersion; // 捕获当前版本号
          Logger.print('[IMController] ========== onConnectFailed 被调用 (SDK v$callbackVersion): $code - $error ==========');
          
          // 忽略已经成功连接后的失败回调（可能是旧的连接重试任务残留）
          final currentStatus = imSdkStatusSubject.valueOrNull;
          if (currentStatus == IMSdkStatus.connectionSucceeded ||
              currentStatus == IMSdkStatus.syncStart ||
              currentStatus == IMSdkStatus.synchronizing ||
              currentStatus == IMSdkStatus.syncEnded) {
            Logger.print('[IMController] 已连接成功，忽略此失败回调（可能是旧连接任务残留）');
            return;
          }
          
          _cancelConnectionTimeout();
          
          // 如果是手动切换线路，也继续尝试重连
          if (_isManualSwitching) {
            Logger.print('[IMController] 手动切换线路失败，但继续自动重连');
            _isManualSwitching = false;
          }
          
          // 延迟10秒后如果还没连接成功，才显示失败状态
          Timer(Duration(seconds: 10), () {
            // 检查版本号是否仍然匹配
            if (_sdkInstanceVersion != callbackVersion) {
              Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$callbackVersion），忽略延迟失败状态更新');
              return;
            }
            if (imSdkStatusSubject.valueOrNull == IMSdkStatus.connecting) {
              Logger.print('[IMController] 10秒后仍未连接成功，显示失败状态');
              imSdkStatus(IMSdkStatus.connectionFailed);
            }
          });
          
          // 安排自动重连
          _scheduleReconnect();
        },
        onConnectSuccess: () {
          Logger.print('[IMController] ========== onConnectSuccess 被调用 (SDK v$_sdkInstanceVersion) ==========');
          Logger.print('[IMController] ✅ 成功连接到服务器: ${Config.serverIp}');
          Logger.print('[IMController] ✅ WebSocket URL: ${Config.imWsUrl}');
          
          _cancelConnectionTimeout();
          _stopReconnect(); // 停止自动重连
          _isManualSwitching = false; // 重置手动切换标志
          _reconnectAttempts = 0; // 重置重连次数
          imSdkStatus(IMSdkStatus.connectionSucceeded);
        },
        onKickedOffline: kickedOffline,
        onUserTokenExpired: kickedOffline,
      ),
    );
    
    // Logger.print('[IMController] SDK 初始化完成，返回值: $initialized');
    
    // Set all listeners
    _setupAllListeners();
    
    return initialized;
  }

  /// 设置所有监听器
  void _setupAllListeners() {
    OpenIM.iMManager
      ..setUploadLogsListener(OnUploadLogsListener(onUploadProgress: uploadLogsProgress))
      //
      ..userManager.setUserListener(OnUserListener(
          onSelfInfoUpdated: (u) {
            userInfo.update((val) {
              val?.nickname = u.nickname;
              val?.faceURL = u.faceURL;
              // val?.gender = u.gender;
              // val?.birth = u.birth;
              // val?.email = u.email;
              val?.remark = u.remark;
              val?.ex = u.ex;
              val?.globalRecvMsgOpt = u.globalRecvMsgOpt;
            });
            // _queryMyFullInfo();
          },
          onUserStatusChanged: userStausChanged))
      // Add message listener (remove when not in use)
      ..messageManager.setAdvancedMsgListener(OnAdvancedMsgListener(
          onRecvC2CReadReceipt: recvC2CMessageReadReceipt,
          onRecvNewMessage: recvNewMessage,
          onRecvGroupReadReceipt: recvGroupMessageReadReceipt,
          onNewRecvMessageRevoked: recvMessageRevoked,
          onRecvOfflineNewMessage: recvOfflineMessage))

      // Set up message sending progress listener
      ..messageManager.setMsgSendProgressListener(OnMsgSendProgressListener(
        onProgress: progressCallback,
      ))
      ..messageManager.setCustomBusinessListener(OnCustomBusinessListener(
        onRecvCustomBusinessMessage: recvCustomBusinessMessage,
      ))
      // Set up friend relationship listener
      ..friendshipManager.setFriendshipListener(OnFriendshipListener(
        onBlackAdded: blacklistAdded,
        onBlackDeleted: blacklistDeleted,
        onFriendApplicationAccepted: friendApplicationAccepted,
        onFriendApplicationAdded: friendApplicationAdded,
        onFriendApplicationDeleted: friendApplicationDeleted,
        onFriendApplicationRejected: friendApplicationRejected,
        onFriendInfoChanged: friendInfoChanged,
        onFriendAdded: friendAdded,
        onFriendDeleted: friendDeleted,
      ))

      // Set up conversation listener
      ..conversationManager.setConversationListener(OnConversationListener(
        onConversationChanged: conversationChanged,
        onNewConversation: newConversation,
        onTotalUnreadMessageCountChanged: totalUnreadMsgCountChanged,
        onSyncServerFailed: () {
          imSdkStatus(IMSdkStatus.syncFailed);
        },
        onSyncServerFinish: () {
          imSdkStatus(IMSdkStatus.syncEnded);
          // 移除自动请求悬浮窗权限，只在需要时（如通话）才请求
        },
        onSyncServerStart: () {
          imSdkStatus(IMSdkStatus.syncStart);
        },
      ))

      // Set up group listener
      ..groupManager.setGroupListener(OnGroupListener(
        onGroupApplicationAccepted: groupApplicationAccepted,
        onGroupApplicationAdded: groupApplicationAdded,
        onGroupApplicationDeleted: groupApplicationDeleted,
        onGroupApplicationRejected: groupApplicationRejected,
        onGroupInfoChanged: groupInfoChanged,
        onGroupMemberAdded: groupMemberAdded,
        onGroupMemberDeleted: groupMemberDeleted,
        onGroupMemberInfoChanged: groupMemberInfoChanged,
        onJoinedGroupAdded: joinedGroupAdded,
        onJoinedGroupDeleted: joinedGroupDeleted,
      ))
      // Set up signaling listener
      ..signalingManager.setSignalingListener(OnSignalingListener(
        onInvitationCancelled: invitationCancelled,
        onInvitationTimeout: invitationTimeout,
        onInviteeAccepted: inviteeAccepted,
        onInviteeRejected: inviteeRejected,
        onReceiveNewInvitation: receiveNewInvitation,
        onInviteeAcceptedByOtherDevice: inviteeAcceptedByOtherDevice,
        onInviteeRejectedByOtherDevice: inviteeRejectedByOtherDevice,
        onHangup: beHangup,
        onRoomParticipantConnected: roomParticipantConnected,
        onRoomParticipantDisconnected: roomParticipantDisconnected,
        onMeetingStreamChanged: meetingSteamChanged,
      ));
  }

  Timer? _connectionTimeoutTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 999; // 基本无限重试
  bool _isManualSwitching = false; // 是否正在手动切换线路

  /// 重新初始化 SDK（用于切换线路）
  /// 注意：这个方法会完全卸载并重新初始化 SDK，只应该在手动切换线路时调用
  Future<void> reinitializeSDK({bool isManualSwitch = true}) async {
    // 递增 SDK 版本号，旧实例的回调将被忽略
    _sdkInstanceVersion++;
    final currentVersion = _sdkInstanceVersion;
    
    try {
      
      Logger.print('[IMController] ========================================');
      Logger.print('[IMController] 开始重新初始化 IM SDK（完全重新初始化）...');
      Logger.print('[IMController] SDK 实例版本: v$currentVersion');
      Logger.print('[IMController] 是否手动切换: $isManualSwitch');
      Logger.print('[IMController] 切换前 - API URL: ${Config.imApiUrl}');
      Logger.print('[IMController] 切换前 - WS URL: ${Config.imWsUrl}');
      Logger.print('[IMController] 切换前 - 服务器IP: ${Config.serverIp}');
      
      _isManualSwitching = isManualSwitch;
      
      // 强制停止所有重连和超时计时器
      _stopReconnect();
      _connectionTimeoutTimer?.cancel();
      _reconnectTimer?.cancel();
      _reconnectAttempts = 0;
      
      // 立即设置为连接中状态
      imSdkStatus(IMSdkStatus.connecting);
      
      // 1. 先登出当前用户（2秒超时）
      Logger.print('[IMController] 🔄 步骤1: 登出当前用户...');
      try {
        await OpenIM.iMManager.logout().timeout(Duration(seconds: 2));
        Logger.print('[IMController] ✓ 登出成功');
      } catch (e) {
        Logger.print('[IMController] ⚠ 登出失败或超时（继续）: $e');
      }
      
      // 2. 🔥 完全卸载旧的 SDK 实例（清理所有底层连接和缓存）
      Logger.print('[IMController] 🔄 步骤2: 卸载旧的 SDK 实例...');
      try {
        await OpenIM.iMManager.unInitSDK().timeout(Duration(seconds: 5));
        Logger.print('[IMController] ✓ SDK 卸载成功');
      } catch (e) {
        Logger.print('[IMController] ⚠ SDK 卸载失败或超时（继续）: $e');
      }
      
      // 等待 5 秒，让 SDK 后台的所有 goroutine 完全清理
      // 注意：从日志看，SDK 的连接重试任务在 logout 后仍可能存活 4-5 秒
      Logger.print('[IMController] ⏳ 等待 5 秒，确保 SDK 后台任务（特别是连接重试）完全清理...');
      await Future.delayed(Duration(seconds: 5));
      Logger.print('[IMController] ✓ 等待完成，SDK 后台任务应已完全停止');
      
      // 3. 重新初始化 SDK（保持手动切换标志）
      Logger.print('[IMController] 准备重新初始化 SDK...');
      Logger.print('[IMController] 切换后 - API URL (图片上传将使用): ${Config.imApiUrl}');
      Logger.print('[IMController] 切换后 - WS URL: ${Config.imWsUrl}');
      Logger.print('[IMController] 切换后 - 服务器IP: ${Config.serverIp}');
      
      // 在初始化前确保手动切换标志仍然有效
      final wasManualSwitch = _isManualSwitching;
      await _initSDKWithListeners();
      _isManualSwitching = wasManualSwitch; // 恢复标志
      
      Logger.print('[IMController] ✓ SDK 重新初始化完成');
      
      // 4. 重新登录
      final loginCert = DataSp.getLoginCertificate();
      if (loginCert != null) {
        Logger.print('[IMController] 开始重新登录...');
        Logger.print('[IMController] 用户ID: ${loginCert.userID}');
        Logger.print('[IMController] Token 前20位: ${loginCert.imToken.length > 20 ? loginCert.imToken.substring(0, 20) : loginCert.imToken}...');
        
        // 启动连接超时计时器（10秒）
        _startConnectionTimeout();
        
        try {
          await OpenIM.iMManager.login(
            userID: loginCert.userID,
            token: loginCert.imToken,
            defaultValue: () async => UserInfo(userID: loginCert.userID),
          );
          Logger.print('[IMController] ✓ 登录请求已发送');
          
          // 登录成功后，主动检查连接状态
          _checkConnectionStatusAfterLogin();
        } catch (e) {
          Logger.print('[IMController] ✗ 登录失败: $e');
          
          // ✨ 检查版本号，如果不是当前版本则忽略
          if (currentVersion != _sdkInstanceVersion) {
            Logger.print('[IMController] ⚠ 忽略旧版本($currentVersion)的登录错误，当前版本: $_sdkInstanceVersion');
            return;
          }
          
          // 如果是 token 过期（10005），需要重新登录
          if (e.toString().contains('10005')) {
            Logger.print('[IMController] ⚠ Token 已过期（错误码 10005），请重新登录');
            _cancelConnectionTimeout();
            imSdkStatus(IMSdkStatus.connectionFailed);
            // 清除登录凭证，强制用户重新登录
            await DataSp.removeLoginCertificate();
            // 不再重连
            _stopReconnect();
            return;
          }
          
          // 其他错误继续抛出
          throw e;
        }
      } else {
        Logger.print('[IMController] ✗ 没有登录凭证');
        imSdkStatus(IMSdkStatus.connectionFailed);
      }
      
      // Logger.print('[IMController] ========================================');
    } catch (e, stackTrace) {
      // Logger.print('[IMController] ✗ 重新初始化 IM SDK 失败: $e');
      // Logger.print('[IMController] 堆栈: $stackTrace');
      _connectionTimeoutTimer?.cancel();
      
      // 不设置为失败状态，保持连接中
      // imSdkStatus(IMSdkStatus.connectionFailed);
      
      // 手动切换线路后失败，继续重连（使用新的配置）
      _scheduleReconnect();
    }
  }

  /// 启动连接超时计时器
  void _startConnectionTimeout() {
    final timeoutVersion = _sdkInstanceVersion; // 捕获当前版本号
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(Duration(seconds: 10), () {
      // 检查 SDK 是否已被重新初始化
      if (_sdkInstanceVersion != timeoutVersion) {
        Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$timeoutVersion），忽略此超时回调');
        return;
      }
      
      Logger.print('[IMController] ========== 连接超时（SDK v$timeoutVersion）==========');
      Logger.print('[IMController] 10秒内未收到连接回调，判定为连接失败');
      if (imSdkStatusSubject.valueOrNull == IMSdkStatus.connecting) {
        imSdkStatus(IMSdkStatus.connectionFailed);
        
        // 如果是手动切换线路，也允许自动重连
        if (_isManualSwitching) {
          Logger.print('[IMController] 手动切换线路超时，但继续尝试重连');
          _isManualSwitching = false;
        }
        // 继续自动重连
        _scheduleReconnect();
      }
    });
  }

  /// 取消连接超时计时器（在连接成功或失败时调用）
  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// 安排重连
  void _scheduleReconnect() {
    // 如果已经连接成功，不需要重连
    if (imSdkStatusSubject.valueOrNull == IMSdkStatus.connectionSucceeded) {
      // Logger.print('[IMController] 已连接成功，取消重连');
      return;
    }

    // 如果超过最大重连次数，停止重连
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // Logger.print('[IMController] 已达到最大重连次数，停止重连');
      return;
    }

    _reconnectAttempts++;
    
    // 计算重连延迟：5秒、10秒、15秒递增
    final delay = (_reconnectAttempts * 5).clamp(5, 15);
    
    // 捕获当前 SDK 版本号
    final reconnectVersion = _sdkInstanceVersion;
    
    // Logger.print('[IMController] 将在 $delay 秒后进行第 $_reconnectAttempts 次重连...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      // 检查 SDK 是否已被重新初始化
      if (_sdkInstanceVersion != reconnectVersion) {
        Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$reconnectVersion），取消此次重连任务');
        return;
      }
      // Logger.print('[IMController] 开始第 $_reconnectAttempts 次重连（只重新登录，不重新初始化 SDK）');
      _reconnectWithoutReinit(reconnectVersion);
    });
  }

  /// 重连（不重新初始化 SDK，只重新登录）
  Future<void> _reconnectWithoutReinit(int expectedVersion) async {
    try {
      // 再次检查 SDK 版本号
      if (_sdkInstanceVersion != expectedVersion) {
        Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$expectedVersion），取消此次重连');
        return;
      }
      
      // Logger.print('[IMController] ========== 开始重连（SDK v$expectedVersion）==========');
      
      // 检查网络连接状态
      final hasNetwork = await _checkNetworkConnectivity();
      if (!hasNetwork) {
        Logger.print('[IMController] ❌ 重连时发现无网络连接，稍后重试');
        return;
      }
      
      final loginCert = DataSp.getLoginCertificate();
      if (loginCert == null) {
        // Logger.print('[IMController] ✗ 没有登录凭证，停止重连');
        _stopReconnect();
        return;
      }
      
      // 启动连接超时计时器
      _startConnectionTimeout();
      
      try {
        await OpenIM.iMManager.login(
          userID: loginCert.userID,
          token: loginCert.imToken,
          defaultValue: () async => UserInfo(userID: loginCert.userID),
        );
        // Logger.print('[IMController] ✓ 重连登录请求已发送');
        
        // 登录后主动检查连接状态
        _checkConnectionStatusAfterLogin();
      } catch (e) {
        // Logger.print('[IMController] ✗ 重连登录失败: $e');
        
        // 如果是 token 过期，停止重连
        if (e.toString().contains('10005')) {
          // Logger.print('[IMController] ⚠ Token 已过期，停止重连');
          _cancelConnectionTimeout();
          _stopReconnect();
          imSdkStatus(IMSdkStatus.connectionFailed);
          await DataSp.removeLoginCertificate();
          return;
        }
        
        // 其他错误继续重连
        _scheduleReconnect();
      }
    } catch (e) {
      // Logger.print('[IMController] ✗ 重连失败: $e');
      _scheduleReconnect();
    }
  }

  /// 停止自动重连
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  /// 检查网络连接状态
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      Logger.print('[IMController] 检查网络状态失败: $e');
      return true; // 检查失败时假设有网络，避免误判
    }
  }

  /// 登录后检查连接状态（仅用于重连场景）
  void _checkConnectionStatusAfterLogin() {
    // 注意：不要通过 loginStatus 来判断连接是否成功
    // SDK 的 loginStatus 可能保持"已登录"状态，但 WebSocket 连接可能已断开
    // 应该只依赖 onConnectSuccess 回调来确定真实的连接状态
    
    // Logger.print('[IMController] 开始主动检查连接状态...');
    
    // 捕获当前 SDK 版本号
    final checkVersion = _sdkInstanceVersion;
    
    // 延迟检查，给 SDK 一些时间建立连接
    Timer(Duration(seconds: 3), () async {
      try {
        // 检查 SDK 是否已被重新初始化
        if (_sdkInstanceVersion != checkVersion) {
          // Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$checkVersion），跳过连接状态检查');
          return;
        }
        
        // 如果已经连接成功，不需要检查
        if (imSdkStatusSubject.valueOrNull == IMSdkStatus.connectionSucceeded) {
          // Logger.print('[IMController] 已连接成功，跳过检查');
          return;
        }
        
        final loginStatus = await OpenIM.iMManager.getLoginStatus();
        // Logger.print('[IMController] 登录状态: $loginStatus');
        
        // loginStatus: 1=未登录, 2=登录中, 3=已登录
        // 注意：这里不能用 loginStatus == 3 来判断连接成功
        // 因为 SDK 可能保持已登录状态，但 WebSocket 实际上一直在重连失败
        if (loginStatus == 2) {
          // Logger.print('[IMController] 仍在登录中，继续等待回调...');
          // 继续等待超时或回调，不触发重连
        } else if (loginStatus == 1) {
          // Logger.print('[IMController] ✗ 登录状态异常: 未登录');
          // 只有在重连场景下才继续重连
          if (_reconnectAttempts > 0) {
            // Logger.print('[IMController] 继续重连...');
            _scheduleReconnect();
          } else {
            // Logger.print('[IMController] 首次登录失败，不触发重连');
          }
        }
        // loginStatus == 3 时，不做任何处理，等待真正的 onConnectSuccess 回调
      } catch (e) {
        // Logger.print('[IMController] ⚠ 检查登录状态失败: $e');
      }
    });
  }

  Future login(String userID, String token) async {
    try {
      // Logger.print('[IMController] ========== 开始登录 ==========');
      // Logger.print('[IMController] 用户ID: $userID');
      
      // 检查网络连接状态
      final hasNetwork = await _checkNetworkConnectivity();
      if (!hasNetwork) {
        Logger.print('[IMController] ❌ 无网络连接，直接设置连接失败状态');
        imSdkStatus(IMSdkStatus.connectionFailed);
        throw Exception('无网络连接，请检查网络设置');
      }
      
      // 停止任何正在进行的重连
      _stopReconnect();
      _connectionTimeoutTimer?.cancel();
      
      // 检查 SDK 是否已初始化
      bool needInit = false;
      try {
        final loginStatus = await OpenIM.iMManager.getLoginStatus();
        // Logger.print('[IMController] 当前登录状态: $loginStatus');
        
        // 如果状态异常（null 或 < 0），需要重新初始化
        if (loginStatus == null || loginStatus < 0) {
          // Logger.print('[IMController] 登录状态异常，需要重新初始化 SDK');
          needInit = true;
        }
      } catch (e) {
        // Logger.print('[IMController] SDK 未初始化: $e');
        needInit = true;
      }
      
      // 如果需要初始化，先卸载再初始化
      if (needInit) {
        // Logger.print('[IMController] 开始重新初始化 SDK...');
        
        // 先尝试卸载旧的 SDK
        try {
          await OpenIM.iMManager.unInitSDK().timeout(Duration(seconds: 3));
          // Logger.print('[IMController] ✓ 已卸载旧 SDK');
        } catch (e) {
          // Logger.print('[IMController] ⚠ 卸载 SDK 失败或超时: $e');
        }
        
        // 等待一下，确保资源释放
        await Future.delayed(Duration(milliseconds: 500));
        
        // 重新初始化
        await _initSDKWithListeners();
        // Logger.print('[IMController] ✓ SDK 初始化完成');
        
        // 再等待一下，确保 SDK 资源加载完成
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Logger.print('[IMController] 准备登录...');
      var user = await OpenIM.iMManager.login(
        userID: userID,
        token: token,
        defaultValue: () async => UserInfo(userID: userID),
      );
      
      // Logger.print('[IMController] ✓ 登录成功');
      userInfo = UserFullInfo.fromJson(user.toJson()).obs;
      _queryMyFullInfo();
      _queryAtAllTag();
      
      // Logger.print('[IMController] ========== 登录完成，等待连接回调 ==========');
    } catch (e, s) {
      // Logger.print('[IMController] ✗ 登录失败: $e');
      // Logger.print('[IMController] 堆栈: $s');
      
      // 如果是资源未加载完成的错误，提示用户稍后重试
      if (e.toString().contains('10004') || e.toString().contains('ResourceLoadNotCompleteError')) {
        // Logger.print('[IMController] ⚠ SDK 资源未加载完成，请稍后重试');
      }
      
      await _handleLoginRepeatError(e);
      return Future.error(e, s);
    }
  }

  Future logout() async {
    // Logger.print('[IMController] 开始退出登录...');
    
    // 停止所有重连尝试
    _stopReconnect();
    _connectionTimeoutTimer?.cancel();
    
    // 只登出用户，不卸载 SDK（保留 SDK 实例，方便重新登录）
    try {
      await OpenIM.iMManager.logout().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          // Logger.print('[IMController] ⚠ 登出超时，强制继续');
          return Future.value();
        },
      );
      // Logger.print('[IMController] ✓ 退出登录成功');
    } catch (e) {
      // Logger.print('[IMController] ⚠ 退出登录失败: $e');
      // 即使登出失败也继续
    }
    
    // 注意：不卸载 SDK，这样重新登录时不需要重新初始化
    // Logger.print('[IMController] ✓ 退出流程完成（保留 SDK 实例）');
  }

  /// @所有人ID
  void _queryAtAllTag() async {
    atAllTag = OpenIM.iMManager.conversationManager.atAllTag;
    // atAllTag = await OpenIM.iMManager.conversationManager.getAtAllTag();
  }

  void _queryMyFullInfo() async {
    final data = await Apis.queryMyFullInfo();
    if (data is UserFullInfo) {
      userInfo.update((val) {
        val?.allowAddFriend = data.allowAddFriend;
        val?.allowBeep = data.allowBeep;
        val?.allowVibration = data.allowVibration;
        val?.nickname = data.nickname;
        val?.faceURL = data.faceURL;
        val?.phoneNumber = data.phoneNumber;
        val?.email = data.email;
        val?.birth = data.birth;
        val?.gender = data.gender;
      });
    }
  }

  _handleLoginRepeatError(e) async {
    if (e is PlatformException && e.code == "13002") {
      await logout();
      await DataSp.removeLoginCertificate();
    }
  }

  /// 启动网络状态监听
  /// 当网络从断开恢复到连接时，自动触发重连
  void _startNetworkMonitoring() {
    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final hasNetwork = result != ConnectivityResult.none;
          Logger.print('[IMController] 网络状态变化: $hasNetwork');
          
          if (hasNetwork) {
            // 网络恢复，检查当前连接状态
            if (imSdkStatusSubject.valueOrNull == IMSdkStatus.connectionFailed) {
              Logger.print('[IMController] 网络恢复，尝试重连');
              // 捕获当前版本号
              final networkRecoverVersion = _sdkInstanceVersion;
              // 等待一小段时间再重连，避免网络刚恢复就立即连接可能失败
              Timer(const Duration(seconds: 2), () {
                // 检查 SDK 是否已被重新初始化
                if (_sdkInstanceVersion != networkRecoverVersion) {
                  Logger.print('[IMController] SDK 已重新初始化（v$_sdkInstanceVersion != v$networkRecoverVersion），取消网络恢复重连');
                  return;
                }
                if (DataSp.getLoginCertificate() != null) {
                  _reconnectWithoutReinit(networkRecoverVersion);
                }
              });
            }
          } else {
            // 网络断开，设置连接失败状态
            Logger.print('[IMController] 网络断开，设置连接失败状态');
            imSdkStatus(IMSdkStatus.connectionFailed);
          }
        },
        onError: (error) {
          Logger.print('[IMController] 网络监听出错: $error');
        },
      );
      
      Logger.print('[IMController] ✓ 网络监听已启动');
    } catch (e) {
      Logger.print('[IMController] ⚠ 启动网络监听失败: $e');
    }
  }
}
