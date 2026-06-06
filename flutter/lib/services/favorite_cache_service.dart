import 'dart:convert';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../models/favorite_models.dart';

/// 收藏数据缓存服务类
/// 
/// 提供收藏数据的本地缓存功能，减少网络请求
/// 包括收藏列表、分类列表、统计信息的缓存
class FavoriteCacheService {
  /// 私有构造函数，实现单例模式
  FavoriteCacheService._();

  /// 单例实例
  static final FavoriteCacheService _instance = FavoriteCacheService._();

  /// 获取单例实例
  static FavoriteCacheService get instance => _instance;

  // ==================== 缓存键常量 ====================

  /// 收藏列表缓存键
  static const String _favoriteListKey = 'favorite_list_cache';

  /// 分类列表缓存键
  static const String _categoryListKey = 'category_list_cache';

  /// 统计信息缓存键
  static const String _statsKey = 'favorite_stats_cache';

  /// 缓存时间戳键后缀
  static const String _timestampSuffix = '_timestamp';

  /// 缓存有效期（毫秒）- 5分钟
  static const int _cacheValidDuration = 5 * 60 * 1000;

  // ==================== 收藏列表缓存 ====================

  /// 缓存收藏列表
  /// 
  /// [favorites] 收藏列表
  /// [userID] 用户ID
  /// [categoryID] 分类ID筛选条件
  /// [favoriteType] 类型筛选条件
  Future<void> cacheFavoriteList(
    List<FavoriteInfo> favorites, {
    required String userID,
    String? categoryID,
    int? favoriteType,
  }) async {
    try {
      final cacheKey = _getFavoriteListCacheKey(userID, categoryID, favoriteType);
      final cacheData = {
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'userID': userID,
        'categoryID': categoryID,
        'favoriteType': favoriteType,
      };

      await SpUtil().putString(cacheKey, jsonEncode(cacheData));
      await SpUtil().putInt('${cacheKey}$_timestampSuffix', DateTime.now().millisecondsSinceEpoch);
      
      // Logger.print('收藏列表已缓存: $cacheKey');
    } catch (e) {
      // Logger.print('缓存收藏列表失败: $e');
    }
  }

