import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const TitleBar({
    Key? key,
    this.height,
    this.left,
    this.center,
    this.right,
    this.backgroundColor,
    this.showUnderline = false,
  }) : super(key: key);
  final double? height;
  final Widget? left;
  final Widget? center;
  final Widget? right;
  final Color? backgroundColor;
  final bool showUnderline;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: backgroundColor ?? Styles.c_FFFFFF,
        padding: EdgeInsets.only(top: mq.padding.top),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: showUnderline
              ? BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(color: Styles.c_E8EAEF, width: .5),
                  ),
                )
              : null,
          child: Row(
            children: [
              if (null != left) left!,
              if (null != center) center!,
              if (null != right) right!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 44.h);

  TitleBar.conversation(
      {super.key,
      String? statusStr,
      bool isFailed = false,
      Function()? onClickCallBtn,
      Function()? onScan,
      Function()? onAddFriend,
      Function()? onAddGroup,
      Function()? onCreateGroup,
      Function()? onVideoMeeting,
      Function()? onSearch, // 添加搜索回调
      Function()? onLineSwitch, // 添加线路切换回调
      CustomPopupMenuController? popCtrl,
      bool showCreateGroup = true,
      this.left})
      : backgroundColor = null,
        height = 62.h,
        showUnderline = false,
        center = null,
        right = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 添加线路切换按钮
            if (onLineSwitch != null)
              GestureDetector(
                onTap: onLineSwitch,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12.r),
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
                        '线路',
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
            if (onLineSwitch != null) 8.horizontalSpace,
            // 添加搜索按钮
            if (onSearch != null)
              ImageRes.searchBlack.toImage
                ..width = 28.w
                ..height = 28.h
                ..onTap = onSearch,
            if (onSearch != null) 16.horizontalSpace,
            PopButton(
              popCtrl: popCtrl,
              barrierColor: Colors.black.withOpacity(0.3), // 添加30%透明度的黑色遮罩
              menus: [
                PopMenuInfo(
                  text: StrRes.scan,
                  icon: ImageRes.popMenuScan,
                  onTap: onScan,
                ),
                PopMenuInfo(
                  text: StrRes.addFriend,
                  icon: ImageRes.popMenuAddFriend,
                  onTap: onAddFriend,
                ),
                PopMenuInfo(
                  text: StrRes.addGroup,
                  icon: ImageRes.popMenuAddGroup,
                  onTap: onAddGroup,
                ),
                if (showCreateGroup)
                  PopMenuInfo(
                    text: StrRes.createGroup,
                    icon: ImageRes.popMenuCreateGroup,
                    onTap: onCreateGroup,
                  ),
                PopMenuInfo(
                  text: StrRes.videoMeeting,
                  icon: ImageRes.popMenuVideoMeeting,
                  onTap: onVideoMeeting,
                ),
              ],
              child: ImageRes.addBlack.toImage
                ..width = 24.w  // 从28.w缩小到24.w
                ..height = 24.h  // 从28.h缩小到24.h
                /*..onTap = onClickAddBtn*/,
            ),
          ],
        );

  TitleBar.chat({
    super.key,
    String? title,
    String? member,
    String? subTitle,
    bool showOnlineStatus = false,
    bool isOnline = false,
    bool isMultiModel = false,
    bool showCallBtn = true,
    Function()? onClickCallBtn,
    Function()? onClickMoreBtn,
    Function()? onCloseMultiModel,
  })  : backgroundColor = null,
        height = 48.h,
        showUnderline = true,
        center = Flexible(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (null != title)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      flex: 5,
                      child: Container(
                        child: title.trim().toText
                          ..style = Styles.ts_0C1C33_17sp_semibold
                          ..maxLines = 1
                          ..overflow = TextOverflow.ellipsis
                          ..textAlign = TextAlign.center,
                      )),
                  if (null != member)
                    Flexible(
                        flex: 2,
                        child: Container(
                            child: member.toText
                              ..style = Styles.ts_0C1C33_17sp_semibold
                              ..maxLines = 1))
                ],
              ),
            if (subTitle?.isNotEmpty == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showOnlineStatus)
                    Container(
                      width: 6.w,
                      height: 6.h,
                      margin: EdgeInsets.only(right: 4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Styles.c_18E875 : Styles.c_8E9AB0,
                      ),
                    ),
                  subTitle!.toText..style = Styles.ts_8E9AB0_10sp,
                ],
              ),
          ],
        )),
        left = SizedBox(
            width: 44.w, // 调整为44.w，与右边宽度保持平衡
            child: Align(
              alignment: Alignment.centerLeft,
              child: isMultiModel
                  ? (StrRes.cancel.toText
                    ..style = Styles.ts_0C1C33_17sp
                    ..onTap = onCloseMultiModel)
                  : (ImageRes.backBlack.toImage
                    ..width = 24.w
                    ..height = 24.h
                    ..onTap = (() => Get.back())),
            )),
        right = SizedBox(
            width: 44.w, // 固定为44.w，因为电话按钮已隐藏，只有更多按钮
            child: Align(
              alignment: Alignment.centerRight,
              child: ImageRes.moreBlack.toImage
                ..width = 28.w
                ..height = 28.h
                ..onTap = onClickMoreBtn,
            ));

  TitleBar.back({
    super.key,
    String? title,
    String? leftTitle,
    TextStyle? titleStyle,
    TextStyle? leftTitleStyle,
    String? result,
    Color? backgroundColor,
    Color? backIconColor,
    this.right,
    this.showUnderline = false,
    Function()? onTap,
  })  : height = 44.h,
        backgroundColor = backgroundColor ?? Styles.c_FFFFFF,
        center = Expanded(
            child: (title ?? '').toText
              ..style = (titleStyle ?? Styles.ts_0C1C33_17sp_semibold)
              ..textAlign = TextAlign.center),
        left = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap ?? (() => Get.back(result: result)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageRes.backBlack.toImage
                ..width = 24.w
                ..height = 24.h
                ..color = backIconColor,
              if (null != leftTitle) leftTitle.toText..style = (leftTitleStyle ?? Styles.ts_0C1C33_17sp_semibold),
            ],
          ),
        );

  TitleBar.contacts({
    super.key,
    this.showUnderline = false,
    Function()? onClickSearch,
    Function()? onClickAddContacts,
  })  : height = 44.h,
        backgroundColor = Styles.c_FFFFFF,
        center = Spacer(),
        left = StrRes.contacts.toText..style = Styles.ts_0C1C33_20sp_semibold,
        right = Row(
          children: [
            ImageRes.searchBlack.toImage
              ..width = 28.w
              ..height = 28.h
              ..onTap = onClickSearch,
            16.horizontalSpace,
            ImageRes.addContacts.toImage
              ..width = 28.w
              ..height = 28.h
              ..onTap = onClickAddContacts,
          ],
        );

  TitleBar.search({
    super.key,
    String? hintText,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool autofocus = true,
    Function(String)? onSubmitted,
    Function()? onCleared,
    ValueChanged<String>? onChanged,
  })  : height = 44.h,
        backgroundColor = Styles.c_FFFFFF,
        center = Expanded(
          child: Container(
              child: SearchBox(
            enabled: true,
            autofocus: autofocus,
            hintText: hintText,
            controller: controller,
            focusNode: focusNode,
            onSubmitted: onSubmitted,
            onCleared: onCleared,
            onChanged: onChanged,
          )),
        ),
        showUnderline = true,
        right = null,
        left = ImageRes.backBlack.toImage
          ..width = 24.w
          ..height = 24.h
          ..onTap = (() => Get.back());
}
