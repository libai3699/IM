import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../models/favorite_models.dart';
import 'favorite_stats_logic.dart';

/// 收藏统计页面
class FavoriteStatsPage extends StatelessWidget {
  const FavoriteStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<FavoriteStatsLogic>();
    
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: TitleBar.back(
        title: '收藏统计',
        backgroundColor: Styles.c_FFFFFF,
      ),
      body: Obx(() {
        if (logic.isLoadingStats.value && logic.stats.value == null) {
          return _buildLoadingState();
        }

        final stats = logic.stats.value;
        if (stats == null) {
          return _buildEmptyState(logic);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总体统计卡片
              _buildOverallStatsCard(logic, stats),
              16.verticalSpace,
              // 类型分布卡片
              _buildTypeDistributionCard(logic, stats),
              16.verticalSpace,
              // 分类分布卡片
              _buildCategoryDistributionCard(logic, stats),
              16.verticalSpace,
              // 时间趋势卡片
              _buildTimeTrendCard(logic, stats),
            ],
          ),
        );
      }),
    );
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
            '正在加载统计信息...',
            style: Styles.ts_8E9AB0_14sp,
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(FavoriteStatsLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64.w,
            color: Styles.c_8E9AB0,
          ),
          16.verticalSpace,
          Text(
            '暂无统计数据',
            style: Styles.ts_8E9AB0_16sp,
          ),
          8.verticalSpace,
          Text(
            '开始收藏内容后查看统计信息',
            style: Styles.ts_8E9AB0_12sp,
          ),
          24.verticalSpace,
          ElevatedButton.icon(
            onPressed: logic.refreshStats,
            icon: Icon(Icons.refresh, size: 16.w),
            label: const Text('刷新'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.c_1B72EC,
              foregroundColor: Styles.c_FFFFFF,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建总体统计卡片
  Widget _buildOverallStatsCard(FavoriteStatsLogic logic, FavoriteStats stats) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Styles.c_1B72EC, Styles.c_1B72EC.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_1B72EC.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, color: Styles.c_FFFFFF, size: 24.w),
              12.horizontalSpace,
              Text(
                '总体统计',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_FFFFFF,
                ),
              ),
            ],
          ),
          20.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总收藏',
                  '${stats.totalCount ?? 0}',
                  Icons.favorite_outline,
                  Styles.c_FFFFFF,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '分类数',
                  '${stats.categoryCount ?? 0}',
                  Icons.category_outlined,
                  Styles.c_FFFFFF,
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Styles.c_FFFFFF.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Styles.c_FFFFFF, size: 16.w),
                8.horizontalSpace,
                Text(
                  stats.growthTrendText,
                  style: TextStyle(fontSize: 14.sp, color: Styles.c_FFFFFF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.w, color: color.withOpacity(0.8)),
            4.horizontalSpace,
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: color.withOpacity(0.8)),
            ),
          ],
        ),
        4.verticalSpace,
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建类型分布卡片
  Widget _buildTypeDistributionCard(FavoriteStatsLogic logic, FavoriteStats stats) {
    final typeStats = stats.typeStatistics;
    
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
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 20.w, color: Styles.c_0C1C33),
              8.horizontalSpace,
              Text(
                '类型分布',
                style: Styles.ts_0C1C33_16sp_medium,
              ),
            ],
          ),
          16.verticalSpace,
          ...typeStats.entries.map((entry) => _buildTypeStatItem(
            entry.key,
            entry.value,
            stats.totalCount ?? 0,
          )),
        ],
      ),
    );
  }

  /// 构建类型统计项
  Widget _buildTypeStatItem(String type, int count, int total) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    Color color;
    
    switch (type) {
      case '消息':
        color = Styles.c_1B72EC;
        break;
      case '图片':
        color = Styles.c_10CC47;
        break;
      case '视频':
        color = Styles.c_FF381F;
        break;
      case '音频':
        color = Styles.c_FF9500;
        break;
      case '文件':
        color = Styles.c_8E9AB0;
        break;
      default:
        color = Styles.c_1B72EC;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(type, style: Styles.ts_0C1C33_14sp),
          ),
          Text(
            '$count',
            style: Styles.ts_0C1C33_14sp_medium,
          ),
          8.horizontalSpace,
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Styles.ts_8E9AB0_12sp,
          ),
        ],
      ),
    );
  }

  /// 构建分类分布卡片
  Widget _buildCategoryDistributionCard(FavoriteStatsLogic logic, FavoriteStats stats) {
    final categories = stats.categoriesWithCount ?? [];
    
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
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 20.w, color: Styles.c_0C1C33),
              8.horizontalSpace,
              Text(
                '分类分布',
                style: Styles.ts_0C1C33_16sp_medium,
              ),
            ],
          ),
          16.verticalSpace,
          if (categories.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  '暂无分类数据',
                  style: Styles.ts_8E9AB0_14sp,
                ),
              ),
            )
          else
            ...categories.map((category) => _buildCategoryStatItem(category)),
        ],
      ),
    );
  }

  /// 构建分类统计项
  Widget _buildCategoryStatItem(CategoryWithCount category) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: Color(int.parse(category.displayColor.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(
              category.displayName,
              style: Styles.ts_0C1C33_14sp,
            ),
          ),
          Text(
            '${category.favoriteCount ?? 0}',
            style: Styles.ts_0C1C33_14sp_medium,
          ),
        ],
      ),
    );
  }

  /// 构建时间趋势卡片
  Widget _buildTimeTrendCard(FavoriteStatsLogic logic, FavoriteStats stats) {
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
          Row(
            children: [
              Icon(Icons.timeline_outlined, size: 20.w, color: Styles.c_0C1C33),
              8.horizontalSpace,
              Text(
                '时间趋势',
                style: Styles.ts_0C1C33_16sp_medium,
              ),
            ],
          ),
          16.verticalSpace,
          _buildTimeTrendItem('今日新增', stats.todayAddedCount ?? 0, Styles.c_10CC47),
          _buildTimeTrendItem('本周新增', stats.weekAddedCount ?? 0, Styles.c_1B72EC),
          _buildTimeTrendItem('本月新增', stats.monthAddedCount ?? 0, Styles.c_FF9500),
          16.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Styles.c_F8F9FA,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Styles.c_8E9AB0),
                8.horizontalSpace,
                Text(
                  '最近收藏：${stats.lastFavoriteTimeText}',
                  style: Styles.ts_8E9AB0_14sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间趋势项
  Widget _buildTimeTrendItem(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(label, style: Styles.ts_0C1C33_14sp),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
