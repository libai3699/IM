import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'mine_logic.dart';

class MinePage extends StatelessWidget {
  final logic = Get.find<MineLogic>();

  MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 用户信息板块
              Obx(() => _buildUserInfoPanel()),

              12.verticalSpace,

              // 功能菜单板块
              _buildFunctionPanel(),

              12.verticalSpace,

              // 退出登录板块
              _buildLogoutPanel(),

              20.verticalSpace, // 底部留白
            ],
          ),
        ),
      ),
    );
  }

  // 用户信息板块
  Widget _buildUserInfoPanel() => Container(
        width: double.infinity,
        color: Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: logic.viewMyInfo,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // 头像
                  AvatarView(
                    url: logic.imLogic.userInfo.value.faceURL,
                    text: logic.imLogic.userInfo.value.nickname,
                    width: 60.w,
                    height: 60.h,
                    borderRadius: BorderRadius.circular(30.r),
                    textStyle: Styles.ts_FFFFFF_14sp.copyWith(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  16.horizontalSpace,
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 用户名（VIP 金色显示）
                        (logic.imLogic.userInfo.value.nickname ?? '').toText
                          ..style = TextStyle(
                            color: _isVip() ? Styles.c_FFB300 : Color(0xFF1C1C1E),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        4.verticalSpace,
                        // 用户ID
                        GestureDetector(
                          onTap: logic.copyID,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: ${logic.imLogic.userInfo.value.userID ?? ''}',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              4.horizontalSpace,
                              Icon(
                                Icons.copy,
                                size: 14.w,
                                color: Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 二维码按钮
                  GestureDetector(
                    onTap: logic.viewMyQrcode,
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.qr_code,
                        size: 20.w,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  8.horizontalSpace,
                  // 右箭头
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFFC7C7CC),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // 功能菜单板块
  Widget _buildFunctionPanel() => Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            _buildMenuItem(
              icon: ImageRes.workingCircle,
              label: StrRes.friendsCircle,
              onTap: logic.friendsCircle,
              isFirst: true,
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: ImageRes.accountSetup,
              label: StrRes.accountSetup,
              onTap: logic.accountSetup,
              // isFirst: true, // 现在账户设置不再是第一个项目
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: ImageRes.aboutUs,
              label: StrRes.aboutUs,
              onTap: logic.aboutUs,
              isLast: true,
            ),
          ],
        ),
      );

  // 退出登录板块
  Widget _buildLogoutPanel() => Container(
        width: double.infinity,
        color: Colors.white,
        child: _buildMenuItem(
          icon: ImageRes.logout,
          label: StrRes.logout,
          onTap: logic.logout,
          isFirst: true,
          isLast: true,
          isLogout: true,
        ),
      );

  // 菜单项
  Widget _buildMenuItem({
    required String icon,
    required String label,
    Function()? onTap,
    bool isFirst = false,
    bool isLast = false,
    bool isLogout = false,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // 图标
                icon.toImage
                  ..width = 24.w
                  ..height = 24.h,
                16.horizontalSpace,
                // 标签
                Expanded(
                  child: label.toText
                    ..style = TextStyle(
                      color: isLogout ? Color(0xFFFF3B30) : Color(0xFF1C1C1E),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                ),
                // 右箭头
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ),
          ),
        ),
      );

  // 分割线
  Widget _buildDivider() => Container(
        height: 0.5.h,
        margin: EdgeInsets.only(left: 56.w),
        color: const Color(0xFFF2F2F7),
      );


}

bool _isVip() {
  try {
    final ex = Get.find<MineLogic>().imLogic.userInfo.value.ex;
    if (ex == null || ex.isEmpty) return false;
    final dynamic map = jsonDecode(ex);
    if (map is Map) {
      final v = map['vip'];
      return v == true || v == 'true' || v == 1;
    }
  } catch (_) {}
  return false;
}