  /// 获取缓存的收藏列表
  /// 
  /// [userID] 用户ID
  /// [categoryID] 分类ID筛选条件
  /// [favoriteType] 类型筛选条件
  /// 返回缓存的收藏列表，如果缓存无效则返回null
  Future<List<FavoriteInfo>?> getCachedFavoriteList({
    required String userID,
    String? categoryID,
    int? favoriteType,
  }) async {
    try {
      final cacheKey = _getFavoriteListCacheKey(userID, categoryID, favoriteType);
      
      // 检查缓存是否有效
      if (!await _isCacheValid(cacheKey)) {
        return null;
      }

      final cacheDataString = SpUtil().getString(cacheKey);
      if (cacheDataString == null || cacheDataString.isEmpty) {
        return null;
      }

      final cacheData = jsonDecode(cacheDataString) as Map<String, dynamic>;
      final favoritesJson = cacheData['favorites'] as List;
      
      final favorites = favoritesJson
          .map((json) => FavoriteInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      // Logger.print('从缓存获取收藏列表: $cacheKey, 数量: ${favorites.length}');
      return favorites;
    } catch (e) {
      // Logger.print('获取缓存收藏列表失败: $e');
      return null;
    }
  }

  /// 清除收藏列表缓存
  /// 
  /// [userID] 用户ID，如果为null则清除所有用户的缓存
  Future<void> clearFavoriteListCache({String? userID}) async {
    try {
      if (userID != null) {
        // 清除指定用户的缓存
        final keys = await _getFavoriteListCacheKeys(userID);
        for (final key in keys) {
          await SpUtil().remove(key);
          await SpUtil().remove('${key}$_timestampSuffix');
        }
      } else {
        // 清除所有收藏列表缓存
        final allKeys = SpUtil().getKeys() ?? <String>{};
        for (final key in allKeys) {
          if (key.startsWith(_favoriteListKey)) {
            await SpUtil().remove(key);
          }
        }
      }
      
      // Logger.print('收藏列表缓存已清除');
    } catch (e) {
      // Logger.print('清除收藏列表缓存失败: $e');
    }
  }

  // ==================== 分类列表缓存 ====================

  /// 缓存分类列表
  /// 
  /// [categories] 分类列表
  /// [userID] 用户ID
  Future<void> cacheCategoryList(List<CategoryInfo> categories, String userID) async {
    try {
      final cacheKey = _getCategoryListCacheKey(userID);
      final cacheData = {
        'categories': categories.map((c) => c.toJson()).toList(),
        'userID': userID,
      };

      await SpUtil().putString(cacheKey, jsonEncode(cacheData));
      await SpUtil().putInt('${cacheKey}$_timestampSuffix', DateTime.now().millisecondsSinceEpoch);
      
      // Logger.print('分类列表已缓存: $cacheKey');
    } catch (e) {
      // Logger.print('缓存分类列表失败: $e');
    }
  }

  /// 获取缓存的分类列表
  /// 
  /// [userID] 用户ID
  /// 返回缓存的分类列表，如果缓存无效则返回null
  Future<List<CategoryInfo>?> getCachedCategoryList(String userID) async {
    try {
      final cacheKey = _getCategoryListCacheKey(userID);
      
      // 检查缓存是否有效
      if (!await _isCacheValid(cacheKey)) {
        return null;
      }

      final cacheDataString = SpUtil().getString(cacheKey);
      if (cacheDataString == null || cacheDataString.isEmpty) {
        return null;
      }

      final cacheData = jsonDecode(cacheDataString) as Map<String, dynamic>;
      final categoriesJson = cacheData['categories'] as List;
      
      final categories = categoriesJson
          .map((json) => CategoryInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      // Logger.print('从缓存获取分类列表: $cacheKey, 数量: ${categories.length}');
      return categories;
    } catch (e) {
      // Logger.print('获取缓存分类列表失败: $e');
      return null;
    }
  }

  /// 清除分类列表缓存
  /// 
  /// [userID] 用户ID，如果为null则清除所有用户的缓存
  Future<void> clearCategoryListCache({String? userID}) async {
    try {
      if (userID != null) {
        final cacheKey = _getCategoryListCacheKey(userID);
        await SpUtil().remove(cacheKey);
        await SpUtil().remove('${cacheKey}$_timestampSuffix');
      } else {
        final allKeys = SpUtil().getKeys() ?? <String>{};
        for (final key in allKeys) {
          if (key.startsWith(_categoryListKey)) {
            await SpUtil().remove(key);
          }
        }
      }
      
      // Logger.print('分类列表缓存已清除');
    } catch (e) {
      // Logger.print('清除分类列表缓存失败: $e');
    }
  }

  // ==================== 统计信息缓存 ====================

  /// 缓存统计信息
  /// 
  /// [stats] 统计信息
  /// [userID] 用户ID
  Future<void> cacheStats(FavoriteStats stats, String userID) async {
    try {
      final cacheKey = _getStatsCacheKey(userID);
      final cacheData = {
        'stats': stats.toJson(),
        'userID': userID,
      };

      await SpUtil().putString(cacheKey, jsonEncode(cacheData));
      await SpUtil().putInt('${cacheKey}$_timestampSuffix', DateTime.now().millisecondsSinceEpoch);
      
      // Logger.print('统计信息已缓存: $cacheKey');
    } catch (e) {
      // Logger.print('缓存统计信息失败: $e');
    }
  }

  /// 获取缓存的统计信息
  /// 
  /// [userID] 用户ID
  /// 返回缓存的统计信息，如果缓存无效则返回null
  Future<FavoriteStats?> getCachedStats(String userID) async {
    try {
      final cacheKey = _getStatsCacheKey(userID);
      
      // 检查缓存是否有效
      if (!await _isCacheValid(cacheKey)) {
        return null;
      }

      final cacheDataString = SpUtil().getString(cacheKey);
      if (cacheDataString == null || cacheDataString.isEmpty) {
        return null;
      }

      final cacheData = jsonDecode(cacheDataString) as Map<String, dynamic>;
      final statsJson = cacheData['stats'] as Map<String, dynamic>;
      
      final stats = FavoriteStats.fromJson(statsJson);

      // Logger.print('从缓存获取统计信息: $cacheKey');
      return stats;
    } catch (e) {
      // Logger.print('获取缓存统计信息失败: $e');
      return null;
    }
  }

  /// 清除统计信息缓存
  /// 
  /// [userID] 用户ID，如果为null则清除所有用户的缓存
  Future<void> clearStatsCache({String? userID}) async {
    try {
      if (userID != null) {
        final cacheKey = _getStatsCacheKey(userID);
        await SpUtil().remove(cacheKey);
        await SpUtil().remove('${cacheKey}$_timestampSuffix');
      } else {
        final allKeys = SpUtil().getKeys() ?? <String>{};
        for (final key in allKeys) {
          if (key.startsWith(_statsKey)) {
            await SpUtil().remove(key);
          }
        }
      }
      
      // Logger.print('统计信息缓存已清除');
    } catch (e) {
      // Logger.print('清除统计信息缓存失败: $e');
    }
  }

  // ==================== 缓存管理 ====================

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      await clearFavoriteListCache();
      await clearCategoryListCache();
      await clearStatsCache();
      
      // Logger.print('所有收藏缓存已清除');
    } catch (e) {
      // Logger.print('清除所有缓存失败: $e');
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      final allKeys = SpUtil().getKeys() ?? <String>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final key in allKeys) {
        if (key.contains(_favoriteListKey) || 
            key.contains(_categoryListKey) || 
            key.contains(_statsKey)) {
          
          if (key.endsWith(_timestampSuffix)) continue;
          
          final timestampKey = '${key}$_timestampSuffix';
          final timestamp = SpUtil().getInt(timestampKey) ?? 0;
          
          if (now - timestamp > _cacheValidDuration) {
            await SpUtil().remove(key);
            await SpUtil().remove(timestampKey);
            // Logger.print('清除过期缓存: $key');
          }
        }
      }
    } catch (e) {
      // Logger.print('清除过期缓存失败: $e');
    }
  }

  // ==================== 私有方法 ====================

  /// 生成收藏列表缓存键
  String _getFavoriteListCacheKey(String userID, String? categoryID, int? favoriteType) {
    final parts = [_favoriteListKey, userID];
    if (categoryID != null) parts.add('cat_$categoryID');
    if (favoriteType != null) parts.add('type_$favoriteType');
    return parts.join('_');
  }

  /// 生成分类列表缓存键
  String _getCategoryListCacheKey(String userID) {
    return '${_categoryListKey}_$userID';
  }

  /// 生成统计信息缓存键
  String _getStatsCacheKey(String userID) {
    return '${_statsKey}_$userID';
  }

  /// 获取用户的所有收藏列表缓存键
  Future<List<String>> _getFavoriteListCacheKeys(String userID) async {
    final allKeys = SpUtil().getKeys() ?? <String>{};
    return allKeys.where((key) =>
        key.startsWith(_favoriteListKey) &&
        key.contains(userID) &&
        !key.endsWith(_timestampSuffix)
    ).toList();
  }

  /// 检查缓存是否有效
  Future<bool> _isCacheValid(String cacheKey) async {
    try {
      final timestampKey = '${cacheKey}$_timestampSuffix';
      final timestamp = SpUtil().getInt(timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return (now - timestamp) < _cacheValidDuration;
    } catch (e) {
      // Logger.print('检查缓存有效性失败: $e');
      return false;
    }
  }
}
