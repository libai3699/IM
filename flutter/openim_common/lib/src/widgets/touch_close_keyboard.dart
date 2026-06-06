import 'package:flutter/material.dart';
import 'package:openim_common/openim_common.dart';

/// 触摸关闭键盘
class TouchCloseSoftKeyboard extends StatelessWidget {
  final Widget child;
  final Function? onTouch;
  final bool isGradientBg;
  final bool isImageBg;
  final bool isLightBlueBg;

  const TouchCloseSoftKeyboard({
    Key? key,
    required this.child,
    this.onTouch,
    this.isGradientBg = false,
    this.isImageBg = false,
    this.isLightBlueBg = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 触摸收起键盘
        FocusScope.of(context).requestFocus(FocusNode());
        onTouch?.call();
      },
      child: isImageBg
          ? Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/icon_my_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: child,
            )
          : isLightBlueBg
              ? Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F9FF), // 浅蓝色背景 #f0f9ff
                  ),
                  child: child,
                )
              : isGradientBg
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Styles.c_FFFFFF,
                            Styles.c_FFF4EF,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: child,
                    )
                  : child,
    );
  }
}
