import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';

class Config {
  //初始化全局信息
  static Future init(Function() runApp) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      cachePath = '$path/';
      await DataSp.init();
      await Hive.initFlutter(path);
      // await SpeechToTextUtil.instance.initSpeech();
      HttpUtil.init();
    } catch (_) {}

    runApp();

    // 设置屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 状态栏透明（Android）
    var brightness = Platform.isAndroid ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness,
    ));

    FlutterBugly.init(androidAppId: "", iOSAppId: "");
  }

  static late String cachePath;
  static const uiW = 375.0;
  static const uiH = 812.0;

  /// 全局字体size
  static const double textScaleFactor = 1.0;

  ///务必更换为自己高德地图的key
  static const webKey = '11111111111111';
  static const webServerKey = '22222222222222222';
  static const locationHost = 'https://open.ijqtx.com:8444';

  /// 离线消息默认类型
  static OfflinePushInfo offlinePushInfo = OfflinePushInfo(
    title: StrRes.offlineMessage,
    desc: "",
    iOSBadgeCount: true,
    iOSPushSound: '+1',
  );

  /// 二维码：scheme
  static const friendScheme = "io.openim.app/addFriend/";
  static const groupScheme = "io.openim.app/joinGroup/";

  /// ip
  /// web.rentsoft.cn
  /// 203.56.175.233
  static const _host = "open.ijqtx.com";

  /// 强制使用HTTPS协议
  static const bool useHttps = true;

  /// 预设线路配置
  static const List<Map<String, String>> _presetLines = [
    {
      'name': '主线路',
      'serverIP': 'open.qweenew.com',
      'authUrl': 'https://open.qweenew.com/chat',
      'apiUrl': 'https://open.qweenew.com/api',
      'wsUrl': 'wss://open.qweenew.com/msg_gateway',
    }
  ];

  /// 获取预设线路列表（完全使用动态配置，如果没有则返回保底线路）
  static List<Map<String, String>> get presetLines {
    final dynamicLines = DataSp.getDynamicLineConfig();
    Logger.print('[Config] 获取动态线路配置: ${dynamicLines.length}个线路');
    if (dynamicLines.isNotEmpty) {
      Logger.print('[Config] 使用动态线路配置: $dynamicLines');
      return dynamicLines;
    } else {
      Logger.print('[Config] 没有线路配置，返回保底线路');
      // 如果没有动态配置，返回保底线路
      return [
        {
          'name': '保底线路',
          'serverIP': 'open.qweenew.com',
          'authUrl': 'https://open.qweenew.com/chat',
          'apiUrl': 'https://open.qweenew.com/api',
          'wsUrl': 'wss://open.qweenew.com/msg_gateway',
        }
      ];
    }
  }

  /// 获取当前线路索引
  static int get currentLineIndex {
    final index = DataSp.getCurrentLineIndex() ?? 0;
    // Logger.print('当前线路索引: $index');
    return index;
  }

  /// 设置当前线路索引
  static Future<void> setCurrentLineIndex(int index) async {
    await DataSp.putCurrentLineIndex(index);
  }

  /// 获取当前线路配置
  static Map<String, String> get currentLineConfig {
    final index = currentLineIndex;
    Logger.print('[Config] 获取线路配置，索引: $index');

    // 使用动态配置
    final dynamicLines = DataSp.getDynamicLineConfig();
    if (dynamicLines.isNotEmpty && index >= 0 && index < dynamicLines.length) {
      final config = dynamicLines[index];
      Logger.print('[Config] 使用动态线路配置: $config');
      return config;
    }

    // 如果没有动态配置，使用保底线路
    Logger.print('[Config] 使用保底线路: open.qweenew.com');
    return {
      'name': '保底线路',
      'serverIP': 'open.qweenew.com',
      'authUrl': 'https://open.qweenew.com/chat',
      'apiUrl': 'https://open.qweenew.com/api',
      'wsUrl': 'wss://open.qweenew.com/msg_gateway',
    };
  }

  /// 服务器IP
  static String get serverIp {
    // 优先使用当前线路配置
    final currentConfig = currentLineConfig;
    if (currentConfig.isNotEmpty) {
      return currentConfig['serverIP'] ?? _host;
    }

    // 回退到原有逻辑
    String? ip;
    var server = DataSp.getServerConfig();
    if (null != server) {
      ip = server['serverIP'];
      // Logger.print('缓存serverIP: $ip');
    }
    return ip ?? _host;
  }


  /// 登录注册手机验 证服务器地址
  /// $apiScheme://$host/chat/
  /// $apiScheme://$host:10008
  /// 端口：10008
  static String get appAuthUrl {
    // 优先使用当前线路配置
    final currentConfig = currentLineConfig;
    if (currentConfig.isNotEmpty && currentConfig.containsKey('authUrl')) {
      final url = currentConfig['authUrl']!;
      // Logger.print('使用线路配置authUrl: $url');
      return url;
    }

    // 回退到原有逻辑
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['authUrl'];
      // Logger.print('缓存authUrl: $url');
    }
    final fallbackUrl = url ?? (useHttps ? "https://$_host/chat" : "http://$_host:10008");
    // Logger.print('最终authUrl: $fallbackUrl');
    return fallbackUrl;
  }

  /// IM sdk api地址
  /// $apiScheme://$host/api/
  /// $apiScheme://$host:10002
  /// 端口：10002
  static String get imApiUrl {
    // 优先使用当前线路配置
    final currentConfig = currentLineConfig;
    if (currentConfig.isNotEmpty) {
      return currentConfig['apiUrl'] ?? (useHttps ? "https://$_host/api" : 'http://$_host:10002');
    }

    // 回退到原有逻辑
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['apiUrl'];
      // Logger.print('缓存apiUrl: $url');
    }
    return url ?? (useHttps ? "https://$_host/api" : 'http://$_host:10002');
  }

  /// IM ws 地址
  /// $socketScheme://$host/msg_gateway
  /// $socketScheme://$host:10001
  /// 端口：10001
  static String get imWsUrl {
    // 优先使用当前线路配置
    final currentConfig = currentLineConfig;
    if (currentConfig.isNotEmpty) {
      return currentConfig['wsUrl'] ?? (useHttps ? "wss://$_host/msg_gateway" : "ws://$_host:10001");
    }

    // 回退到原有逻辑
    String? url;
    var server = DataSp.getServerConfig();
    if (null != server) {
      url = server['wsUrl'];
      // Logger.print('缓存wsUrl: $url');
    }
    return url ?? (useHttps ? "wss://$_host/msg_gateway" : "ws://$_host:10001");
  }

}
