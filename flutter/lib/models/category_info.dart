import 'dart:convert';

/// 收藏分类信息数据模型
/// 
/// 根据后端API文档定义的分类信息结构创建
/// 支持JSON序列化和反序列化
class CategoryInfo {
  /// 分类ID，唯一标识符
  String? categoryID;

  /// 用户ID
  String? userID;

  /// 分类名称
  String? categoryName;

  /// 分类颜色（十六进制颜色值，如 #FF5722）
  String? categoryColor;

  /// 排序顺序，数值越小越靠前
  int? sortOrder;

  /// 该分类下的收藏数量
  int? favoriteCount;

  /// 创建时间戳（毫秒）
  int? createTime;

  /// 更新时间戳（毫秒）
  int? updateTime;

  /// 扩展字段，用于存储额外信息
  String? ex;

  /// 扩展字段的Map形式，便于客户端使用
  Map<String, dynamic> exMap = {};

  // ==================== 扩展属性 ====================

  /// 创建时间文本
  String get createTimeText {
    if (createTime == null) return '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(createTime!);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 构造函数
  CategoryInfo({
    this.categoryID,
    this.userID,
    this.categoryName,
    this.categoryColor,
    this.sortOrder,
    this.favoriteCount,
    this.createTime,
    this.updateTime,
    this.ex,
    this.exMap = const <String, dynamic>{},
  });

  /// 从JSON创建CategoryInfo对象
  CategoryInfo.fromJson(Map<String, dynamic> json) {
    categoryID = json['categoryID'];
    userID = json['userID'];
    categoryName = json['categoryName'];
    categoryColor = json['categoryColor'];
    sortOrder = json['sortOrder'];
    favoriteCount = json['favoriteCount'] ?? 0;
    createTime = json['createTime'];
    updateTime = json['updateTime'];
    ex = json['ex'];
    
    // 处理扩展字段
    exMap = json['exMap'] ?? {};
    
    // 如果ex字段存在且是JSON字符串，尝试解析到exMap
    if (ex != null && ex!.isNotEmpty) {
      try {
        final decoded = jsonDecode(ex!);
        if (decoded is Map<String, dynamic>) {
          exMap.addAll(decoded);
        }
      } catch (e) {
        // 解析失败时忽略，保持原有exMap
      }
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['categoryID'] = categoryID;
    data['userID'] = userID;
    data['categoryName'] = categoryName;
    data['categoryColor'] = categoryColor;
    data['sortOrder'] = sortOrder;
    data['favoriteCount'] = favoriteCount;
    data['createTime'] = createTime;
    data['updateTime'] = updateTime;
    data['ex'] = ex;
    data['exMap'] = exMap;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// 获取显示名称（如果分类名称为空，返回默认名称）
  String get displayName => categoryName ?? '未命名分类';

  /// 获取显示颜色（如果颜色为空，返回默认颜色）
  String get displayColor => categoryColor ?? CategoryColor.defaultColor;

  /// 判断是否为默认分类
  bool get isDefault => categoryID == CategoryInfo.defaultCategoryID;

  /// 判断是否有收藏内容
  bool get hasFavorites => (favoriteCount ?? 0) > 0;

  /// 获取收藏数量显示文本
  String get favoriteCountText {
    final count = favoriteCount ?? 0;
    if (count == 0) return '暂无收藏';
    return '$count个收藏';
  }

  /// 更新分类信息
  void update(CategoryInfo other) {
    if (categoryID != other.categoryID) return;
    
    userID = other.userID ?? userID;
    categoryName = other.categoryName ?? categoryName;
    categoryColor = other.categoryColor ?? categoryColor;
    sortOrder = other.sortOrder ?? sortOrder;
    favoriteCount = other.favoriteCount ?? favoriteCount;
    createTime = other.createTime ?? createTime;
    updateTime = other.updateTime ?? updateTime;
    ex = other.ex ?? ex;
    exMap.addAll(other.exMap);
  }

  /// 复制分类信息
  CategoryInfo copyWith({
    String? categoryID,
    String? userID,
    String? categoryName,
    String? categoryColor,
    int? sortOrder,
    int? favoriteCount,
    int? createTime,
    int? updateTime,
    String? ex,
    Map<String, dynamic>? exMap,
  }) {
    return CategoryInfo(
      categoryID: categoryID ?? this.categoryID,
      userID: userID ?? this.userID,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      sortOrder: sortOrder ?? this.sortOrder,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      ex: ex ?? this.ex,
      exMap: exMap ?? this.exMap,
    );
  }

  /// 重写相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryInfo && other.categoryID == categoryID;
  }

  /// 重写hashCode
  @override
  int get hashCode => categoryID.hashCode;

  /// 默认分类ID
  static const String defaultCategoryID = 'default';

  /// 创建默认分类
  static CategoryInfo createDefault({String? userID}) {
    return CategoryInfo(
      categoryID: defaultCategoryID,
      userID: userID,
      categoryName: '默认分类',
      categoryColor: CategoryColor.defaultColor,
      sortOrder: 0,
      favoriteCount: 0,
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 分类颜色常量定义
class CategoryColor {
  /// 默认颜色
  static const String defaultColor = '#2196F3';

  /// 预定义颜色列表
  static const List<String> predefinedColors = [
    '#2196F3', // 蓝色
    '#4CAF50', // 绿色
    '#FF9800', // 橙色
    '#F44336', // 红色
    '#9C27B0', // 紫色
    '#607D8B', // 蓝灰色
    '#795548', // 棕色
    '#E91E63', // 粉红色
    '#009688', // 青色
    '#FFC107', // 琥珀色
    '#3F51B5', // 靛蓝色
    '#8BC34A', // 浅绿色
  ];

  /// 获取随机颜色
  static String getRandomColor() {
    final index = DateTime.now().millisecondsSinceEpoch % predefinedColors.length;
    return predefinedColors[index];
  }

  /// 验证颜色格式是否正确
  static bool isValidColor(String color) {
    if (color.isEmpty) return false;
    
    // 检查是否为十六进制颜色格式
    final regex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return regex.hasMatch(color);
  }

  /// 获取颜色名称（用于显示）
  static String getColorName(String color) {
    switch (color.toUpperCase()) {
      case '#2196F3':
        return '蓝色';
      case '#4CAF50':
        return '绿色';
      case '#FF9800':
        return '橙色';
      case '#F44336':
        return '红色';
      case '#9C27B0':
        return '紫色';
      case '#607D8B':
        return '蓝灰色';
      case '#795548':
        return '棕色';
      case '#E91E63':
        return '粉红色';
      case '#009688':
        return '青色';
      case '#FFC107':
        return '琥珀色';
      case '#3F51B5':
        return '靛蓝色';
      case '#8BC34A':
        return '浅绿色';
      default:
        return '自定义';
    }
  }
}

/// 分类排序方式
enum CategorySortType {
  /// 按创建时间排序
  createTime,
  
  /// 按更新时间排序
  updateTime,
  
  /// 按名称排序
  name,
  
  /// 按收藏数量排序
  favoriteCount,
  
  /// 按自定义顺序排序
  custom,
}

/// 分类排序扩展
extension CategorySortExtension on CategorySortType {
  /// 获取排序名称
  String get name {
    switch (this) {
      case CategorySortType.createTime:
        return '创建时间';
      case CategorySortType.updateTime:
        return '更新时间';
      case CategorySortType.name:
        return '名称';
      case CategorySortType.favoriteCount:
        return '收藏数量';
      case CategorySortType.custom:
        return '自定义';
    }
  }
}
