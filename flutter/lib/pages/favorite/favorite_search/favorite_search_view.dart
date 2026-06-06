import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../models/favorite_models.dart';
import '../../../routes/app_navigator.dart';
import 'favorite_search_logic.dart';

/// 收藏搜索页面
class FavoriteSearchPage extends StatelessWidget {
  const FavoriteSearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<FavoriteSearchLogic>();
    
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Styles.c_0C1C33),
        ),
        title: Container(
          height: 36.h,
          decoration: BoxDecoration(
            color: Styles.c_F8F9FA,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: TextField(
            controller: logic.searchController,
            focusNode: logic.searchFocusNode,
            decoration: InputDecoration(
              hintText: '搜索收藏内容',
              hintStyle: Styles.ts_8E9AB0_14sp,
              prefixIcon: Icon(Icons.search, size: 20.w, color: Styles.c_8E9AB0),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
            ),
            style: Styles.ts_0C1C33_14sp,
            textInputAction: TextInputAction.search,
            onSubmitted: logic.onSearchSubmitted,
          ),
        ),
        actions: [
          // 筛选按钮
          IconButton(
            onPressed: logic.showFilterDialog,
            icon: Icon(Icons.tune, color: Styles.c_0C1C33),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索筛选条件显示
          Obx(() => _buildFilterChips(logic)),
          // 搜索结果或历史
          Expanded(
            child: Obx(() {
              if (logic.searchKeyword.value.isEmpty) {
                return _buildSearchHistory(logic);
              } else if (logic.isSearching.value) {
                return _buildSearchingState();
              } else if (logic.searchResultList.isEmpty) {
                return _buildNoResults(logic);
              } else {
                return _buildSearchResults(logic);
              }
            }),
          ),
        ],
      ),
    );
  }

  /// 构建筛选条件芯片
  Widget _buildFilterChips(FavoriteSearchLogic logic) {
    final chips = <Widget>[];
    
    // 分类筛选芯片
    if (logic.selectedCategoryID.value != null) {
      final category = logic.categoryList.firstWhereOrNull(
        (cat) => cat.categoryID == logic.selectedCategoryID.value,
      );
      if (category != null) {
        chips.add(_buildFilterChip(
          label: category.displayName,
          color: Color(int.parse(category.displayColor.replaceFirst('#', '0xFF'))),
          onRemove: () => logic.clearCategoryFilter(),
        ));
      }
    }
    
    // 类型筛选芯片
    if (logic.selectedFavoriteType.value != 0) {
      chips.add(_buildFilterChip(
        label: logic.selectedTypeName,
        color: Styles.c_1B72EC,
        onRemove: () => logic.clearTypeFilter(),
      ));
    }
    
    // 标签筛选芯片
    for (final tag in logic.selectedTags) {
      chips.add(_buildFilterChip(
        label: tag,
        color: Styles.c_10CC47,
        onRemove: () => logic.removeTag(tag),
      ));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      color: Styles.c_FFFFFF,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: chips,
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: color),
          ),
          4.horizontalSpace,
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14.w, color: color),
          ),
        ],
      ),
    );
  }

  /// 构建搜索历史
  Widget _buildSearchHistory(FavoriteSearchLogic logic) {
    return Obx(() {
      if (logic.searchHistory.isEmpty) {
        return _buildEmptyHistory(logic);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史标题
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  '搜索历史',
                  style: Styles.ts_0C1C33_16sp_medium,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: logic.clearSearchHistory,
                  child: Text(
                    '清空',
                    style: Styles.ts_8E9AB0_14sp,
                  ),
                ),
              ],
            ),
          ),
          // 搜索历史列表
          Expanded(
            child: ListView.builder(
              itemCount: logic.searchHistory.length,
              itemBuilder: (context, index) {
                final keyword = logic.searchHistory[index];
                return ListTile(
                  leading: Icon(Icons.history, size: 20.w, color: Styles.c_8E9AB0),
                  title: Text(keyword, style: Styles.ts_0C1C33_14sp),
                  trailing: GestureDetector(
                    onTap: () => logic.removeSearchHistory(keyword),
                    child: Icon(Icons.close, size: 16.w, color: Styles.c_8E9AB0),
                  ),
                  onTap: () => logic.searchWithKeyword(keyword),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  /// 构建搜索中状态
  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          16.verticalSpace,
          Text(
            '正在搜索...',
            style: Styles.ts_8E9AB0_14sp,
          ),
        ],
      ),
    );
  }

  /// 构建空历史状态
  Widget _buildEmptyHistory(FavoriteSearchLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_outlined,
            size: 64.w,
            color: Styles.c_8E9AB0,
          ),
          16.verticalSpace,
          Text(
            '搜索收藏内容',
            style: Styles.ts_8E9AB0_16sp,
          ),
          8.verticalSpace,
          Text(
            '输入关键词搜索您的收藏',
            style: Styles.ts_8E9AB0_12sp,
          ),
        ],
      ),
    );
  }

  /// 构建无结果状态
  Widget _buildNoResults(FavoriteSearchLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64.w,
            color: Styles.c_8E9AB0,
          ),
          16.verticalSpace,
          Text(
            '未找到相关收藏',
            style: Styles.ts_8E9AB0_16sp,
          ),
          8.verticalSpace,
          Text(
            '尝试使用其他关键词或调整筛选条件',
            style: Styles.ts_8E9AB0_12sp,
          ),
          24.verticalSpace,
          OutlinedButton(
            onPressed: logic.clearAllFilters,
            child: const Text('清除筛选条件'),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults(FavoriteSearchLogic logic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索结果统计
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            '找到 ${logic.searchResultList.length} 个结果',
            style: Styles.ts_8E9AB0_14sp,
          ),
        ),
        // 搜索结果列表
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: logic.searchResultList.length,
            separatorBuilder: (context, index) => 8.verticalSpace,
            itemBuilder: (context, index) {
              final favorite = logic.searchResultList[index];
              return _buildSearchResultItem(logic, favorite);
            },
          ),
        ),
      ],
    );
  }

  /// 构建搜索结果项
  Widget _buildSearchResultItem(FavoriteSearchLogic logic, FavoriteInfo favorite) {
    return Container(
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
          onTap: () => AppNavigator.startFavoriteDetail(favoriteInfo: favorite),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
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
                      Container(
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
        ),
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
      size: 18.w,
      color: iconColor,
    );
  }
}
