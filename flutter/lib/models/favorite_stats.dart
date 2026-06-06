import 'dart:convert';
import 'category_info.dart';

/// 收藏统计信息数据模型
/// 
/// 根据后端API文档定义的统计信息结构创建
/// 支持JSON序列化和反序列化
class FavoriteStats {
  /// 总收藏数量
  int? totalCount;

  /// 消息收藏数量
  int? messageCount;

  /// 文件收藏数量
  int? fileCount;

  /// 图片收藏数量
  int? imageCount;

  /// 视频收藏数量
  int? videoCount;

  /// 音频收藏数量
  int? audioCount;

  /// 链接收藏数量
  int? linkCount;

  /// 分类数量
  int? categoryCount;

  /// 分类详情列表（包含每个分类的收藏数量）
  List<CategoryWithCount>? categoriesWithCount;

  /// 今日新增收藏数量
  int? todayAddedCount;

  /// 本周新增收藏数量
  int? weekAddedCount;

  /// 本月新增收藏数量
  int? monthAddedCount;

  /// 最近收藏的时间戳
  int? lastFavoriteTime;

  /// 构造函数
  FavoriteStats({
    this.totalCount,
    this.messageCount,
    this.fileCount,
    this.imageCount,
    this.videoCount,
    this.audioCount,
    this.linkCount,
    this.categoryCount,
    this.categoriesWithCount,
    this.todayAddedCount,
    this.weekAddedCount,
    this.monthAddedCount,
    this.lastFavoriteTime,
  });

  /// 从JSON创建FavoriteStats对象
  FavoriteStats.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'] ?? 0;
    messageCount = json['messageCount'] ?? 0;
    fileCount = json['fileCount'] ?? 0;
    imageCount = json['imageCount'] ?? 0;
    videoCount = json['videoCount'] ?? 0;
    audioCount = json['audioCount'] ?? 0;
    linkCount = json['linkCount'] ?? 0;
    categoryCount = json['categoryCount'] ?? 0;
    todayAddedCount = json['todayAddedCount'] ?? 0;
    weekAddedCount = json['weekAddedCount'] ?? 0;
    monthAddedCount = json['monthAddedCount'] ?? 0;
    lastFavoriteTime = json['lastFavoriteTime'];

    // 处理分类详情列表
    if (json['categoriesWithCount'] is List) {
      categoriesWithCount = (json['categoriesWithCount'] as List)
          .map((e) => CategoryWithCount.fromJson(e))
          .toList();
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['totalCount'] = totalCount;
    data['messageCount'] = messageCount;
    data['fileCount'] = fileCount;
    data['imageCount'] = imageCount;
    data['videoCount'] = videoCount;
    data['audioCount'] = audioCount;
    data['linkCount'] = linkCount;
    data['categoryCount'] = categoryCount;
    data['todayAddedCount'] = todayAddedCount;
    data['weekAddedCount'] = weekAddedCount;
    data['monthAddedCount'] = monthAddedCount;
    data['lastFavoriteTime'] = lastFavoriteTime;
    data['categoriesWithCount'] = categoriesWithCount?.map((e) => e.toJson()).toList();
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// 获取按类型分组的统计数据
  Map<String, int> get typeStatistics {
    return {
      '消息': messageCount ?? 0,
      '文件': fileCount ?? 0,
      '图片': imageCount ?? 0,
      '视频': videoCount ?? 0,
      '音频': audioCount ?? 0,
      '链接': linkCount ?? 0,
    };
  }

  /// 获取最活跃的收藏类型
  String get mostActiveType {
    final stats = typeStatistics;
    if (stats.isEmpty) return '无';
    
    final maxEntry = stats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxEntry.key;
  }

  /// 获取收藏增长趋势文本
  String get growthTrendText {
    final today = todayAddedCount ?? 0;
    final week = weekAddedCount ?? 0;
    final month = monthAddedCount ?? 0;

    if (today > 0) {
      return '今日新增 $today 个收藏';
    } else if (week > 0) {
      return '本周新增 $week 个收藏';
    } else if (month > 0) {
      return '本月新增 $month 个收藏';
    } else {
      return '暂无新增收藏';
    }
  }

  /// 获取最后收藏时间的友好显示
  String get lastFavoriteTimeText {
    if (lastFavoriteTime == null) return '暂无收藏';
    
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastFavoriteTime!);
    final now = DateTime.now();
    final difference = now.difference(lastTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${lastTime.year}-${lastTime.month.toString().padLeft(2, '0')}-${lastTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 判断是否有收藏内容
  bool get hasFavorites => (totalCount ?? 0) > 0;

  /// 判断是否有分类
  bool get hasCategories => (categoryCount ?? 0) > 0;

  /// 获取平均每个分类的收藏数量
  double get averageFavoritesPerCategory {
    final total = totalCount ?? 0;
    final categories = categoryCount ?? 0;
    if (categories == 0) return 0.0;
    return total / categories;
  }
}

/// 分类统计信息
class CategoryWithCount {
  /// 分类ID
  String? categoryID;

  /// 分类名称
  String? categoryName;

  /// 分类颜色
  String? categoryColor;

  /// 该分类下的收藏数量
  int? favoriteCount;

  /// 构造函数
  CategoryWithCount({
    this.categoryID,
    this.categoryName,
    this.categoryColor,
    this.favoriteCount,
  });

  /// 从JSON创建CategoryWithCount对象
  CategoryWithCount.fromJson(Map<String, dynamic> json) {
    categoryID = json['categoryID'];
    categoryName = json['categoryName'];
    categoryColor = json['categoryColor'];
    favoriteCount = json['favoriteCount'] ?? 0;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['categoryID'] = categoryID;
    data['categoryName'] = categoryName;
    data['categoryColor'] = categoryColor;
    data['favoriteCount'] = favoriteCount;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// 获取显示名称
  String get displayName => categoryName ?? '未命名分类';

  /// 获取显示颜色
  String get displayColor => categoryColor ?? CategoryColor.defaultColor;

  /// 获取收藏数量文本
  String get favoriteCountText {
    final count = favoriteCount ?? 0;
    return '$count个收藏';
  }

  /// 判断是否有收藏内容
  bool get hasFavorites => (favoriteCount ?? 0) > 0;

  /// 重写相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryWithCount && other.categoryID == categoryID;
  }

  /// 重写hashCode
  @override
  int get hashCode => categoryID.hashCode;
}

/// 统计时间范围
enum StatsTimeRange {
  /// 今日
  today,
  
  /// 本周
  thisWeek,
  
  /// 本月
  thisMonth,
  
  /// 全部
  all,
}

/// 统计时间范围扩展
extension StatsTimeRangeExtension on StatsTimeRange {
  /// 获取时间范围名称
  String get name {
    switch (this) {
      case StatsTimeRange.today:
        return '今日';
      case StatsTimeRange.thisWeek:
        return '本周';
      case StatsTimeRange.thisMonth:
        return '本月';
      case StatsTimeRange.all:
        return '全部';
    }
  }

  /// 获取时间范围的开始时间戳
  int get startTimestamp {
    final now = DateTime.now();
    switch (this) {
      case StatsTimeRange.today:
        final today = DateTime(now.year, now.month, now.day);
        return today.millisecondsSinceEpoch;
      case StatsTimeRange.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final thisWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return thisWeek.millisecondsSinceEpoch;
      case StatsTimeRange.thisMonth:
        final thisMonth = DateTime(now.year, now.month, 1);
        return thisMonth.millisecondsSinceEpoch;
      case StatsTimeRange.all:
        return 0;
    }
  }
}
