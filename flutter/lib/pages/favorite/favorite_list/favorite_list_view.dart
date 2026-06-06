import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../models/favorite_models.dart';
import 'favorite_list_logic.dart';

/// 收藏列表页面
class FavoriteListPage extends StatelessWidget {
  const FavoriteListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<FavoriteListLogic>();
    
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        title: Text('我的收藏', style: Styles.ts_0C1C33_18sp_medium),
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Styles.c_0C1C33),
        ),
        actions: [
          // 搜索按钮
          IconButton(
            onPressed: logic.openSearch,
            icon: Icon(Icons.search, color: Styles.c_0C1C33, size: 20.w),
          ),
          // 更多操作按钮
          PopupMenuButton<String>(
            onSelected: logic.onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'multiSelect',
                child: Row(
                  children: [
                    Icon(Icons.checklist, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('多选', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('分类管理', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('统计信息', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 16.w, color: Styles.c_0C1C33),
                    8.horizontalSpace,
                    Text('导出数据', style: Styles.ts_0C1C33_14sp),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 多选模式顶部操作栏
          Obx(() => logic.isMultiSelectMode.value
              ? _buildMultiSelectTopBar(logic)
              : const SizedBox.shrink()),
          // 筛选栏
          Obx(() => logic.isMultiSelectMode.value
              ? const SizedBox.shrink()
              : _buildFilterBar(logic)),
          // 收藏列表
          Expanded(
            child: _buildFavoriteList(logic),
          ),
          // 多选模式底部操作栏
          Obx(() => logic.isMultiSelectMode.value
              ? _buildMultiSelectBottomBar(logic)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar(FavoriteListLogic logic) {
    return Container(
      color: Styles.c_FFFFFF,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 分类筛选
          Expanded(
            child: Obx(() => _buildFilterChip(
              label: logic.selectedCategoryName,
              onTap: logic.showCategoryFilter,
              icon: Icons.category_outlined,
            )),
          ),
          12.horizontalSpace,
          // 类型筛选
          Expanded(
            child: Obx(() => _buildFilterChip(
              label: logic.selectedTypeName,
              onTap: logic.showTypeFilter,
              icon: Icons.filter_list_outlined,
            )),
          ),
        ],
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Styles.c_F8F9FA,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Styles.c_E8EAEF, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.w, color: Styles.c_8E9AB0),
            4.horizontalSpace,
            Flexible(
              child: Text(
                label,
                style: Styles.ts_8E9AB0_12sp,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            4.horizontalSpace,
            Icon(Icons.keyboard_arrow_down, size: 14.w, color: Styles.c_8E9AB0),
          ],
        ),
      ),
    );
  }

  /// 构建收藏列表
  Widget _buildFavoriteList(FavoriteListLogic logic) {
    return Obx(() {
      // 错误状态
      if (logic.hasError.value && logic.favoriteList.isEmpty) {
        return _buildErrorState(logic);
      }

      // 加载状态
      if (logic.isLoadingFavorites.value && logic.favoriteList.isEmpty) {
        return _buildLoadingState();
      }

      // 空状态
      if (logic.favoriteList.isEmpty) {
        return _buildEmptyState(logic);
      }

      // 正常列表状态
      return SmartRefresher(
        controller: logic.refreshController,
        enablePullDown: true,
        enablePullUp: logic.hasMoreFavorites.value,
        onRefresh: logic.refreshFavoriteList,
        onLoading: logic.loadMoreFavorites,
        header: const WaterDropHeader(),
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = Text("上拉加载更多", style: Styles.ts_8E9AB0_14sp);
            } else if (mode == LoadStatus.loading) {
              body = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  8.horizontalSpace,
                  Text("正在加载...", style: Styles.ts_8E9AB0_14sp),
                ],
              );
            } else if (mode == LoadStatus.failed) {
              body = Text("加载失败，点击重试", style: Styles.ts_FF381F_14sp);
            } else if (mode == LoadStatus.canLoading) {
              body = Text("松手加载更多", style: TextStyle(fontSize: 14.sp, color: Styles.c_1B72EC));
            } else {
              body = Text("没有更多数据了", style: Styles.ts_8E9AB0_14sp);
            }
            return Container(
              height: 55.h,
              child: Center(child: body),
            );
          },
        ),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: logic.favoriteList.length,
          separatorBuilder: (context, index) => 8.verticalSpace,
          itemBuilder: (context, index) {
            final favorite = logic.favoriteList[index];
            return _buildFavoriteItem(logic, favorite, index);
          },
        ),
      );
    });
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          16.verticalSpace,
          Text(
            '正在加载收藏列表...',
            style: Styles.ts_8E9AB0_14sp,
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(FavoriteListLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Styles.c_FF381F,
          ),
          16.verticalSpace,
          Text(
            '加载失败',
            style: Styles.ts_0C1C33_16sp_medium,
          ),
          8.verticalSpace,
          Text(
            logic.errorMessage.value ?? '网络连接异常，请检查网络设置',
            style: Styles.ts_8E9AB0_14sp,
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          ElevatedButton.icon(
            onPressed: logic.refreshFavoriteList,
            icon: Icon(Icons.refresh, size: 16.w),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.c_1B72EC,
              foregroundColor: Styles.c_FFFFFF,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(FavoriteListLogic logic) {
    // 根据筛选条件显示不同的空状态
    final hasFilter = logic.selectedCategoryID.value != null ||
                     logic.selectedFavoriteType.value != 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.bookmark_border,
            size: 64.w,
            color: Styles.c_8E9AB0,
          ),
          16.verticalSpace,
          Text(
            hasFilter ? '没有找到符合条件的收藏' : '暂无收藏内容',
            style: Styles.ts_8E9AB0_16sp,
          ),
          8.verticalSpace,
          Text(
            hasFilter ? '尝试调整筛选条件' : '长按聊天消息可以添加收藏',
            style: Styles.ts_8E9AB0_12sp,
          ),
          if (hasFilter) ...[
            24.verticalSpace,
            OutlinedButton.icon(
              onPressed: logic.clearAllFilters,
              icon: Icon(Icons.clear_all, size: 16.w),
              label: const Text('清除筛选'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Styles.c_1B72EC,
                side: BorderSide(color: Styles.c_1B72EC),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建收藏项
  Widget _buildFavoriteItem(FavoriteListLogic logic, FavoriteInfo favorite, int index) {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => logic.onTapFavorite(favorite),
          onLongPress: logic.isMultiSelectMode.value 
              ? null 
              : () => logic.onLongPressFavorite(favorite),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // 多选模式的复选框
                if (logic.isMultiSelectMode.value) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Checkbox(
                      value: logic.selectedFavoriteList.contains(favorite),
                      onChanged: (checked) => logic.toggleFavoriteSelection(favorite),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: Styles.c_1B72EC,
                    ),
                  ),
                  12.horizontalSpace,
                ],
                // 收藏内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和类型图标
                      Row(
                        children: [
                          _buildTypeIcon(favorite.favoriteType),
                          8.horizontalSpace,
                          Expanded(
                            child: Text(
                              favorite.displayTitle,
                              style: Styles.ts_0C1C33_16sp_medium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (favorite.content?.isNotEmpty == true) ...[
                        8.verticalSpace,
                        Text(
                          favorite.content!,
                          style: Styles.ts_8E9AB0_14sp,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      12.verticalSpace,
                      // 底部信息
                      Row(
                        children: [
                          // 分类标签
                          if (favorite.categoryName?.isNotEmpty == true)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Color(int.parse(favorite.categoryColor?.replaceFirst('#', '0xFF') ?? '0xFF2196F3')).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                favorite.categoryName!,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Color(int.parse(favorite.categoryColor?.replaceFirst('#', '0xFF') ?? '0xFF2196F3')),
                                ),
                              ),
                            ),
                          const Spacer(),
                          // 时间
                          Text(
                            favorite.createTimeText,
                            style: Styles.ts_8E9AB0_12sp,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
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
      size: 18.w,
      color: iconColor,
    );
  }

  /// 构建多选模式顶部操作栏
  Widget _buildMultiSelectTopBar(FavoriteListLogic logic) {
    return Container(
      color: Styles.c_FFFFFF,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 取消按钮
          GestureDetector(
            onTap: logic.exitMultiSelectMode,
            child: Text(
              '取消',
              style: Styles.ts_1B72EC_16sp,
            ),
          ),
          const Spacer(),
          // 选中数量显示
          Obx(() => Text(
            '已选择 ${logic.selectedFavoriteList.length} 项',
            style: Styles.ts_0C1C33_16sp_medium,
          )),
          const Spacer(),
          // 全选/取消全选
          Obx(() => GestureDetector(
            onTap: logic.toggleSelectAll,
            child: Text(
              logic.selectedFavoriteList.length == logic.favoriteList.length
                  ? '取消全选'
                  : '全选',
              style: Styles.ts_1B72EC_16sp,
            ),
          )),
        ],
      ),
    );
  }

  /// 构建多选模式底部操作栏
  Widget _buildMultiSelectBottomBar(FavoriteListLogic logic) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        border: Border(top: BorderSide(color: Styles.c_E8EAEF, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 移动到分类按钮
            Expanded(
              child: OutlinedButton.icon(
                onPressed: logic.selectedFavoriteList.isEmpty
                    ? null
                    : () => logic.showBatchMoveCategoryDialog(),
                icon: Icon(Icons.folder_outlined, size: 16.w),
                label: const Text('移动分类'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Styles.c_1B72EC,
                  side: BorderSide(color: Styles.c_1B72EC),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            12.horizontalSpace,
            // 批量删除按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: logic.selectedFavoriteList.isEmpty
                    ? null
                    : () => logic.showBatchDeleteDialog(),
                icon: Icon(Icons.delete_outline, size: 16.w),
                label: const Text('删除'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_FF381F,
                  foregroundColor: Styles.c_FFFFFF,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
