import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';
import 'package:should_rebuild/should_rebuild.dart';
import 'package:get/get.dart';

class ChatEmojiView extends StatefulWidget {
  const ChatEmojiView({
    Key? key,
    this.favoriteList = const [],
    this.onAddFavorite,
    this.onSelectedFavorite,
    required this.textEditingController,
    this.height,
    this.customEmojiLayout,
    this.onAnimatedStickerSelected,
    this.enableAnimatedStickers = false,
  }) : super(key: key);
  final List<String> favoriteList;
  final Function()? onAddFavorite;
  final Function(int index, String url)? onSelectedFavorite;
  final TextEditingController textEditingController;
  final double? height;
  final Widget? customEmojiLayout;
  /// 动态表情选择回调
  final Function(String assetPath, int width, int height)? onAnimatedStickerSelected;
  /// 是否启用动态表情包
  final bool enableAnimatedStickers;

  @override
  State<ChatEmojiView> createState() => _ChatEmojiViewState();
}

class _ChatEmojiViewState extends State<ChatEmojiView> {
  var _index = 0;

  /// 标签页索引：0=默认emoji, 1=收藏表情, 2=动态表情包
  int get _tabCount => widget.enableAnimatedStickers ? 3 : 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Styles.c_FFFFFF,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                // 默认emoji
                widget.customEmojiLayout ??
                    ShouldRebuild<EmojiLayout>(
                      shouldRebuild: (oldWidget, newWidget) => false,
                      child: EmojiLayout(
                        controller: widget.textEditingController,
                      ),
                    ),
                // 收藏表情
                _buildFavoriteLayout(),
                // 动态表情包
                if (widget.enableAnimatedStickers) _buildAnimatedStickerLayout(),
              ],
            ),
          ),
          _buildTabView(),
        ],
      ),
    );
  }

  Widget _buildTabView() => Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          border: BorderDirectional(
            top: BorderSide(
              color: Styles.c_E8EAEF,
              width: 1.h,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildTabSelectedBgView(selected: _index == 0, index: 0, icon: ImageRes.emojiTab),
            _buildTabSelectedBgView(selected: _index == 1, index: 1, icon: ImageRes.favoriteTab),
            if (widget.enableAnimatedStickers)
              _buildTabSelectedBgView(selected: _index == 2, index: 2, icon: ImageRes.animatedStickerTab), // 使用专用的动态表情图标
          ],
        ),
      );

  Widget _buildTabSelectedBgView({
    bool selected = false,
    int index = 0,
    required String icon,
  }) =>
      GestureDetector(
        onTap: () {
          setState(() {
            _index = index;
          });
        },
        child: Container(
          width: 62.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: selected ? Styles.c_E8EAEF : null,
            // borderRadius: BorderRadius.circular(6.r),
          ),
          child: Center(
            child: index == 2
              ? Text(
                  '贴纸',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: selected ? Styles.c_0089FF : Styles.c_8E9AB0,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : (icon.toImage
                  ..width = 28.w
                  ..height = 28.h
                  ..color = (selected ? Styles.c_0089FF : Styles.c_8E9AB0)),
          ),
        ),
      );

  Widget _buildFavoriteLayout() => Container(
        color: Styles.c_FFFFFF,
        height: widget.height ?? 188.h,
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 22.h),
          itemCount: widget.favoriteList.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            mainAxisSpacing: 22.h,
            crossAxisSpacing: 22.w,
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return GestureDetector(
                onTap: widget.onAddFavorite,
                child: ImageRes.addFavorite.toImage
                  ..width = 66.w
                  ..height = 66.h,
              );
            }
            var url = widget.favoriteList.elementAt(index - 1);
            return GestureDetector(
              onTap: () => widget.onSelectedFavorite?.call(index - 1, url),
              child: ImageUtil.networkImage(
                url: url,
                width: 66.w,
                height: 66.h,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );

  /// 构建动态表情包布局
  Widget _buildAnimatedStickerLayout() {
    return Container(
      color: Styles.c_FFFFFF,
      height: widget.height ?? 188.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.animation,
              size: 48.w,
              color: Styles.c_0089FF,
            ),
            12.verticalSpace,
            Text(
              '🎭 动态表情包',
              style: Styles.ts_0089FF_17sp,
            ),
            8.verticalSpace,
            Text(
              '即将上线，敬请期待！',
              style: Styles.ts_8E9AB0_14sp,
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiLayout extends StatelessWidget {
  const EmojiLayout({
    Key? key,
    required this.controller,
    this.height,
  }) : super(key: key);
  final TextEditingController controller;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 移除固定高度，让父组件控制
      color: Styles.c_FFFFFF,
      child: emoji.EmojiPicker(
        onEmojiSelected: (category, emoji) {
          // Do something when emoji is tapped
          controller
            ..text += emoji.emoji
            ..selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        },
        onBackspacePressed: () {
          // Backspace-Button tapped logic
          // Remove this line to also remove the button in the UI
          controller
            ..text = controller.text.characters.skipLast(1).toString()
            ..selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        },
        config: emoji.Config(
          columns: 7,
          emojiSizeMax: 28 * (Platform.isIOS ? 1.30 : 1.0),
          // Issue: https://github.com/flutter/flutter/issues/28894
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: Styles.c_FFFFFF,
          indicatorColor: Styles.c_0089FF,
          iconColor: Styles.c_8E9AB0,
          iconColorSelected: Styles.c_0089FF,
          backspaceColor: Styles.c_0089FF,
          skinToneDialogBgColor: Styles.c_FFFFFF,
          skinToneIndicatorColor: Styles.c_8E9AB0,
          enableSkinTones: true,
          recentsLimit: 9,
          noRecents: '最近使用'.toText..style = Styles.ts_0C1C33_17sp,
          tabIndicatorAnimDuration: kTabScrollDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    );
  }
}
