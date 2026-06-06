import 'dart:convert';

/// 创建分类请求数据模型
class CreateCategoryRequest {
  /// 用户ID
  String userID;

  /// 分类名称
  String categoryName;

  /// 分类颜色
  String? categoryColor;

  /// 排序顺序
  int? sortOrder;

  /// 构造函数
  CreateCategoryRequest({
    required this.userID,
    required this.categoryName,
    this.categoryColor,
    this.sortOrder,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['categoryName'] = categoryName;
    data['categoryColor'] = categoryColor;
    data['sortOrder'] = sortOrder;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 获取分类列表请求数据模型
class GetCategoryListRequest {
  /// 用户ID
  String userID;

  /// 构造函数
  GetCategoryListRequest({
    required this.userID,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 更新分类请求数据模型
class UpdateCategoryRequest {
  /// 用户ID
  String userID;

  /// 分类ID
  String categoryID;

  /// 分类名称
  String? categoryName;

  /// 分类颜色
  String? categoryColor;

  /// 排序顺序
  int? sortOrder;

  /// 构造函数
  UpdateCategoryRequest({
    required this.userID,
    required this.categoryID,
    this.categoryName,
    this.categoryColor,
    this.sortOrder,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['categoryID'] = categoryID;
    data['categoryName'] = categoryName;
    data['categoryColor'] = categoryColor;
    data['sortOrder'] = sortOrder;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 删除分类请求数据模型
class DeleteCategoryRequest {
  /// 用户ID
  String userID;

  /// 分类ID
  String categoryID;

  /// 是否将分类下的收藏移动到默认分类
  bool moveToDefault;

  /// 构造函数
  DeleteCategoryRequest({
    required this.userID,
    required this.categoryID,
    this.moveToDefault = true,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['categoryID'] = categoryID;
    data['moveToDefault'] = moveToDefault;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 获取收藏统计请求数据模型
class GetFavoriteStatsRequest {
  /// 用户ID
  String userID;

  /// 构造函数
  GetFavoriteStatsRequest({
    required this.userID,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 获取收藏详情请求数据模型
class GetFavoriteInfoRequest {
  /// 用户ID
  String userID;

  /// 收藏ID
  String favoriteID;

  /// 构造函数
  GetFavoriteInfoRequest({
    required this.userID,
    required this.favoriteID,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteID'] = favoriteID;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
