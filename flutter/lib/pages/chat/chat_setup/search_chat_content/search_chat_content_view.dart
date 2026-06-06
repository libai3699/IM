import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'search_chat_content_logic.dart';

class SearchChatContentPage extends StatelessWidget {
  final logic = Get.find<SearchChatContentLogic>();

  SearchChatContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Styles.c_FFFFFF,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Styles.c_0C1C33, size: 20.w),
            onPressed: () => Get.back(),
          ),
          title: "查找聊天内容".toText..style = Styles.ts_0C1C33_17sp,
          centerTitle: true,
          bottom: TabBar(
            labelColor: Styles.c_0089FF,
            unselectedLabelColor: Styles.c_8E9AB0,
            indicatorColor: Styles.c_0089FF,
            indicatorWeight: 2.h,
            labelStyle: Styles.ts_0089FF_16sp,
            unselectedLabelStyle: Styles.ts_8E9AB0_16sp,
            tabs: const [
              Tab(text: "聊天"),
              Tab(text: "图片/视频"),
              Tab(text: "文件"),
            ],
          ),
        ),
        backgroundColor: Styles.c_F8F9FA,
        body: TabBarView(
          children: [
            _buildChatTab(),
            _buildMediaTab(),
            _buildFileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // 搜索框
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Styles.c_8E9AB0, size: 20.w),
              12.horizontalSpace,
              Expanded(
                child: TextField(
                  controller: logic.searchController,
                  decoration: InputDecoration(
                    hintText: "搜索聊天记录",
                    hintStyle: Styles.ts_8E9AB0_14sp,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Styles.ts_0C1C33_14sp,
                  onChanged: logic.onSearchChanged,
                  onSubmitted: (_) => logic.searchMessages(),
                ),
              ),
              if (logic.searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: logic.clearSearch,
                  child: Icon(Icons.clear, color: Styles.c_8E9AB0, size: 20.w),
                ),
            ],
          ),
        ),
        // 搜索结果列表
        Expanded(
          child: Obx(() {
            if (logic.isSearching.value || logic.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (logic.searchResults.isEmpty) {
              return _buildEmptyView("暂无聊天记录");
            }
            return ListView.builder(
              itemCount: logic.searchResults.length,
              itemBuilder: (context, index) {
                final message = logic.searchResults[index];
                return _buildMessageItem(message);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMediaTab() {
    return Obx(() {
      if (logic.isLoadingMedia.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (logic.mediaList.isEmpty) {
        return _buildEmptyView("暂无图片或视频");
      }
      return GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.w,
        ),
        itemCount: logic.mediaList.length,
        itemBuilder: (context, index) {
          final message = logic.mediaList[index];
          return _buildMediaItem(message);
        },
      );
    });
  }

  Widget _buildFileTab() {
    return Obx(() {
      if (logic.isLoadingFiles.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (logic.fileList.isEmpty) {
        return _buildEmptyView("暂无文件");
      }
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: logic.fileList.length,
        itemBuilder: (context, index) {
          final message = logic.fileList[index];
          return _buildFileItem(message);
        },
      );
    });
  }

  Widget _buildEmptyView(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.w, color: Styles.c_8E9AB0),
          16.verticalSpace,
          text.toText..style = Styles.ts_8E9AB0_14sp,
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return GestureDetector(
      onTap: () => logic.jumpToMessage(message),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            // 头像
            AvatarView(
              url: message.senderFaceUrl,
              text: message.senderNickname,
              width: 40.w,
              height: 40.w,
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: (message.senderNickname ?? '').toText
                          ..style = Styles.ts_0C1C33_14sp
                          ..maxLines = 1
                          ..overflow = TextOverflow.ellipsis,
                      ),
                      IMUtils.getChatTimeline(message.sendTime!).toText
                        ..style = Styles.ts_8E9AB0_12sp,
                    ],
                  ),
                  4.verticalSpace,
                  IMUtils.parseMsg(message, replaceIdToNickname: true).toText
                    ..style = Styles.ts_8E9AB0_12sp
                    ..maxLines = 2
                    ..overflow = TextOverflow.ellipsis,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(Message message) {
    return GestureDetector(
      onTap: () => logic.previewMedia(message),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Styles.c_FFFFFF,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图片或视频缩略图
              if (message.contentType == MessageType.picture)
                ImageUtil.networkImage(
                  url: message.pictureElem?.snapshotPicture?.url ?? '',
                  fit: BoxFit.cover,
                )
              else if (message.contentType == MessageType.video)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageUtil.networkImage(
                      url: message.videoElem?.snapshotUrl ?? '',
                      fit: BoxFit.cover,
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 32.w,
                      ),
                    ),
                  ],
                ),
              // 时间标签
              Positioned(
                bottom: 4.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: IMUtils.formatDateMs(message.sendTime!, format: 'MM/dd').toText
                    ..style = TextStyle(color: Colors.white, fontSize: 10.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(Message message) {
    final fileElem = message.fileElem;
    return GestureDetector(
      onTap: () => logic.openFile(message),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            // 文件图标
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Styles.c_F0F2F6,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.insert_drive_file,
                color: Styles.c_8E9AB0,
                size: 24.w,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (fileElem?.fileName ?? '').toText
                    ..style = Styles.ts_0C1C33_14sp
                    ..maxLines = 1
                    ..overflow = TextOverflow.ellipsis,
                  4.verticalSpace,
                  Row(
                    children: [
                      IMUtils.formatBytes(fileElem?.fileSize ?? 0).toText
                        ..style = Styles.ts_8E9AB0_12sp,
                      8.horizontalSpace,
                      IMUtils.getChatTimeline(message.sendTime!).toText
                        ..style = Styles.ts_8E9AB0_12sp,
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.w,
              color: Styles.c_8E9AB0,
            ),
          ],
        ),
      ),
    );
  }
}
