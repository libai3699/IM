import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

// class ChatCustomEmojiView extends StatefulWidget {
//   const ChatCustomEmojiView({
//     Key? key,
//     this.index,
//     this.data,
//     this.heroTag,
//     required this.isISend,
//   }) : super(key: key);
//
//   /// 收藏的表情包以加载url的方式
//   /// {"url:"", "width":0, "height":0 }
//   final String? data;
//   final int? index;
//   final bool isISend;
//   final String? heroTag;
//
//   @override
//   State<ChatCustomEmojiView> createState() => _ChatCustomEmojiViewState();
// }
//
// class _ChatCustomEmojiViewState extends State<ChatCustomEmojiView> {
//   double trulyWidth = 1;
//   double trulyHeight = 1;
//   late String url;
//
//   @override
//   void initState() {
//     if (null != widget.data) {
//       var map = json.decode(widget.data!);
//       url = map['url'];
//       var w = map['width'] ?? 1.0;
//       var h = map['height'] ?? 1.0;
//       if (w is int) {
//         w = w.toDouble();
//       }
//       if (h is int) {
//         h = h.toDouble();
//       }
//
//       if (pictureWidth < w) {
//         trulyWidth = pictureWidth;
//         trulyHeight = trulyWidth * h / w;
//       } else {
//         trulyWidth = w;
//         trulyHeight = h;
//       }
//     }
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final child = ClipRRect(
//       // borderRadius: borderRadius(isISend),
//       child: ImageUtil.networkImage(
//         url: url,
//         width: trulyWidth,
//         height: trulyHeight,
//         fit: BoxFit.fitWidth,
//         clearMemoryCacheWhenDispose: false,
//       ),
//     );
//     return null != widget.heroTag
//         ? Hero(tag: widget.heroTag!, child: child)
//         : child;
//   }
// }

class ChatCustomEmojiView extends StatelessWidget {
  const ChatCustomEmojiView({
    Key? key,
    this.index,
    this.data,
    this.heroTag,
    required this.isISend,
  }) : super(key: key);

  /// 内置表情包，按位置显示
  final int? index;

  /// 收藏的表情包以加载url的方式
  /// {"url:"", "width":0, "height":0 }
  final String? data;
  final bool isISend;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    // 收藏的url表情或动态表情包
    try {
      if (data != null) {
        var map = json.decode(data!);

        // 检查是否为动态表情包
        bool isAnimatedSticker = map['isAnimated'] == true && map['type'] == 'animated_sticker';

        if (isAnimatedSticker) {
          // 处理动态表情包
          return _buildAnimatedStickerView(map);
        } else {
          // 处理普通URL表情
          return _buildUrlEmojiView(map);
        }
      }
    } catch (e, s) {
      // Logger.print('ChatCustomEmojiView error: $e  stackTrace: $s');
    }
    // 位置表情
    return Container();
  }

  /// 构建动态表情包视图
  Widget _buildAnimatedStickerView(Map<String, dynamic> map) {
    var assetPath = map['assetPath'];
    var w = map['width'] ?? 120.0;
    var h = map['height'] ?? 120.0;

    if (w is int) w = w.toDouble();
    if (h is int) h = h.toDouble();

    double trulyWidth;
    double trulyHeight;
    if (pictureWidth < w) {
      trulyWidth = pictureWidth;
      trulyHeight = trulyWidth * h / w;
    } else {
      trulyWidth = w;
      trulyHeight = h;
    }

    final child = ClipRRect(
      borderRadius: borderRadius(isISend),
      child: Image.asset(
        assetPath,
        width: trulyWidth,
        height: trulyHeight,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true, // 确保动态WebP正常播放
        errorBuilder: (context, error, stackTrace) {
          print('❌ 动态表情显示失败: $assetPath, error: $error');
          return Container(
            width: trulyWidth,
            height: trulyHeight,
            decoration: BoxDecoration(
              color: Styles.c_E8EAEF,
              borderRadius: borderRadius(isISend),
            ),
            child: Icon(
              Icons.error_outline,
              color: Styles.c_8E9AB0,
              size: 24.w,
            ),
          );
        },
      ),
    );

    return null != heroTag ? Hero(tag: heroTag!, child: child) : child;
  }

  /// 构建URL表情视图
  Widget _buildUrlEmojiView(Map<String, dynamic> map) {
    var url = map['url'];
    var w = map['width'] ?? 1.0;
    var h = map['height'] ?? 1.0;

    if (w is int) w = w.toDouble();
    if (h is int) h = h.toDouble();

    double trulyWidth;
    double trulyHeight;
    if (pictureWidth < w) {
      trulyWidth = pictureWidth;
      trulyHeight = trulyWidth * h / w;
    } else {
      trulyWidth = w;
      trulyHeight = h;
    }

    final child = ClipRRect(
      borderRadius: borderRadius(isISend),
      child: ImageUtil.networkImage(
        url: url,
        width: trulyWidth,
        height: trulyHeight,
        fit: BoxFit.fitWidth,
      ),
    );

    return null != heroTag ? Hero(tag: heroTag!, child: child) : child;
  }
}
