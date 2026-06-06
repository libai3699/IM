import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'my_qrcode_logic.dart';

class MyQrcodePage extends StatelessWidget {
  final logic = Get.find<MyQrcodeLogic>();

  MyQrcodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: TitleBar.back(
          title: StrRes.qrcode,
        ),
        backgroundColor: Styles.c_F8F9FA,
        body: Container(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.only(top: 22.h),
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            width: 331.w,
            height: 520.h, // 增加高度以容纳更大的二维码和新布局
            decoration: BoxDecoration(
              color: Styles.c_FFFFFF,
              borderRadius: BorderRadius.circular(10.r),
              // 去掉阴影
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 30.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AvatarView(
                        width: 48.w,
                        height: 48.h,
                        url: logic.imLogic.userInfo.value.faceURL,
                        text: logic.imLogic.userInfo.value.nickname,
                        textStyle: Styles.ts_FFFFFF_14sp,
                      ),
                      12.horizontalSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 用户名
                          (logic.imLogic.userInfo.value.nickname ?? '').toText
                            ..style = Styles.ts_0C1C33_20sp,
                          4.verticalSpace,
                          // 用户ID
                          ('ID: ${logic.imLogic.userInfo.value.userID ?? ''}').toText
                            ..style = Styles.ts_8E9AB0_14sp,
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 120.h,
                  width: 272.w,
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        // 更大的二维码，去掉边框
                        Container(
                          width: 240.w, // 增大二维码容器
                          height: 240.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Styles.c_FFFFFF,
                            // 去掉边框
                          ),
                          child: QrImageView(
                            data: logic.buildQRContent(),
                            size: 220.w, // 增大二维码尺寸
                            backgroundColor: Styles.c_FFFFFF,
                          ),
                        ),
                        20.verticalSpace,
                        // 提示文字移到二维码下面
                        StrRes.qrcodeHint.toText
                          ..style = Styles.ts_8E9AB0_15sp
                          ..textAlign = TextAlign.center,
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
