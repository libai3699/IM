import 'package:get/get.dart';

import 'favorite_search_logic.dart';

/// 收藏搜索页面绑定类
class FavoriteSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FavoriteSearchLogic());
  }
}
