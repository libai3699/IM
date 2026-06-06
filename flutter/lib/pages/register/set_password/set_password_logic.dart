import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/controller/im_controller.dart';
import '../../../core/controller/push_controller.dart';
import '../../../routes/app_navigator.dart';

/// 注册流程：设置昵称与密码（仅 usedFor=1）
class SetPasswordLogic extends GetxController {
  final appLogic = Get.find<AppController>();
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final nicknameCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final pwdAgainCtrl = TextEditingController();
  final enabled = false.obs;
  String? phoneNumber;
  String? email;
  late String areaCode;
  late String verificationCode;
  String? invitationCode;

  @override
  void onClose() {
    nicknameCtrl.dispose();
    pwdCtrl.dispose();
    pwdAgainCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    phoneNumber = Get.arguments['phoneNumber'];
    email = Get.arguments['email'];
    areaCode = Get.arguments['areaCode'] ?? '';
    verificationCode = Get.arguments['verificationCode'] ?? '';
    invitationCode = Get.arguments['invitationCode'];
    nicknameCtrl.addListener(_onChanged);
    pwdCtrl.addListener(_onChanged);
    pwdAgainCtrl.addListener(_onChanged);
    super.onInit();
  }

  void _onChanged() {
    enabled.value = nicknameCtrl.text.trim().isNotEmpty &&
        pwdCtrl.text.trim().isNotEmpty &&
        pwdAgainCtrl.text.trim().isNotEmpty;
  }

  bool _checkingInput() {
    if (nicknameCtrl.text.trim().isEmpty) {
      IMViews.showToast(StrRes.plsEnterYourNickname);
      return false;
    }
    if (!IMUtils.isValidPassword(pwdCtrl.text)) {
      IMViews.showToast(StrRes.wrongPasswordFormat);
      return false;
    }
    if (pwdCtrl.text != pwdAgainCtrl.text) {
      IMViews.showToast(StrRes.twicePwdNoSame);
      return false;
    }
    return true;
  }

  void nextStep() {
    if (_checkingInput()) {
      register();
    }
  }

  void register() async {
    await appLogic.queryClientConfig();
    if (appLogic.needVerificationCodeRegister && verificationCode.isEmpty) {
      IMViews.showToast('请先完成短信验证码验证');
      Get.back();
      return;
    }

    await LoadingView.singleton.wrap(asyncFunction: () async {
      final data = await Apis.register(
        nickname: nicknameCtrl.text.trim(),
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        email: email,
        password: pwdCtrl.text,
        verificationCode: verificationCode,
        invitationCode: invitationCode,
      );
      if (null == IMUtils.emptyStrToNull(data.imToken) ||
          null == IMUtils.emptyStrToNull(data.chatToken)) {
        AppNavigator.startLogin();
        return;
      }
      final loginAccount = {
        'areaCode': areaCode,
        'phoneNumber': phoneNumber,
        'email': email,
      };
      await DataSp.putLoginCertificate(data);
      await DataSp.putLoginAccount(loginAccount);
      DataSp.putLoginType(email != null ? 1 : 0);
      await imLogic.login(data.userID, data.imToken);
      pushLogic.login(data.userID);
      AppNavigator.startMain();
    });
  }
}
