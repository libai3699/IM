import 'package:dio/dio.dart';
import 'package:openim_common/openim_common.dart';
import '../models/favorite_models.dart';

/// 收藏功能API服务类
/// 
/// 封装所有收藏相关的HTTP请求方法
/// 包括认证、错误处理、请求重试等功能
/// 遵循项目现有的API调用规范
class FavoriteApiService {
  /// 私有构造函数，实现单例模式
  FavoriteApiService._();

  /// 单例实例
  static final FavoriteApiService _instance = FavoriteApiService._();

  /// 获取单例实例
  static FavoriteApiService get instance => _instance;

  /// 获取带认证Token的请求选项
  /// 使用IM Token认证方式（收藏API在IM服务上）
  Options get _authOptions => Options(headers: {
    'token': DataSp.imToken,
    'Content-Type': 'application/json',
    'operationID': _generateOperationID(),
  });

  /// 生成唯一操作ID，用于日志追踪
  String _generateOperationID() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 收藏API基础URL - 使用IM API端口(10002)而不是认证端口(10008)
  String get _baseUrl => '${Config.imApiUrl}/favorite';

  /// 分类API基础URL
  String get _categoryBaseUrl => '${Config.imApiUrl}/favorite/category';

  // ==================== 收藏管理API ====================

  /// 添加收藏
  /// 
  /// [request] 添加收藏请求参数
  /// 返回添加成功的收藏信息
  Future<FavoriteInfo> addFavorite(AddFavoriteRequest request) async {
    try {
      // Logger.print('添加收藏请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/add',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('添加收藏响应: $data');
      
      if (data != null && data['favoriteInfo'] != null) {
        return FavoriteInfo.fromJson(data['favoriteInfo']);
      } else {
        throw Exception('添加收藏失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('添加收藏异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '添加收藏失败'));
    }
  }

  /// 获取收藏列表
  /// 
  /// [request] 获取收藏列表请求参数
  /// 返回收藏列表和分页信息
  Future<Map<String, dynamic>> getFavoriteList(GetFavoriteListRequest request) async {
    try {
      // Logger.print('获取收藏列表请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/list',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('获取收藏列表响应: $data');
      
      if (data != null) {
        final favorites = <FavoriteInfo>[];
        if (data['favorites'] is List) {
          favorites.addAll(
            (data['favorites'] as List).map((e) => FavoriteInfo.fromJson(e))
          );
        }
        
        return {
          'favorites': favorites,
          'total': data['total'] ?? 0,
          'hasMore': data['hasMore'] ?? false,
        };
      } else {
        throw Exception('获取收藏列表失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('获取收藏列表异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '获取收藏列表失败'));
    }
  }

  /// 搜索收藏
  /// 
  /// [request] 搜索收藏请求参数
  /// 返回搜索结果和分页信息
  Future<Map<String, dynamic>> searchFavorites(SearchFavoriteRequest request) async {
    try {
      // Logger.print('搜索收藏请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/search',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('搜索收藏响应: $data');
      
      if (data != null) {
        final favorites = <FavoriteInfo>[];
        if (data['favorites'] is List) {
          favorites.addAll(
            (data['favorites'] as List).map((e) => FavoriteInfo.fromJson(e))
          );
        }
        
        return {
          'favorites': favorites,
          'total': data['total'] ?? 0,
          'hasMore': data['hasMore'] ?? false,
        };
      } else {
        throw Exception('搜索收藏失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('搜索收藏异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '搜索收藏失败'));
    }
  }

  /// 删除收藏
  /// 
  /// [request] 删除收藏请求参数
  /// 返回删除是否成功
  Future<bool> removeFavorite(RemoveFavoriteRequest request) async {
    try {
      // Logger.print('删除收藏请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/remove',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('删除收藏响应: $data');
      return true;
    } catch (e, s) {
      // Logger.print('删除收藏异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '删除收藏失败'));
    }
  }

  /// 更新收藏信息
  /// 
  /// [request] 更新收藏请求参数
  /// 返回更新后的收藏信息
  Future<FavoriteInfo> updateFavorite(UpdateFavoriteRequest request) async {
    try {
      // Logger.print('更新收藏请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/update',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('更新收藏响应: $data');
      
      if (data != null && data['favoriteInfo'] != null) {
        return FavoriteInfo.fromJson(data['favoriteInfo']);
      } else {
        throw Exception('更新收藏失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('更新收藏异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '更新收藏失败'));
    }
  }

  /// 获取收藏详情
  /// 
  /// [request] 获取收藏详情请求参数
  /// 返回收藏详细信息
  Future<FavoriteInfo> getFavoriteInfo(GetFavoriteInfoRequest request) async {
    try {
      // Logger.print('获取收藏详情请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/info',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('获取收藏详情响应: $data');
      
      if (data != null && data['favoriteInfo'] != null) {
        return FavoriteInfo.fromJson(data['favoriteInfo']);
      } else {
        throw Exception('获取收藏详情失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('获取收藏详情异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '获取收藏详情失败'));
    }
  }

