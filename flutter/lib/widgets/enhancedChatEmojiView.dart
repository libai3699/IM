import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

/// 增强版聊天表情视图 - 集成动态表情包功能
class EnhancedChatEmojiView extends StatefulWidget {
  const EnhancedChatEmojiView({
    Key? key,
    this.favoriteList = const [],
    this.onAddFavorite,
    this.onSelectedFavorite,
    required this.textEditingController,
    this.height,
    this.customEmojiLayout,
  }) : super(key: key);

  final List<String> favoriteList;
  final Function()? onAddFavorite;
  final Function(int index, String url)? onSelectedFavorite;
  final TextEditingController textEditingController;
  final double? height;
  final Widget? customEmojiLayout;

  @override
  State<EnhancedChatEmojiView> createState() => _EnhancedChatEmojiViewState();
}

class _EnhancedChatEmojiViewState extends State<EnhancedChatEmojiView> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 360.h, // 进一步增加高度以显示完整的三排表情包
      color: Styles.c_FFFFFF,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                // 默认emoji - 使用简化的emoji显示避免TabController冲突
                widget.customEmojiLayout ??
                    _buildSimpleEmojiLayout(),
                // 收藏表情
                _buildFavoriteLayout(),
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
            _buildTabSelectedBgView(
              selected: _index == 0,
              index: 0,
              icon: ImageRes.emojiTab,
              label: 'Emoji',
            ),
            _buildTabSelectedBgView(
              selected: _index == 1,
              index: 1,
              icon: ImageRes.favoriteTab,
              label: '收藏',
            ),

          ],
        ),
      );

  Widget _buildTabSelectedBgView({
    bool selected = false,
    int index = 0,
    required String icon,
    required String label,
  }) =>
      GestureDetector(
        onTap: () {
          setState(() {
            _index = index;
          });
          print('🎭 切换到标签页: $label (index: $index)');
        },
        child: Container(
          width: 62.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: selected ? Styles.c_E8EAEF : null,
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
        height: widget.height ?? 320.h, // 增加高度
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



  /// 构建简化的emoji布局，避免TabController冲突
  Widget _buildSimpleEmojiLayout() {
    return Container(
      color: Styles.c_FFFFFF,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        itemCount: _getCommonEmojis().length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 每行7个emoji，与原版保持一致
          childAspectRatio: 1,
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
        ),
        itemBuilder: (BuildContext context, int index) {
          final emoji = _getCommonEmojis()[index];
          return GestureDetector(
            onTap: () {
              // 添加emoji到输入框
              final controller = widget.textEditingController;
              controller.text += emoji;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                color: Colors.transparent,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 获取常用emoji列表
  List<String> _getCommonEmojis() {
    return [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣',
      '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰',
      '😍', '🤩', '😘', '😗', '😚', '😙', '😋',
      '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭',
      '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶',
      '😏', '😒', '🙄', '😬', '🤥', '😔', '😪',
      '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
      '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠',
      '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
      '☹️', '😮', '😯', '😲', '😳', '🥺', '😦',
      '😧', '😨', '😰', '😥', '😢', '😭', '😱',
      '😖', '😣', '😞', '😓', '😩', '😫', '🥱',
    ];
  }
}
