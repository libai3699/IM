import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/pages/login/login_logic.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/app_controller.dart';

class RegisterLogic extends GetxController {
  final appLogic = Get.find<AppController>();
  final phoneCtrl = TextEditingController();
  final invitationCodeCtrl = TextEditingController();
  final areaCode = "+86".obs;
  final enabled = false.obs;
  final loginController = Get.find<LoginLogic>();
  String? get email => loginController.operateType == LoginType.email ? phoneCtrl.text.trim() : null;
  String? get phone => loginController.operateType == LoginType.phone ? phoneCtrl.text.trim() : null;

  @override
  void onClose() {
    phoneCtrl.dispose();
    invitationCodeCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    phoneCtrl.addListener(_onChanged);
    invitationCodeCtrl.addListener(_onChanged);
    appLogic.queryClientConfig();
    super.onInit();
  }

  _onChanged() {
    var valid = false;
    if (loginController.operateType == LoginType.phone) {
      // 允许英文等字符，至少 6 位（不再限制纯数字）
      valid = phoneCtrl.text.trim().length >= 6;
    } else {
      valid = phoneCtrl.text.trim().isNotEmpty;
    }
    if (needInvitationCodeRegister) {
      valid = valid && invitationCodeCtrl.text.trim().isNotEmpty;
    }
    enabled.value = valid;
  }

  bool get needInvitationCodeRegister => appLogic.needInvitationCodeRegister;

  bool get needVerificationCodeRegister => appLogic.needVerificationCodeRegister;

  String? get invitationCode => IMUtils.emptyStrToNull(invitationCodeCtrl.text);

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  /// [usedFor] 1：注册，2：重置密码
  Future<bool> requestVerificationCode() => Apis.requestVerificationCode(
        areaCode: areaCode.value,
        phoneNumber: phone,
        email: email,
        usedFor: 1,
        invitationCode: invitationCode,
      );

  void next() async {
    await appLogic.queryClientConfig();

    if (loginController.operateType == LoginType.phone) {
      if (phoneCtrl.text.trim().length < 6) {
        IMViews.showToast('请输入至少6位手机号');
        return;
      }
    }

    if (loginController.operateType == LoginType.email && !phoneCtrl.text.isEmail) {
      IMViews.showToast(StrRes.plsEnterRightEmail);
      return;
    }
    if (needVerificationCodeRegister) {
      final success = await LoadingView.singleton.wrap(
        asyncFunction: () => requestVerificationCode(),
      );
      if (success) {
        AppNavigator.startVerifyPhone(
          areaCode: areaCode.value,
          phoneNumber: phone,
          email: email,
          usedFor: 1,
          invitationCode: invitationCode,
        );
      }
    } else {
      AppNavigator.startSetPassword(
        areaCode: areaCode.value,
        phoneNumber: phone,
        email: email,
        usedFor: 1,
        verificationCode: '',
        invitationCode: invitationCode,
      );
    }
  }
}
