import 'package:get/get.dart';

import 'favorite_list_logic.dart';

/// 收藏列表页面绑定类
class FavoriteListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FavoriteListLogic());
  }
}
