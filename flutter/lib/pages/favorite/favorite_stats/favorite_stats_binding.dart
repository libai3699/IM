import 'package:get/get.dart';

import 'favorite_stats_logic.dart';

/// 收藏统计页面绑定类
class FavoriteStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FavoriteStatsLogic());
  }
}
