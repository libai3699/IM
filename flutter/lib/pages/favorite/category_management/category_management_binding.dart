import 'package:get/get.dart';

import 'category_management_logic.dart';

/// 分类管理页面绑定类
class CategoryManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CategoryManagementLogic());
  }
}