  /// 批量操作收藏
  /// 
  /// [request] 批量操作请求参数
  /// 返回操作是否成功
  Future<bool> batchOperateFavorites(BatchOperateFavoriteRequest request) async {
    try {
      // Logger.print('批量操作收藏请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/batch_operate',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('批量操作收藏响应: $data');
      return true;
    } catch (e, s) {
      // Logger.print('批量操作收藏异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '批量操作收藏失败'));
    }
  }

  // ==================== 分类管理API ====================

  /// 创建分类
  /// 
  /// [request] 创建分类请求参数
  /// 返回创建的分类信息
  Future<CategoryInfo> createCategory(CreateCategoryRequest request) async {
    try {
      // Logger.print('创建分类请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_categoryBaseUrl/create',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('创建分类响应: $data');
      
      if (data != null && data['categoryInfo'] != null) {
        return CategoryInfo.fromJson(data['categoryInfo']);
      } else {
        throw Exception('创建分类失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('创建分类异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '创建分类失败'));
    }
  }

  /// 获取分类列表
  /// 
  /// [request] 获取分类列表请求参数
  /// 返回分类列表
  Future<List<CategoryInfo>> getCategoryList(GetCategoryListRequest request) async {
    try {
      // Logger.print('获取分类列表请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_categoryBaseUrl/list',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('获取分类列表响应: $data');
      
      if (data != null && data['categories'] is List) {
        return (data['categories'] as List)
            .map((e) => CategoryInfo.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } catch (e, s) {
      // Logger.print('获取分类列表异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '获取分类列表失败'));
    }
  }

  /// 更新分类
  /// 
  /// [request] 更新分类请求参数
  /// 返回更新后的分类信息
  Future<CategoryInfo> updateCategory(UpdateCategoryRequest request) async {
    try {
      // Logger.print('更新分类请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_categoryBaseUrl/update',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('更新分类响应: $data');
      
      if (data != null && data['categoryInfo'] != null) {
        return CategoryInfo.fromJson(data['categoryInfo']);
      } else {
        throw Exception('更新分类失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('更新分类异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '更新分类失败'));
    }
  }

  /// 删除分类
  /// 
  /// [request] 删除分类请求参数
  /// 返回删除是否成功
  Future<bool> deleteCategory(DeleteCategoryRequest request) async {
    try {
      // Logger.print('删除分类请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_categoryBaseUrl/delete',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('删除分类响应: $data');
      return true;
    } catch (e, s) {
      // Logger.print('删除分类异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '删除分类失败'));
    }
  }

  // ==================== 统计API ====================

  /// 获取收藏统计信息
  /// 
  /// [request] 获取统计信息请求参数
  /// 返回统计信息
  Future<FavoriteStats> getFavoriteStats(GetFavoriteStatsRequest request) async {
    try {
      // Logger.print('获取收藏统计请求: ${request.toString()}');
      
      final data = await HttpUtil.post(
        '$_baseUrl/stats',
        data: request.toJson(),
        options: _authOptions,
      );
      
      // Logger.print('获取收藏统计响应: $data');
      
      if (data != null) {
        return FavoriteStats.fromJson(data);
      } else {
        throw Exception('获取收藏统计失败：响应数据格式错误');
      }
    } catch (e, s) {
      // Logger.print('获取收藏统计异常: $e\n堆栈: $s');
      return Future.error(_handleError(e, '获取收藏统计失败'));
    }
  }

  // ==================== 便捷方法 ====================

  /// 快速添加消息收藏
  ///
  /// [userID] 用户ID
  /// [messageID] 消息ID
  /// [conversationID] 会话ID
  /// [content] 消息内容
  /// [title] 收藏标题（可选）
  /// [categoryID] 分类ID（可选）
  /// [tags] 标签列表（可选）
  /// [notes] 备注（可选）
  Future<FavoriteInfo> addMessageFavorite({
    required String userID,
    required String messageID,
    required String conversationID,
    required String content,
    String? title,
    String? categoryID,
    List<String>? tags,
    String? notes,
  }) async {
    final request = AddFavoriteRequest(
      userID: userID,
      favoriteType: FavoriteType.message,
      sourceID: messageID,
      conversationID: conversationID,
      title: title ?? '消息收藏',
      content: content,
      categoryID: categoryID,
      tags: tags,
      notes: notes,
    );
    return addFavorite(request);
  }

  /// 快速添加文件收藏
  ///
  /// [userID] 用户ID
  /// [fileID] 文件ID
  /// [fileName] 文件名
  /// [fileUrl] 文件URL
  /// [thumbnailUrl] 缩略图URL（可选）
  /// [categoryID] 分类ID（可选）
  /// [tags] 标签列表（可选）
  /// [notes] 备注（可选）
  Future<FavoriteInfo> addFileFavorite({
    required String userID,
    required String fileID,
    required String fileName,
    required String fileUrl,
    String? thumbnailUrl,
    String? categoryID,
    List<String>? tags,
    String? notes,
  }) async {
    final request = AddFavoriteRequest(
      userID: userID,
      favoriteType: FavoriteType.file,
      sourceID: fileID,
      title: fileName,
      content: fileUrl,
      thumbnailURL: thumbnailUrl,
      categoryID: categoryID,
      tags: tags,
      notes: notes,
    );
    return addFavorite(request);
  }

  /// 快速删除单个收藏
  ///
  /// [userID] 用户ID
  /// [favoriteID] 收藏ID
  Future<bool> removeSingleFavorite({
    required String userID,
    required String favoriteID,
  }) async {
    final request = RemoveFavoriteRequest(
      userID: userID,
      favoriteIDs: [favoriteID],
    );
    return removeFavorite(request);
  }

  /// 检查收藏是否存在
  ///
  /// [userID] 用户ID
  /// [sourceID] 源内容ID
  /// [favoriteType] 收藏类型
  /// 返回是否已收藏
  Future<bool> isFavoriteExists({
    required String userID,
    required String sourceID,
    required int favoriteType,
  }) async {
    try {
      final request = GetFavoriteListRequest(
        userID: userID,
        favoriteType: favoriteType,
        pagination: PaginationRequest(pageNumber: 1, showNumber: 1),
      );

      final result = await getFavoriteList(request);
      final favorites = result['favorites'] as List<FavoriteInfo>;

      return favorites.any((favorite) => favorite.sourceID == sourceID);
    } catch (e) {
      // Logger.print('检查收藏是否存在异常: $e');
      return false;
    }
  }

  /// 获取用户的默认分类
  ///
  /// [userID] 用户ID
  /// 返回默认分类信息，如果不存在则创建
  Future<CategoryInfo> getOrCreateDefaultCategory(String userID) async {
    try {
      final request = GetCategoryListRequest(userID: userID);
      final categories = await getCategoryList(request);

      // 查找默认分类
      final defaultCategory = categories.firstWhere(
        (category) => category.isDefault,
        orElse: () => CategoryInfo.createDefault(userID: userID),
      );

      // 如果默认分类不存在，创建一个
      if (defaultCategory.categoryID == CategoryInfo.defaultCategoryID &&
          !categories.contains(defaultCategory)) {
        final createRequest = CreateCategoryRequest(
          userID: userID,
          categoryName: defaultCategory.categoryName!,
          categoryColor: defaultCategory.categoryColor,
          sortOrder: defaultCategory.sortOrder,
        );
        return await createCategory(createRequest);
      }

      return defaultCategory;
    } catch (e) {
      // Logger.print('获取或创建默认分类异常: $e');
      return CategoryInfo.createDefault(userID: userID);
    }
  }

  // ==================== 错误处理 ====================

  /// 统一错误处理
  ///
  /// [error] 原始错误对象
  /// [defaultMessage] 默认错误消息
  /// 返回格式化的错误信息
  Exception _handleError(dynamic error, String defaultMessage) {
    if (error is DioException) {
      // 处理网络请求错误
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('网络连接超时，请检查网络设置');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          // 处理后端返回的业务错误
          if (responseData is Map<String, dynamic>) {
            final errCode = responseData['errCode'];
            final errMsg = responseData['errMsg'];

            if (errCode == 14) {
              return Exception('收藏服务暂时不可用，请稍后重试');
            } else if (errCode == 1507) {
              return Exception('登录已过期，请重新登录');
            } else if (errMsg != null) {
              return Exception('$errMsg (错误码: $errCode)');
            }
          }

          if (statusCode == 401) {
            return Exception('登录已过期，请重新登录');
          } else if (statusCode == 403) {
            return Exception('权限不足，无法执行此操作');
          } else if (statusCode == 404) {
            return Exception('请求的资源不存在');
          } else if (statusCode == 500) {
            return Exception('服务器内部错误，请稍后重试');
          } else {
            return Exception('$defaultMessage (错误码: $statusCode)');
          }
        case DioExceptionType.cancel:
          return Exception('请求已取消');
        case DioExceptionType.unknown:
        default:
          return Exception('网络连接失败，请检查网络设置');
      }
    } else if (error is Exception) {
      return error;
    } else {
      return Exception('$defaultMessage: ${error.toString()}');
    }
  }
}
