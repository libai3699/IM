import 'package:get/get.dart';

import 'favorite_detail_logic.dart';

/// 收藏详情页面绑定类
class FavoriteDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FavoriteDetailLogic());
  }
}
