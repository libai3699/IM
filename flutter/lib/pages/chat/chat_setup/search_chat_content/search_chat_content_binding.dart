import 'package:get/get.dart';

import 'search_chat_content_logic.dart';

class SearchChatContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SearchChatContentLogic());
  }
}
