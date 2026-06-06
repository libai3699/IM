import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sprintf/sprintf.dart';

/// 高德h5地图
class ChatWebViewMap extends StatefulWidget {
  const ChatWebViewMap({
    Key? key,
    required this.host,
    required this.webKey,
    required this.webServerKey,
    this.mapThumbnailSize = "1200*600",
    this.mapBackUrl = "http://callback",
    this.latitude,
    this.longitude,
  }) : super(key: key);

  final String host;
  final String webKey;
  final String webServerKey;
  final String mapThumbnailSize;
  final String mapBackUrl;
  final double? latitude;
  final double? longitude;

  @override
  State<ChatWebViewMap> createState() => _ChatWebViewMapState();
}

class _ChatWebViewMapState extends State<ChatWebViewMap> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        domStorageEnabled: true,
        geolocationEnabled: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;

  String url = "";
  double progress = 0;
  double? latitude;
  double? longitude;
  String? description;

  /// 定位获取
  late String locationUrl;
  late String thumbnailUrl;

  /// 根据定位坐标预览
  late String previewLocationUrl;

  _initUrl() {
    locationUrl = "${widget.host}?key=${widget.webKey}&serverKey=${widget.webServerKey}#/";
    previewLocationUrl = "${widget.host}?key=${widget.webKey}&serverKey=${widget.webServerKey}&location=${widget.longitude},${widget.latitude}#/";
  }

  String getStaticMapURL(double longitude, double latitude) {
    return 'https://restapi.amap.com/v3/staticmap?location=$longitude,$latitude&zoom=13&size=200*200&markers=mid,,A:$longitude,$latitude&key=${widget.webServerKey}';
  }

  bool get isPreview => widget.longitude != null && widget.latitude != null;

  @override
  void initState() {
    super.initState();

    // 初始化坐标（如果是预览模式）
    latitude = widget.latitude;
    longitude = widget.longitude;

    _initUrl();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _confirm() async {
    if (null == latitude || null == longitude) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: StrRes.plsSelectLocation.toText
            ..style = Styles.ts_0C1C33_17sp_semibold,
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: StrRes.determine.toText
                  ..style = Styles.ts_0089FF_17sp_semibold,
              ),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pop(context, {
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TitleBar.back(
        onTap: () async {
          if (await webViewController!.canGoBack()) {
            webViewController!.goBack();
          } else {
            Get.back();
          }
        },
        title: StrRes.location,
        right: isPreview
            ? null
            : GestureDetector(
                onTap: _confirm,
                behavior: HitTestBehavior.translucent,
                child: StrRes.determine.toText..style = Styles.ts_0C1C33_17sp,
              ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              // contextMenu: contextMenu,
              initialUrlRequest: URLRequest(
                  url: Uri.parse(isPreview ? previewLocationUrl : locationUrl)),
              // initialFile: "assets/index.html",
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialOptions: options,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {},
              androidOnGeolocationPermissionsShowPrompt:
                  (controller, origin) async {
                return GeolocationPermissionShowPromptResponse(
                    origin: origin, allow: true, retain: true);
              },
              androidOnPermissionRequest: (ctrl, origin, res) async {
                return PermissionRequestResponse(
                  resources: res,
                  action: PermissionRequestResponseAction.GRANT,
                );
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                var uriStr = uri.toString();
                // Logger.print('click: $uriStr');
                if (uriStr.startsWith(widget.mapBackUrl)) {
                  try {
                    // Logger.print('${uri.queryParameters}');
                    var result = <String, String>{};
                    result.addAll(uri.queryParameters);

                    // 高德地图回调格式适配
                    var lat = result['latitude'] ?? result['lat'];
                    var lng = result['longitude'] ?? result['lng'];
                    var name = result['name'] ?? '';
                    var addr = result['address'] ?? result['addr'] ?? '';

                    if (lat != null && lng != null) {
                      result['latitude'] = lat;
                      result['longitude'] = lng;
                      result['name'] = name;
                      result['addr'] = addr;
                      result['url'] = getStaticMapURL(double.parse(lng), double.parse(lat));
                      // Logger.print('${result['url']}');

                      latitude = double.tryParse(lat);
                      longitude = double.tryParse(lng);
                      description = jsonEncode(result);
                    }
                  } catch (e) {
                    // Logger.print('e:$e');
                  }
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                pullToRefreshController.endRefreshing();
                this.url = url.toString();
              },
              onLoadError: (controller, url, code, message) {
                pullToRefreshController.endRefreshing();
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController.endRefreshing();
                }
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                this.url = url.toString();
              },
              onConsoleMessage: (controller, consoleMessage) {
                // Logger.print('$consoleMessage');
              },
            ),
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : Container(),
          ],
        ),
      ),
    );
  }
}
