import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../models/favorite_models.dart';
import 'favorite_detail_logic.dart';

/// 收藏详情页面
class FavoriteDetailPage extends StatelessWidget {
  const FavoriteDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<FavoriteDetailLogic>();
    
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        title: Text('收藏详情', style: Styles.ts_0C1C33_18sp_medium),
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Styles.c_0C1C33),
        ),
        actions: [
          // 更多操作按钮
          PopupMenuButton<String>(
            onSelected: logic.onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('编辑', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('分享', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'jumpToSource',
                child: Row(
                  children: [
                    Icon(Icons.launch_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('跳转到原消息', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16.w, color: Styles.c_FF381F),
                    8.horizontalSpace,
                    Text('删除', style: TextStyle(fontSize: 14.sp, color: Styles.c_FF381F)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final favorite = logic.favoriteInfo.value;
        if (favorite == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主要内容区域
              _buildContentCard(logic, favorite),
              16.verticalSpace,
              // 详细信息区域
              _buildInfoCard(logic, favorite),
              16.verticalSpace,
              // 标签区域
              if (favorite.tags?.isNotEmpty == true) ...[
                _buildTagsCard(logic, favorite),
                16.verticalSpace,
              ],
              // 备注区域
              if (favorite.notes?.isNotEmpty == true) ...[
                _buildNotesCard(logic, favorite),
                16.verticalSpace,
              ],
            ],
          ),
        );
      }),
    );
  }

  /// 构建内容卡片
  Widget _buildContentCard(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和类型
          Row(
            children: [
              _buildTypeIcon(favorite.favoriteType),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  favorite.displayTitle,
                  style: Styles.ts_0C1C33_18sp_medium,
                ),
              ),
            ],
          ),
          16.verticalSpace,
          // 内容展示
          _buildContentDisplay(logic, favorite),
        ],
      ),
    );
  }

  /// 构建内容展示
  Widget _buildContentDisplay(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    switch (favorite.favoriteType) {
      case FavoriteType.message:
        return _buildTextContent(favorite);
      case FavoriteType.image:
        return _buildImageContent(logic, favorite);
      case FavoriteType.video:
        return _buildVideoContent(logic, favorite);
      case FavoriteType.audio:
        return _buildAudioContent(logic, favorite);
      case FavoriteType.file:
        return _buildFileContent(logic, favorite);
      case FavoriteType.link:
        return _buildLinkContent(logic, favorite);
      default:
        return _buildTextContent(favorite);
    }
  }

  /// 构建文本内容
  Widget _buildTextContent(FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Styles.c_F8F9FA,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        favorite.content ?? '',
        style: Styles.ts_0C1C33_16sp,
      ),
    );
  }

  /// 构建图片内容
  Widget _buildImageContent(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return GestureDetector(
      onTap: () => logic.previewImage(favorite),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          favorite.content ?? '',
          width: double.infinity,
          height: 200.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200.h,
              color: Styles.c_F8F9FA,
              child: Icon(Icons.broken_image, size: 48.w, color: Styles.c_8E9AB0),
            );
          },
        ),
      ),
    );
  }

  /// 构建视频内容
  Widget _buildVideoContent(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return GestureDetector(
      onTap: () => logic.playVideo(favorite),
      child: Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Styles.c_000000.withOpacity(0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (favorite.thumbnailURL?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  favorite.thumbnailURL ?? '',
                  width: double.infinity,
                  height: 200.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200.h,
                      color: Styles.c_F8F9FA,
                      child: Icon(Icons.broken_image, size: 48.w, color: Styles.c_8E9AB0),
                    );
                  },
                ),
              ),
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Styles.c_000000.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Styles.c_FFFFFF,
                size: 30.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建音频内容
  Widget _buildAudioContent(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_F8F9FA,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => logic.playAudio(favorite),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Styles.c_1B72EC,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Styles.c_FFFFFF,
                size: 20.w,
              ),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '语音消息',
                  style: Styles.ts_0C1C33_14sp_medium,
                ),
                4.verticalSpace,
                Text(
                  favorite.notes ?? '未知时长',
                  style: Styles.ts_8E9AB0_12sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件内容
  Widget _buildFileContent(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return GestureDetector(
      onTap: () => logic.openFile(favorite),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_F8F9FA,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 40.w,
              color: Styles.c_8E9AB0,
            ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.title ?? '未知文件',
                    style: Styles.ts_0C1C33_14sp_medium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.verticalSpace,
                  Text(
                    favorite.notes ?? '未知大小',
                    style: Styles.ts_8E9AB0_12sp,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_outlined,
              size: 20.w,
              color: Styles.c_1B72EC,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建链接内容
  Widget _buildLinkContent(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return GestureDetector(
      onTap: () => logic.openLink(favorite),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_F8F9FA,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Styles.c_1B72EC.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              size: 24.w,
              color: Styles.c_1B72EC,
            ),
            12.horizontalSpace,
            Expanded(
              child: Text(
                favorite.content ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Styles.c_1B72EC,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详细信息卡片
  Widget _buildInfoCard(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '详细信息',
            style: Styles.ts_0C1C33_16sp_medium,
          ),
          16.verticalSpace,
          _buildInfoRow('分类', favorite.categoryName ?? '默认分类'),
          _buildInfoRow('收藏时间', favorite.createTimeText),
          if (favorite.conversationID?.isNotEmpty == true)
            _buildInfoRow('来源会话', logic.getConversationName(favorite)),
          _buildInfoRow('收藏ID', favorite.favoriteID ?? ''),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: Styles.ts_8E9AB0_14sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Styles.ts_0C1C33_14sp,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签卡片
  Widget _buildTagsCard(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '标签',
            style: Styles.ts_0C1C33_16sp_medium,
          ),
          12.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: favorite.tags!.map((tag) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Styles.c_1B72EC.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Styles.c_1B72EC,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建备注卡片
  Widget _buildNotesCard(FavoriteDetailLogic logic, FavoriteInfo favorite) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备注',
            style: Styles.ts_0C1C33_16sp_medium,
          ),
          12.verticalSpace,
          Text(
            favorite.notes!,
            style: Styles.ts_0C1C33_14sp,
          ),
        ],
      ),
    );
  }

  /// 构建类型图标
  Widget _buildTypeIcon(int? favoriteType) {
    IconData iconData;
    Color iconColor;

    switch (favoriteType) {
      case FavoriteType.message:
        iconData = Icons.chat_bubble_outline;
        iconColor = Styles.c_1B72EC;
        break;
      case FavoriteType.image:
        iconData = Icons.image_outlined;
        iconColor = Styles.c_10CC47;
        break;
      case FavoriteType.video:
        iconData = Icons.videocam_outlined;
        iconColor = Styles.c_FF381F;
        break;
      case FavoriteType.audio:
        iconData = Icons.mic_outlined;
        iconColor = Styles.c_FF9500;
        break;
      case FavoriteType.file:
        iconData = Icons.insert_drive_file_outlined;
        iconColor = Styles.c_8E9AB0;
        break;
      case FavoriteType.link:
        iconData = Icons.link_outlined;
        iconColor = Styles.c_1B72EC;
        break;
      default:
        iconData = Icons.bookmark_outline;
        iconColor = Styles.c_8E9AB0;
    }

    return Icon(
      iconData,
      size: 24.w,
      color: iconColor,
    );
  }
}
