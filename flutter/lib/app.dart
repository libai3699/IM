import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'controllers/favorite_controller.dart';
import 'core/controller/im_controller.dart';
import 'core/controller/push_controller.dart';
import 'routes/app_pages.dart';
import 'widgets/app_view.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppView(
      builder: (locale, builder) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          enableLog: false,
          builder: (context, child) {
            // 完全禁用溢出错误的黄色斜杠显示
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return const SizedBox.shrink();
            };

            // 包装child以捕获所有溢出错误
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: Builder(
                builder: (context) {
                  return builder?.call(context, child) ?? child ?? const SizedBox.shrink();
                },
              ),
            );
          },
          logWriterCallback: Logger.print,
          translations: TranslationService(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // DefaultCupertinoLocalizations.delegate,
          ],
          fallbackLocale: TranslationService.fallbackLocale,
          locale: locale,
          localeResolutionCallback: (locale, list) {
            Get.locale ??= locale;
            return locale;
          },
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          getPages: AppPages.routes,
          initialBinding: InitBinding(),
          initialRoute: AppRoutes.splash,
          theme: ThemeData.light().copyWith(colorScheme: ColorScheme.fromSwatch())),
    );
  }
}

class InitBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IMController>(IMController());
    Get.put<PushController>(PushController());
    Get.put<CacheController>(CacheController());
    Get.put<DownloadController>(DownloadController());
    Get.put<FavoriteController>(FavoriteController());
  }
}
