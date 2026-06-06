import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../../routes/app_navigator.dart';

class SearchChatContentLogic extends GetxController {
  final searchController = TextEditingController();
  final conversationInfo = Rxn<ConversationInfo>();
  
  final isSearching = false.obs;
  final isLoading = false.obs;
  final isLoadingMedia = false.obs;
  final isLoadingFiles = false.obs;
  
  final searchResults = <Message>[].obs;
  final mediaList = <Message>[].obs;
  final fileList = <Message>[].obs;
  
  String get conversationID => conversationInfo.value?.conversationID ?? '';
  int get sessionType => conversationInfo.value?.conversationType ?? 0;

  @override
  void onInit() {
    conversationInfo.value = Get.arguments['conversationInfo'];
    _loadAllData();
    super.onInit();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    if (value.isEmpty) {
      searchResults.clear();
    }
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
  }

  Future<void> searchMessages() async {
    final keyword = searchController.text.trim();
    if (keyword.isEmpty) return;

    try {
      isSearching.value = true;
      
      final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        keywordList: [keyword],
        keywordListMatchType: 0,
        senderUserIDList: [],
        messageTypeList: [MessageType.text],
        searchTimePosition: 0,
        searchTimePeriod: 0,
        pageIndex: 1,
        count: 100,
      );

      searchResults.assignAll(result.searchResultItems?.first.messageList ?? []);
    } catch (e) {
      IMViews.showToast('搜索失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> _loadAllData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadAllMessages(),
        _loadMediaMessages(),
        _loadFileMessages(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAllMessages() async {
    try {
      // 加载所有文本消息（不需要关键词搜索）
      final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        keywordList: [],
        keywordListMatchType: 0,
        senderUserIDList: [],
        messageTypeList: [MessageType.text, MessageType.atText],
        searchTimePosition: 0,
        searchTimePeriod: 0,
        pageIndex: 1,
        count: 100,
      );

      searchResults.assignAll(result.searchResultItems?.first.messageList ?? []);
    } catch (e) {
      IMViews.showToast('加载聊天记录失败: $e');
    }
  }

  Future<void> _loadMediaMessages() async {
    try {
      isLoadingMedia.value = true;
      
      // 加载图片消息
      final pictureResult = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        keywordList: [],
        keywordListMatchType: 0,
        senderUserIDList: [],
        messageTypeList: [MessageType.picture],
        searchTimePosition: 0,
        searchTimePeriod: 0,
        pageIndex: 1,
        count: 100,
      );

      // 加载视频消息
      final videoResult = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        keywordList: [],
        keywordListMatchType: 0,
        senderUserIDList: [],
        messageTypeList: [MessageType.video],
        searchTimePosition: 0,
        searchTimePeriod: 0,
        pageIndex: 1,
        count: 100,
      );

      final allMedia = <Message>[];
      allMedia.addAll(pictureResult.searchResultItems?.first.messageList ?? []);
      allMedia.addAll(videoResult.searchResultItems?.first.messageList ?? []);
      
      // 按时间排序
      allMedia.sort((a, b) => (b.sendTime ?? 0).compareTo(a.sendTime ?? 0));
      
      mediaList.assignAll(allMedia);
    } catch (e) {
      print('加载媒体文件失败: $e');
      // 不显示错误提示，避免影响用户体验
    } finally {
      isLoadingMedia.value = false;
    }
  }

  Future<void> _loadFileMessages() async {
    try {
      isLoadingFiles.value = true;
      
      final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        keywordList: [],
        keywordListMatchType: 0,
        senderUserIDList: [],
        messageTypeList: [MessageType.file],
        searchTimePosition: 0,
        searchTimePeriod: 0,
        pageIndex: 1,
        count: 100,
      );

      fileList.assignAll(result.searchResultItems?.first.messageList ?? []);
    } catch (e) {
      print('加载文件失败: $e');
      // 不显示错误提示，避免影响用户体验
    } finally {
      isLoadingFiles.value = false;
    }
  }

  void jumpToMessage(Message message) {
    Get.back();
    // 跳转到聊天页面并定位到该消息
    AppNavigator.startChat(
      conversationInfo: conversationInfo.value!,
      searchMessage: message,
    );
  }

  void previewMedia(Message message) {
    if (message.contentType == MessageType.picture) {
      // 预览图片
      final pictureElem = message.pictureElem;
      if (pictureElem != null) {
        AppNavigator.startPreviewImage(
          imageUrls: [pictureElem.sourcePicture?.url ?? ''],
          initialIndex: 0,
        );
      }
    } else if (message.contentType == MessageType.video) {
      // 播放视频
      final videoElem = message.videoElem;
      if (videoElem != null) {
        AppNavigator.startVideoPlayer(
          videoUrl: videoElem.videoUrl ?? '',
          title: '视频',
        );
      }
    }
  }

  void openFile(Message message) {
    // 使用IMUtils的previewFile方法打开文件
    IMUtils.previewFile(message);
  }
}
