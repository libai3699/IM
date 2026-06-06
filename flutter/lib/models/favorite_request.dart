import 'dart:convert';

/// 添加收藏请求数据模型
class AddFavoriteRequest {
  /// 用户ID
  String userID;

  /// 收藏类型 1:消息 2:文件 3:图片 4:视频 5:音频 6:链接
  int favoriteType;

  /// 源内容ID
  String sourceID;

  /// 会话ID
  String? conversationID;

  /// 标题
  String? title;

  /// 内容
  String? content;

  /// 缩略图URL
  String? thumbnailURL;

  /// 分类ID
  String? categoryID;

  /// 标签数组
  List<String>? tags;

  /// 备注
  String? notes;

  /// 构造函数
  AddFavoriteRequest({
    required this.userID,
    required this.favoriteType,
    required this.sourceID,
    this.conversationID,
    this.title,
    this.content,
    this.thumbnailURL,
    this.categoryID,
    this.tags,
    this.notes,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteType'] = favoriteType;
    data['sourceID'] = sourceID;
    data['conversationID'] = conversationID;
    data['title'] = title;
    data['content'] = content;
    data['thumbnailURL'] = thumbnailURL;
    data['categoryID'] = categoryID;
    data['tags'] = tags;
    data['notes'] = notes;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 获取收藏列表请求数据模型
class GetFavoriteListRequest {
  /// 用户ID
  String userID;

  /// 收藏类型筛选 0:全部
  int? favoriteType;

  /// 分类ID筛选
  String? categoryID;

  /// 标签筛选
  List<String>? tags;

  /// 关键词筛选
  String? keyword;

  /// 分页信息
  PaginationRequest pagination;

  /// 构造函数
  GetFavoriteListRequest({
    required this.userID,
    this.favoriteType,
    this.categoryID,
    this.tags,
    this.keyword,
    required this.pagination,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteType'] = favoriteType;
    data['categoryID'] = categoryID;
    data['tags'] = tags;
    data['keyword'] = keyword;
    data['pagination'] = pagination.toJson();
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 搜索收藏请求数据模型
class SearchFavoriteRequest {
  /// 用户ID
  String userID;

  /// 搜索关键词
  String keyword;

  /// 收藏类型筛选
  int? favoriteType;

  /// 分类ID筛选
  String? categoryID;

  /// 标签筛选
  List<String>? tags;

  /// 分页信息
  PaginationRequest pagination;

  /// 构造函数
  SearchFavoriteRequest({
    required this.userID,
    required this.keyword,
    this.favoriteType,
    this.categoryID,
    this.tags,
    required this.pagination,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['keyword'] = keyword;
    data['favoriteType'] = favoriteType;
    data['categoryID'] = categoryID;
    data['tags'] = tags;
    data['pagination'] = pagination.toJson();
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 删除收藏请求数据模型
class RemoveFavoriteRequest {
  /// 用户ID
  String userID;

  /// 收藏ID列表
  List<String> favoriteIDs;

  /// 构造函数
  RemoveFavoriteRequest({
    required this.userID,
    required this.favoriteIDs,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteIDs'] = favoriteIDs;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 更新收藏请求数据模型
class UpdateFavoriteRequest {
  /// 用户ID
  String userID;

  /// 收藏ID
  String favoriteID;

  /// 标题
  String? title;

  /// 分类ID
  String? categoryID;

  /// 标签
  List<String>? tags;

  /// 备注
  String? notes;

  /// 构造函数
  UpdateFavoriteRequest({
    required this.userID,
    required this.favoriteID,
    this.title,
    this.categoryID,
    this.tags,
    this.notes,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteID'] = favoriteID;
    data['title'] = title;
    data['categoryID'] = categoryID;
    data['tags'] = tags;
    data['notes'] = notes;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 批量操作收藏请求数据模型
class BatchOperateFavoriteRequest {
  /// 用户ID
  String userID;

  /// 收藏ID列表
  List<String> favoriteIDs;

  /// 操作类型 1:移动分类 2:添加标签 3:移除标签 4:批量删除
  int operation;

  /// 目标分类ID（移动分类时使用）
  String? targetCategoryID;

  /// 目标标签（添加/移除标签时使用）
  List<String>? targetTags;

  /// 构造函数
  BatchOperateFavoriteRequest({
    required this.userID,
    required this.favoriteIDs,
    required this.operation,
    this.targetCategoryID,
    this.targetTags,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userID'] = userID;
    data['favoriteIDs'] = favoriteIDs;
    data['operation'] = operation;
    data['targetCategoryID'] = targetCategoryID;
    data['targetTags'] = targetTags;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 分页请求数据模型
class PaginationRequest {
  /// 页码（从1开始）
  int pageNumber;

  /// 每页显示数量
  int showNumber;

  /// 构造函数
  PaginationRequest({
    this.pageNumber = 1,
    this.showNumber = 20,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['pageNumber'] = pageNumber;
    data['showNumber'] = showNumber;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// 获取偏移量
  int get offset => (pageNumber - 1) * showNumber;

  /// 是否为第一页
  bool get isFirstPage => pageNumber <= 1;

  /// 获取下一页的分页请求
  PaginationRequest get nextPage {
    return PaginationRequest(
      pageNumber: pageNumber + 1,
      showNumber: showNumber,
    );
  }

  /// 重置到第一页
  PaginationRequest get firstPage {
    return PaginationRequest(
      pageNumber: 1,
      showNumber: showNumber,
    );
  }
}

/// 批量操作类型常量
class BatchOperationType {
  /// 移动分类
  static const int moveCategory = 1;

  /// 添加标签
  static const int addTags = 2;

  /// 移除标签
  static const int removeTags = 3;

  /// 批量删除
  static const int batchDelete = 4;

  /// 获取操作类型名称
  static String getOperationName(int operation) {
    switch (operation) {
      case moveCategory:
        return '移动分类';
      case addTags:
        return '添加标签';
      case removeTags:
        return '移除标签';
      case batchDelete:
        return '批量删除';
      default:
        return '未知操作';
    }
  }

  /// 判断是否为有效的操作类型
  static bool isValidOperation(int operation) {
    return [moveCategory, addTags, removeTags, batchDelete].contains(operation);
  }
}
