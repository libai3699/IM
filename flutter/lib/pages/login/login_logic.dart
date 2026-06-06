import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/pages/mine/server_config/server_config_binding.dart';
import 'package:openim/pages/mine/server_config/server_config_view.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';

enum LoginType {
  phone,
  email,
}

extension LoginTypeExt on LoginType {
  int get rawValue {
    switch (this) {
      case LoginType.phone:
        return 0;
      case LoginType.email:
        return 1;
    }
  }

  String get name {
    switch (this) {
      case LoginType.phone:
        return StrRes.phoneNumber;
      case LoginType.email:
        return StrRes.email;
    }
  }

  String get hintText {
    switch (this) {
      case LoginType.phone:
        return StrRes.plsEnterPhoneNumber;
      case LoginType.email:
        return StrRes.plsEnterEmail;
    }
  }

  String get exclusiveName {
    switch (this) {
      case LoginType.phone:
        return StrRes.email;
      case LoginType.email:
        return StrRes.phoneNumber;
    }
  }
}

class LoginLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final phoneCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final verificationCodeCtrl = TextEditingController();
  final googleAuthCodeCtrl = TextEditingController(); // 谷歌验证码控制器
  final obscureText = true.obs;
  final enabled = false.obs;
  final areaCode = "+86".obs;
  final isPasswordLogin = true.obs;
  final versionInfo = ''.obs;
  final loginType = LoginType.phone.obs;
  final showGoogleAuthCode = false.obs; // 是否显示谷歌验证码输入框
  int _logoClickCount = 0; // logo点击次数
  String? get email => loginType.value == LoginType.email ? phoneCtrl.text.trim() : null;
  String? get phone => loginType.value == LoginType.phone ? phoneCtrl.text.trim() : null;
  LoginType operateType = LoginType.phone;

  // 线路配置相关
  bool _lineConfigLoaded = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  _initData() async {
    var map = DataSp.getLoginAccount();
    if (map is Map) {
      String? phoneNumber = map["phoneNumber"];
      String? areaCode = map["areaCode"];
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        phoneCtrl.text = phoneNumber;
      }
      if (areaCode != null && areaCode.isNotEmpty) {
        this.areaCode.value = areaCode;
      }
    }

    final type = DataSp.getLoginType();
    loginType.value = type == 0 ? LoginType.phone : LoginType.email;
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    pwdCtrl.dispose();
    verificationCodeCtrl.dispose();
    googleAuthCodeCtrl.dispose();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    _initData();
    phoneCtrl.addListener(_onChanged);
    pwdCtrl.addListener(_onChanged);
    verificationCodeCtrl.addListener(_onChanged);

    // 初始化网络监听和线路配置
    _initNetworkAndLineConfig();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    getPackageInfo();
  }

  _onChanged() {
    enabled.value = isPasswordLogin.value && phoneCtrl.text.trim().isNotEmpty && pwdCtrl.text.trim().isNotEmpty ||
        !isPasswordLogin.value && phoneCtrl.text.trim().isNotEmpty && verificationCodeCtrl.text.trim().isNotEmpty;
  }

  login() {
    DataSp.putLoginType(loginType.value.rawValue);
    LoadingView.singleton.wrap(asyncFunction: () async {
      var suc = await _login();
      if (suc) {
        Get.find<CacheController>().resetCache();
        AppNavigator.startMain();
      }
    });
  }

  Future<bool> _login() async {
    try {
      // 手机号至少 6 位，允许英文等字符（不再限制纯数字）
      if (loginType.value == LoginType.phone && phoneCtrl.text.trim().length < 6) {
        IMViews.showToast('请输入至少6位手机号');
        return false;
      }

      if (email?.isNotEmpty == true && !phoneCtrl.text.isEmail) {
        IMViews.showToast(StrRes.plsEnterRightEmail);
        return false;
      }

      final password = IMUtils.emptyStrToNull(pwdCtrl.text);
      final code = IMUtils.emptyStrToNull(verificationCodeCtrl.text);
      final googleAuthCode = IMUtils.emptyStrToNull(googleAuthCodeCtrl.text); // 谷歌验证码（可选）
      final data = await Apis.login(
        areaCode: areaCode.value,
        phoneNumber: phone,
        email: email,
        password: isPasswordLogin.value ? password : null,
        verificationCode: isPasswordLogin.value ? null : code,
        googleAuthCode: googleAuthCode, // 传递谷歌验证码
      );
      final account = {
        'areaCode': areaCode.value,
        'phoneNumber': phoneCtrl.text.trim(),
      };
      await DataSp.putLoginCertificate(data);
      await DataSp.putLoginAccount(account);
      // Logger.print('login : ${data.userID}, token: ${data.imToken}');
      await imLogic.login(data.userID, data.imToken);
      // Logger.print('im login success');
      pushLogic.login(data.userID);
      // Logger.print('push login success');
      return true;
    } catch (e) {
      // Logger.print('login e: $e');
    }
    return false;
  }

  void togglePasswordType() {
    isPasswordLogin.value = !isPasswordLogin.value;
  }

  void toggleLoginType() {
    if (loginType.value == LoginType.phone) {
      loginType.value = LoginType.email;
    } else {
      loginType.value = LoginType.phone;
    }

    phoneCtrl.text = '';
  }

  /// 刷新线路配置（给UI调用）
  Future<void> refreshLineConfig() async {
    Logger.print('[线路配置] 手动刷新线路配置...');
    await _loadDynamicLineConfig();
  }

  /// 切换线路
  void switchLine(int index) async {
    try {
      // Logger.print('开始切换线路到索引: $index');

      // 清除可能存在的服务器配置缓存
      await DataSp.putServerConfig({});
      // Logger.print('已清除服务器配置缓存');

      // 保存线路索引
      await Config.setCurrentLineIndex(index);

      // 验证保存是否成功
      // final savedIndex = DataSp.getCurrentLineIndex();
      // Logger.print('保存后的线路索引: $savedIndex');

      final lineConfig = Config.presetLines[index];

      // 显示当前配置信息用于调试
      // Logger.print('切换到线路: ${lineConfig['name']}');
      // Logger.print('服务器IP: ${Config.serverIp}');
      // Logger.print('认证URL: ${Config.appAuthUrl}');
      // Logger.print('API URL: ${Config.imApiUrl}');
      // Logger.print('WS URL: ${Config.imWsUrl}');

      // 只显示线路名称，不显示域名/服务器信息
      IMViews.showToast('已切换到${lineConfig['name']}');
    } catch (e) {
      // Logger.print('切换线路失败: $e');
      IMViews.showToast('切换线路失败: $e');
    }
  }

  Future<bool> getVerificationCode() async {
    // 修改手机号校验规则：至少6个字符即可
    if (phone?.isNotEmpty == true && phoneCtrl.text.trim().length < 6) {
      IMViews.showToast('手机号必须至少6个字符');
      return false;
    }

    if (email?.isNotEmpty == true && !phoneCtrl.text.isEmail) {
      IMViews.showToast(StrRes.plsEnterRightEmail);
      return false;
    }

    return sendVerificationCode();
  }

  /// [usedFor] 1：注册，2：重置密码 3：登录
  Future<bool> sendVerificationCode() => LoadingView.singleton.wrap(
      asyncFunction: () => Apis.requestVerificationCode(
            areaCode: areaCode.value,
            phoneNumber: phone,
            email: email,
            usedFor: 3,
          ));

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  void configService() => Get.to(
        () => ServerConfigPage(),
        binding: ServerConfigBinding(),
      );

  void registerNow() => AppNavigator.startRegister();

  void forgetPassword() => AppNavigator.startForgetPassword();

  void getPackageInfo() async {
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // final version = packageInfo.version;
    // final appName = packageInfo.appName;
    // final buildNumber = packageInfo.buildNumber;

    versionInfo.value = '番茄';
  }

  /// 处理logo点击事件（点击3次切换显示/隐藏谷歌验证码输入框）
  void onLogoClick() {
    _logoClickCount++;
    if (_logoClickCount >= 3) {
      showGoogleAuthCode.value = !showGoogleAuthCode.value; // 切换显示/隐藏状态
      _logoClickCount = 0; // 重置计数
    }
  }

  /// 初始化网络监听和线路配置
  Future<void> _initNetworkAndLineConfig() async {
    // 1. 先检查是否有缓存的线路配置
    final cachedLines = DataSp.getDynamicLineConfig();

    if (cachedLines.isNotEmpty) {
      // 有缓存，直接使用
      Logger.print('[线路配置] 使用本地缓存的线路配置');
      _lineConfigLoaded = true;
    } else {
      // 没有缓存，使用保底线路
      Logger.print('[线路配置] 没有本地缓存，使用保底线路');
      await _useFallbackLine();
    }

    // 2. 检查当前网络状态
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNetwork = connectivityResult != ConnectivityResult.none;

    if (hasNetwork) {
      // 如果已有网络，立即尝试获取最新线路配置
      Logger.print('[线路配置] 检测到网络已连接，立即获取线路配置');
      _loadDynamicLineConfig();
    } else {
      Logger.print('[线路配置] 当前无网络连接，等待网络连接');
    }

    // 3. 监听网络状态变化
    _setupNetworkListener();

    // 4. 启动定时器，定期尝试获取线路配置（作为备用）
    _startRetryTimer();
  }

  /// 设置网络状态监听
  void _setupNetworkListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final hasNetwork = result != ConnectivityResult.none;

      if (hasNetwork) {
        Logger.print('[线路配置] 🌐 网络已连接，尝试获取线路配置');
        // 延迟1秒，确保网络真正可用（iOS权限刚授予时可能需要一点时间）
        Future.delayed(const Duration(seconds: 1), () {
          _loadDynamicLineConfig();
        });
      } else {
        Logger.print('[线路配置] ❌ 网络已断开');
      }
    });
  }

  /// 启动重试定时器
  void _startRetryTimer() {
    if (_lineConfigLoaded) return;

    // 每30秒尝试一次，直到成功
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lineConfigLoaded) {
        timer.cancel();
        return;
      }
      Logger.print('[线路配置] 定时重试获取线路配置...');
      _loadDynamicLineConfig();
    });
  }

  /// 使用保底线路
  Future<void> _useFallbackLine() async {
    try {
      Logger.print('[线路配置] 使用保底线路: open.ijqtx.com');

      final fallbackLine = {
        'name': '保底线路',
        'serverIP': 'open.qweenew.com',
        'authUrl': 'https://open.qweenew.com/chat',
        'apiUrl': 'https://open.qweenew.com/api',
        'wsUrl': 'wss://open.qweenew.com/msg_gateway',
      };

      // 保存保底线路配置
      await DataSp.putDynamicLineConfig([fallbackLine]);
      await Config.setCurrentLineIndex(0);

      Logger.print('[线路配置] 保底线路配置完成');
    } catch (e) {
      Logger.print('[线路配置] 设置保底线路失败: $e');
    }
  }

  /// 动态获取线路配置（竞速模式：哪个快用哪个）
  Future<void> _loadDynamicLineConfig() async {
    // 添加时间戳参数绕过所有 CDN 缓存（确保获取最新配置）
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
        _lineConfigLoaded = true;
        Logger.print('[线路配置] ✅ 动态线路配置加载成功（竞速模式）');
        // 注意：其他未完成的请求会自动超时并被取消，这是正常的
        return;
      }
    } catch (e) {
      Logger.print('[线路配置] ❌ 所有源都失败: $e');
    }

    // 所有URL都失败，使用保底线路
    Logger.print('[线路配置] ⚠️ 所有配置URL都失败，使用保底线路');
    if (!_lineConfigLoaded) {
      await _useFallbackLine();
    }
  }

  /// 从单个URL获取配置（用于竞速模式）
  Future<List<String>?> _fetchConfigFromUrl(String url) async {
    try {
      Logger.print('[线路配置] 🚀 竞速请求: $url');

      final response = await dio.get(
        url,
        options: Options(
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
      final saveResult = await DataSp.putDynamicLineConfig(newLines);
      Logger.print('保存线路配置结果: $saveResult');

      // 验证保存
      final savedLines = DataSp.getDynamicLineConfig();
      Logger.print('验证保存的线路配置: $savedLines');

      // 如果当前没有选择线路，默认选择第一个
      final currentIndex = DataSp.getCurrentLineIndex();
      if (currentIndex == null) {
        await Config.setCurrentLineIndex(0);
        Logger.print('设置默认线路索引为0');
      }

      Logger.print('动态线路配置更新完成');
    } catch (e) {
      Logger.print('更新线路配置失败: $e');
    }
  }
}
