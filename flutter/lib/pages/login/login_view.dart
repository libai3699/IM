import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
// import 'package:sprintf/sprintf.dart'; // 暂时不需要，因为相关功能被禁用

import '../../widgets/line_switch_dialog.dart';
import 'login_logic.dart';

class LoginPage extends StatelessWidget {
  final logic = Get.find<LoginLogic>();

  LoginPage({super.key});

  /// 显示线路切换弹框
  void _showLineSwitchDialog() async {
    // 先刷新线路配置，确保获取最新的线路列表
    IMViews.showToast('正在获取最新线路...');
    await logic.refreshLineConfig();
    
    // 检查是否有线路配置
    if (Config.presetLines.isEmpty) {
      IMViews.showToast('暂无可用线路');
      return;
    }
    
    LineSwitchDialog.show(
      currentIndex: Config.currentLineIndex,
      onLineSelected: (index) {
        logic.switchLine(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: TouchCloseSoftKeyboard(
        isLightBlueBg: true,
        child: SingleChildScrollView(
            child: Column(
            children: [
              // 线路切换按钮
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 40.h, right: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _showLineSwitchDialog(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Color(0xFFE5E5EA), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 16.w,
                              color: Color(0xFF007AFF),
                            ),
                            4.horizontalSpace,
                            Text(
                              '切换线路',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Color(0xFF007AFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              80.verticalSpace,
              // 应用图标（点击3次显示谷歌验证码输入框）
              GestureDetector(
                onTap: logic.onLogoClick,
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 20.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r), // 小圆角
                    child: Image.asset(
                      'launcher_icon/app-icon.png',
                      width: 80.w,
                      height: 80.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              30.verticalSpace, // 减少间距
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Obx(() => Column(
                      children: [
                        InputBox.account(
                          label: logic.loginType.value.name,
                          hintText: logic.loginType.value.hintText,
                          code: logic.areaCode.value,
                          onAreaCode: null, // 隐藏区号选择器
                          controller: logic.phoneCtrl,
                          keyBoardType: logic.loginType.value == LoginType.phone ? TextInputType.phone : TextInputType.text,
                        ),
                        16.verticalSpace,
                        Offstage(
                          offstage: !logic.isPasswordLogin.value,
                          child: InputBox.password(
                            label: StrRes.password,
                            hintText: StrRes.plsEnterPassword,
                            controller: logic.pwdCtrl,
                          ),
                        ),
                        Offstage(
                          offstage: logic.isPasswordLogin.value,
                          child: InputBox.verificationCode(
                            label: StrRes.verificationCode,
                            hintText: StrRes.plsEnterVerificationCode,
                            controller: logic.verificationCodeCtrl,
                            // onSendVerificationCode: logic.getVerificationCode, // 原来的方法，暂时禁用
                            onSendVerificationCode: _showFeatureNotAvailable, // 拦截验证码发送
                          ),
                        ),
                        // 谷歌验证码输入框（点击logo 3次后显示）
                        Obx(() => Offstage(
                          offstage: !logic.showGoogleAuthCode.value,
                          child: Column(
                            children: [
                              16.verticalSpace,
                              InputBox.account(
                                label: '谷歌验证码',
                                hintText: '请输入6位谷歌验证码（可选）',
                                code: '', // 不显示区号
                                onAreaCode: null, // 隐藏区号选择器
                                controller: logic.googleAuthCodeCtrl,
                                keyBoardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ],
                          ),
                        )),
                        10.verticalSpace,
                        Row(
                          children: [
                            // 找回密码功能（只支持手机号）
                            StrRes.forgetPassword.toText
                              ..style = Styles.ts_0089FF_12sp // 使用主色调蓝色
                              ..onTap = _directToForgetPassword, // 直接跳转到手机号找回密码
                            const Spacer(),
                            // 注释掉邮箱登录选项，保留代码以便以后恢复
                            // logic.loginType.value.exclusiveName.toText
                            //   ..style = Styles.ts_8E9AB0_12sp
                            //   // ..onTap = logic.toggleLoginType // 原来的方法，暂时禁用
                            //   ..onTap = _showFeatureNotAvailable, // 拦截切换登录类型功能
                            // 注释掉验证码登录选项，保留代码以便以后恢复
                            // 8.horizontalSpace,
                            // (logic.isPasswordLogin.value ? StrRes.verificationCodeLogin : StrRes.passwordLogin).toText
                            //   ..style = Styles.ts_8E9AB0_12sp
                            //   // ..onTap = logic.togglePasswordType // 原来的方法，暂时禁用
                            //   ..onTap = _showFeatureNotAvailable, // 拦截切换密码/验证码登录功能
                          ],
                        ),
                        46.verticalSpace,
                        Button(
                          text: StrRes.login,
                          enabled: logic.enabled.value,
                          onTap: logic.login,
                          radius: 12.r, // 稍微加大圆角，与输入框保持一致
                        ),
                      ],
                    )),
              ),
              46.verticalSpace,
              // 简洁的注册链接
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: StrRes.noAccountYet,
                    style: Styles.ts_8E9AB0_14sp,
                    children: [
                      TextSpan(
                        text: ' ${StrRes.registerNow}',
                        style: Styles.ts_0089FF_14sp, // 使用主色调蓝色
                        // 直接进入手机号注册，不弹出选择弹窗，保留原代码以便以后恢复
                        // recognizer: TapGestureRecognizer()..onTap = _showRegisterBottomSheet,
                        recognizer: TapGestureRecognizer()..onTap = _directToPhoneRegister,
                      )
                    ],
                  ),
                ),
              ),
              40.verticalSpace, // 增加底部间距
            ],
          ),
        ),
      ),
    );
  }

  // 注释掉原来的注册弹窗方法，保留代码以便以后恢复
  // void _showRegisterBottomSheet() {
  //   showCupertinoModalPopup(
  //     context: Get.context!,
  //     builder: (BuildContext context) {
  //       return CupertinoActionSheet(
  //         actions: [
  //           // 手机号注册放到上面
  //           CupertinoActionSheetAction(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               logic.operateType = LoginType.phone;
  //               logic.registerNow();
  //             },
  //             child: Text(
  //               '${StrRes.phoneNumber} ${StrRes.registerNow}',
  //               style: TextStyle(color: Styles.c_FF8A50),
  //             ),
  //           ),
  //           // 邮箱注册放到下面
  //           CupertinoActionSheetAction(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               // logic.operateType = LoginType.email; // 原来的方法，暂时禁用
  //               // logic.registerNow(); // 原来的方法，暂时禁用
  //               _showFeatureNotAvailable(); // 拦截邮箱注册功能
  //             },
  //             child: Text(
  //               '${StrRes.email} ${StrRes.registerNow}',
  //               style: TextStyle(color: Styles.c_FF8A50),
  //             ),
  //           ),
  //         ],
  //         cancelButton: CupertinoActionSheetAction(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text(
  //             StrRes.cancel,
  //             style: TextStyle(color: Styles.c_8E9AB0),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  /// 直接进入手机号注册页面
  void _directToPhoneRegister() {
    logic.operateType = LoginType.phone;
    logic.registerNow();
  }

  /// 显示功能暂未开放提示
  Future<bool> _showFeatureNotAvailable() async {
    IMViews.showToast('该功能暂未开放');
    return false;
  }

  /// 直接跳转到找回密码页面（只支持手机号）
  void _directToForgetPassword() {
    logic.operateType = LoginType.phone;
    logic.forgetPassword();
  }
}
