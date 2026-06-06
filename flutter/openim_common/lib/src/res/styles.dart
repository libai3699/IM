import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Styles {
  Styles._();

  static Color c_0089FF = const Color(0xFF0099FF); // 主题色
  static Color c_0C1C33 = const Color(0xFF0C1C33); // 黑色字体
  static Color c_8E9AB0 = const Color(0xFF8E9AB0); // 说明文字
  static Color c_E8EAEF = const Color(0xFFE8EAEF); // 分割线
  static Color c_FF381F = const Color(0xFFFF381F); // 警告色
  static Color c_FFFFFF = const Color(0xFFFFFFFF); // 警告色
  static Color c_18E875 = const Color(0xFF18E875); // 在线
  static Color c_F0F2F6 = const Color(0xFFF0F2F6); // 聊天页底部
  static Color c_000000 = const Color(0xFF000000); //
  static Color c_92B3E0 = const Color(0xFF92B3E0);
  static Color c_F2F8FF = const Color(0xFFF2F8FF); // 同步成功背景色
  static Color c_F8F9FA = const Color(0xFFF8F9FA); // 默认背景
  static Color c_6085B1 = const Color(0xFF6085B1);
  static Color c_FFB300 = const Color(0xFFFFB300); // 会议状态
  static Color c_FFE1DD = const Color(0xFFFFE1DD); // 同步失败背景色
  static Color c_707070 = const Color(0xFF707070);
  static Color c_4CAF50 = const Color(0xFF4CAF50); // 成功绿色
  static Color c_E8F5E9 = const Color(0xFFE8F5E9); // 成功绿色背景

  // 原橙色主题色系改为蓝色主题
  static Color c_FF8A50 = const Color(0xFF0099FF); // 主要蓝色 - 替换原橙色
  static Color c_FFB380 = const Color(0xFF66B3FF); // 浅蓝色 - 替换原浅橙色
  static Color c_FFF4EF = const Color(0xFFE6F3FF); // 极浅蓝色背景 - 替换原极浅橙色背景
  static Color c_FFE5D6 = const Color(0xFFCCE6FF); // 浅蓝色背景 - 替换原浅橙色背景
  static Color c_FF9966 = const Color(0xFF3399FF); // 中等蓝色 - 替换原中等橙色
  static Color c_FFCC99 = const Color(0xFF99CCFF); // 温暖蓝色 - 替换原温暖橙色

  // 收藏功能相关颜色
  static Color c_1B72EC = const Color(0xFF1B72EC); // 主要蓝色
  static Color c_10CC47 = const Color(0xFF10CC47); // 成功绿色
  static Color c_FF9500 = const Color(0xFFFF9500); // 警告橙色
  static Color c_F7F8FA = const Color(0xFFF7F8FA); // 浅灰背景

  static Color c_92B3E0_opacity50 = c_92B3E0.withOpacity(.5); // 气泡背景
  static Color c_E8EAEF_opacity50 = c_E8EAEF.withOpacity(.5);
  static Color c_F4F5F7 = const Color(0xFFF4F5F7);
  static Color c_CCE7FE = const Color(0xFFCCE7FE);

  // static Color c_E8EAEF_opacity30 = c_E8EAEF.withOpacity(.3); // 默认背景

  static Color c_FFFFFF_opacity0 = c_FFFFFF.withOpacity(.0);
  static Color c_FFFFFF_opacity30 = c_FFFFFF.withOpacity(.3);
  static Color c_FFFFFF_opacity50 = c_FFFFFF.withOpacity(.5);
  static Color c_FFFFFF_opacity70 = c_FFFFFF.withOpacity(.7);
  static Color c_0089FF_opacity10 = c_0089FF.withOpacity(.1);
  static Color c_0089FF_opacity20 = c_0089FF.withOpacity(.2);
  static Color c_0089FF_opacity50 = c_0089FF.withOpacity(.5);

  // 蓝色系透明度变体 - 原橙色变量名保留，值改为蓝色
  static Color c_FF8A50_opacity10 = c_FF8A50.withOpacity(.1);
  static Color c_FF8A50_opacity20 = c_FF8A50.withOpacity(.2);
  static Color c_FF8A50_opacity30 = c_FF8A50.withOpacity(.3);
  static Color c_FF8A50_opacity50 = c_FF8A50.withOpacity(.5);
  static Color c_FF8A50_opacity70 = c_FF8A50.withOpacity(.7);
  static Color c_FFB380_opacity20 = c_FFB380.withOpacity(.2);
  static Color c_FFB380_opacity30 = c_FFB380.withOpacity(.3);
  static Color c_FFE5D6_opacity50 = c_FFE5D6.withOpacity(.5);
  static Color c_FFE5D6_opacity70 = c_FFE5D6.withOpacity(.7);

  static Color c_FF381F_opacity10 = c_FF381F.withOpacity(.1);
  static Color c_8E9AB0_opacity13 = c_8E9AB0.withOpacity(.13);
  static Color c_8E9AB0_opacity15 = c_8E9AB0.withOpacity(.15);
  static Color c_8E9AB0_opacity16 = c_8E9AB0.withOpacity(.16);
  static Color c_8E9AB0_opacity30 = c_8E9AB0.withOpacity(.3);
  static Color c_8E9AB0_opacity50 = c_8E9AB0.withOpacity(.5);
  static Color c_0C1C33_opacity30 = c_0C1C33.withOpacity(.3);
  static Color c_0C1C33_opacity60 = c_0C1C33.withOpacity(.6);
  static Color c_0C1C33_opacity85 = c_0C1C33.withOpacity(.85);
  static Color c_0C1C33_opacity80 = c_0C1C33.withOpacity(.8);
  static Color c_FF381F_opacity70 = c_FF381F.withOpacity(.7);
  static Color c_000000_opacity70 = c_000000.withOpacity(.7);
  static Color c_000000_opacity15 = c_000000.withOpacity(.15);
  static Color c_000000_opacity12 = c_000000.withOpacity(.12);
  static Color c_000000_opacity4 = c_000000.withOpacity(.04);

  /// FFFFFF
  static TextStyle ts_FFFFFF_21sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 21.sp,
  );
  static TextStyle ts_FFFFFF_20sp_medium = TextStyle(
    color: c_FFFFFF,
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FFFFFF_18sp_medium = TextStyle(
    color: c_FFFFFF,
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FFFFFF_17sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 17.sp,
  );
  static TextStyle ts_FFFFFF_opacity70_17sp = TextStyle(
    color: c_FFFFFF_opacity70,
    fontSize: 17.sp,
  );
  static TextStyle ts_FFFFFF_17sp_semibold = TextStyle(
    color: c_FFFFFF,
    fontSize: 17.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_FFFFFF_17sp_medium = TextStyle(
    color: c_FFFFFF,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FFFFFF_16sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 16.sp,
  );
  static TextStyle ts_FFFFFF_14sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 14.sp,
  );
  static TextStyle ts_FFFFFF_opacity70_14sp = TextStyle(
    color: c_FFFFFF_opacity70,
    fontSize: 14.sp,
  );
  static TextStyle ts_FFFFFF_14sp_medium = TextStyle(
    color: c_FFFFFF,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FFFFFF_12sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 12.sp,
  );
  static TextStyle ts_FFFFFF_10sp = TextStyle(
    color: c_FFFFFF,
    fontSize: 10.sp,
  );

  /// 8E9AB0
  static TextStyle ts_8E9AB0_10sp_semibold = TextStyle(
    color: c_8E9AB0,
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_8E9AB0_10sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 10.sp,
  );
  static TextStyle ts_8E9AB0_12sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 12.sp,
  );
  static TextStyle ts_8E9AB0_13sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 13.sp,
  );
  static TextStyle ts_8E9AB0_14sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 14.sp,
  );
  static TextStyle ts_8E9AB0_15sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 15.sp,
  );
  static TextStyle ts_8E9AB0_16sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 16.sp,
  );
  static TextStyle ts_8E9AB0_17sp = TextStyle(
    color: c_8E9AB0,
    fontSize: 17.sp,
  );
  static TextStyle ts_8E9AB0_opacity50_17sp = TextStyle(
    color: c_8E9AB0_opacity50,
    fontSize: 17.sp,
  );

  /// 0C1C33
  static TextStyle ts_0C1C33_10sp = TextStyle(
    color: c_0C1C33,
    fontSize: 10.sp,
  );
  static TextStyle ts_0C1C33_12sp = TextStyle(
    color: c_0C1C33,
    fontSize: 12.sp,
  );
  static TextStyle ts_0C1C33_12sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0C1C33_14sp = TextStyle(
    color: c_0C1C33,
    fontSize: 14.sp,
  );
  static TextStyle ts_0C1C33_14sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0C1C33_17sp = TextStyle(
    color: c_0C1C33,
    fontSize: 17.sp,
  );
  static TextStyle ts_0C1C33_17sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0C1C33_17sp_semibold = TextStyle(
    color: c_0C1C33,
    fontSize: 17.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_0C1C33_20sp = TextStyle(
    color: c_0C1C33,
    fontSize: 20.sp,
  );
  static TextStyle ts_0C1C33_20sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0C1C33_20sp_semibold = TextStyle(
    color: c_0C1C33,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
  );

  /// 0089FF
  static TextStyle ts_0089FF_10sp_semibold = TextStyle(
    color: c_0089FF,
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_0089FF_10sp = TextStyle(
    color: c_0089FF,
    fontSize: 10.sp,
  );
  static TextStyle ts_0089FF_12sp = TextStyle(
    color: c_0089FF,
    fontSize: 12.sp,
  );
  static TextStyle ts_0089FF_14sp = TextStyle(
    color: c_0089FF,
    fontSize: 14.sp,
  );
  static TextStyle ts_0089FF_16sp = TextStyle(
    color: c_0089FF,
    fontSize: 16.sp,
  );
  static TextStyle ts_0089FF_17sp = TextStyle(
    color: c_0089FF,
    fontSize: 17.sp,
  );
  static TextStyle ts_0089FF_17sp_semibold = TextStyle(
    color: c_0089FF,
    fontSize: 17.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_0089FF_17sp_medium = TextStyle(
    color: c_0089FF,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0089FF_14sp_medium = TextStyle(
    color: c_0089FF,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle ts_0089FF_22sp_semibold = TextStyle(
    color: c_0089FF,
    fontSize: 22.sp,
    fontWeight: FontWeight.w600,
  );

  /// FF8A50 - 原橙色系文本样式改为蓝色（变量名保留）
  static TextStyle ts_FF8A50_10sp = TextStyle(
    color: c_FF8A50,
    fontSize: 10.sp,
  );
  static TextStyle ts_FF8A50_10sp_semibold = TextStyle(
    color: c_FF8A50,
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_FF8A50_12sp = TextStyle(
    color: c_FF8A50,
    fontSize: 12.sp,
  );
  static TextStyle ts_FF8A50_14sp = TextStyle(
    color: c_FF8A50,
    fontSize: 14.sp,
  );
  static TextStyle ts_FF8A50_14sp_medium = TextStyle(
    color: c_FF8A50,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FF8A50_16sp = TextStyle(
    color: c_FF8A50,
    fontSize: 16.sp,
  );
  static TextStyle ts_FF8A50_17sp = TextStyle(
    color: c_FF8A50,
    fontSize: 17.sp,
  );
  static TextStyle ts_FF8A50_17sp_medium = TextStyle(
    color: c_FF8A50,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_FF8A50_17sp_semibold = TextStyle(
    color: c_FF8A50,
    fontSize: 17.sp,
    fontWeight: FontWeight.w600,
  );
  static TextStyle ts_FF8A50_22sp_semibold = TextStyle(
    color: c_FF8A50,
    fontSize: 22.sp,
    fontWeight: FontWeight.w600,
  );

  /// FF381F
  static TextStyle ts_FF381F_17sp = TextStyle(
    color: c_FF381F,
    fontSize: 17.sp,
  );
  static TextStyle ts_FF381F_14sp = TextStyle(
    color: c_FF381F,
    fontSize: 14.sp,
  );
  static TextStyle ts_FF381F_12sp = TextStyle(
    color: c_FF381F,
    fontSize: 12.sp,
  );
  static TextStyle ts_FF381F_10sp = TextStyle(
    color: c_FF381F,
    fontSize: 10.sp,
  );

  /// 4CAF50 - 成功绿色
  static TextStyle ts_4CAF50_12sp = TextStyle(
    color: c_4CAF50,
    fontSize: 12.sp,
  );

  /// 6085B1
  static TextStyle ts_6085B1_17sp_medium = TextStyle(
    color: c_6085B1,
    fontSize: 17.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_6085B1_17sp = TextStyle(
    color: c_6085B1,
    fontSize: 17.sp,
  );
  static TextStyle ts_6085B1_12sp = TextStyle(
    color: c_6085B1,
    fontSize: 12.sp,
  );
  static TextStyle ts_6085B1_14sp = TextStyle(
    color: c_6085B1,
    fontSize: 14.sp,
  );

  // 收藏功能相关文本样式
  static TextStyle ts_0C1C33_16sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_0C1C33_18sp_medium = TextStyle(
    color: c_0C1C33,
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle ts_1B72EC_16sp = TextStyle(
    color: c_1B72EC,
    fontSize: 16.sp,
  );
  static TextStyle ts_1B72EC_14sp = TextStyle(
    color: c_1B72EC,
    fontSize: 14.sp,
  );
  static TextStyle ts_0C1C33_16sp = TextStyle(
    color: c_0C1C33,
    fontSize: 16.sp,
  );
}
