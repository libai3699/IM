import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../controllers/favorite_controller.dart';
import '../../../models/favorite_models.dart';

/// 收藏统计页面逻辑控制器
class FavoriteStatsLogic extends GetxController {
  /// 收藏控制器
  final favoriteController = Get.find<FavoriteController>();

  // ==================== 响应式状态 ====================

  /// 统计信息（代理到FavoriteController）
  Rx<FavoriteStats?> get stats => favoriteController.stats;

  /// 是否正在加载统计信息
  RxBool get isLoadingStats => favoriteController.isLoadingStats;

  // ==================== 生命周期 ====================

  @override
  void onReady() {
    super.onReady();
    // 页面准备完成后加载统计信息
    loadStats();
  }

  // ==================== 数据操作 ====================

  /// 加载统计信息
  Future<void> loadStats() async {
    await favoriteController.loadFavoriteStats();
  }

  /// 刷新统计信息
  Future<void> refreshStats() async {
    await loadStats();
  }

  // ==================== 计算属性 ====================

  /// 获取最活跃的收藏类型
  String get mostActiveType {
    final statsData = stats.value;
    if (statsData == null) return '无';
    return statsData.mostActiveType;
  }

  /// 获取平均每个分类的收藏数量
  double get averageFavoritesPerCategory {
    final statsData = stats.value;
    if (statsData == null) return 0.0;
    return statsData.averageFavoritesPerCategory;
  }

  /// 判断是否有收藏数据
  bool get hasData {
    final statsData = stats.value;
    return statsData != null && statsData.hasFavorites;
  }

  /// 获取收藏增长趋势描述
  String get growthTrendDescription {
    final statsData = stats.value;
    if (statsData == null) return '暂无数据';
    
    final today = statsData.todayAddedCount ?? 0;
    final week = statsData.weekAddedCount ?? 0;
    final month = statsData.monthAddedCount ?? 0;
    
    if (today > 0) {
      return '今日活跃，新增了 $today 个收藏';
    } else if (week > 0) {
      return '本周共新增 $week 个收藏';
    } else if (month > 0) {
      return '本月共新增 $month 个收藏';
    } else {
      return '最近没有新增收藏';
    }
  }

  /// 获取类型分布的百分比数据
  Map<String, double> get typePercentages {
    final statsData = stats.value;
    if (statsData == null) return {};
    
    final total = statsData.totalCount ?? 0;
    if (total == 0) return {};
    
    final typeStats = statsData.typeStatistics;
    final percentages = <String, double>{};
    
    for (final entry in typeStats.entries) {
      percentages[entry.key] = (entry.value / total) * 100;
    }
    
    return percentages;
  }

  /// 获取分类分布的百分比数据
  Map<String, double> get categoryPercentages {
    final statsData = stats.value;
    if (statsData == null) return {};
    
    final total = statsData.totalCount ?? 0;
    if (total == 0) return {};
    
    final categories = statsData.categoriesWithCount ?? [];
    final percentages = <String, double>{};
    
    for (final category in categories) {
      final count = category.favoriteCount ?? 0;
      percentages[category.displayName] = (count / total) * 100;
    }
    
    return percentages;
  }

  // ==================== 用户交互 ====================

  /// 导出统计数据
  void exportStats() {
    final statsData = stats.value;
    if (statsData == null) {
      IMViews.showToast('暂无统计数据');
      return;
    }

    // 这里可以实现数据导出功能
    // 例如生成CSV文件或JSON文件
    IMViews.showToast('导出功能开发中');
  }

  /// 分享统计信息
  void shareStats() {
    final statsData = stats.value;
    if (statsData == null) {
      IMViews.showToast('暂无统计数据');
      return;
    }

    final shareText = '''
我的收藏统计：
📚 总收藏：${statsData.totalCount ?? 0} 个
📁 分类数：${statsData.categoryCount ?? 0} 个
📈 ${statsData.growthTrendText}
🏆 最活跃类型：${statsData.mostActiveType}
⏰ 最近收藏：${statsData.lastFavoriteTimeText}
''';

    // 这里可以调用系统分享功能
    IMViews.showToast('分享功能开发中');
    // Logger.print('分享内容: $shareText');
  }

  /// 查看详细分析
  void viewDetailedAnalysis() {
    // 这里可以跳转到更详细的分析页面
    IMViews.showToast('详细分析功能开发中');
  }

  // ==================== 辅助方法 ====================

  /// 格式化数字显示
  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// 格式化百分比显示
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// 获取类型图标
  String getTypeIcon(String type) {
    switch (type) {
      case '消息':
        return '💬';
      case '图片':
        return '🖼️';
      case '视频':
        return '🎥';
      case '音频':
        return '🎵';
      case '文件':
        return '📄';
      case '链接':
        return '🔗';
      default:
        return '📋';
    }
  }

  /// 获取趋势描述
  String getTrendDescription(int current, int previous) {
    if (previous == 0) {
      return current > 0 ? '新增' : '无变化';
    }
    
    final change = current - previous;
    final percentage = (change / previous * 100).abs();
    
    if (change > 0) {
      return '增长 ${formatPercentage(percentage)}';
    } else if (change < 0) {
      return '下降 ${formatPercentage(percentage)}';
    } else {
      return '无变化';
    }
  }
}
