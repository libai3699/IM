import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:openim_common/openim_common.dart';
import 'dart:ui' as ui;

import 'app.dart';

void main() {
  FlutterBugly.postCatchedException(
      () => Config.init(() => runApp(const ChatApp())));
}
