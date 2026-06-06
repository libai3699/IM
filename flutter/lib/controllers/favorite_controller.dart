import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../models/favorite_models.dart';
import '../services/favorite_api_service.dart';
import '../services/favorite_cache_service.dart';
import '../core/controller/im_controller.dart';

/// 收藏功能状态管理控制器
/// 
/// 使用GetX管理收藏相关的所有状态和业务逻辑
/// 包括收藏列表、分类管理、搜索、统计等功能
class FavoriteController extends GetxController {
  /// API服务实例
  final _apiService = FavoriteApiService.instance;

  /// 缓存服务实例
  final _cacheService = FavoriteCacheService.instance;

  /// IM控制器实例，用于获取用户信息
  final imLogic = Get.find<IMController>();

  // ==================== 响应式状态变量 ====================

  /// 收藏列表
  final favoriteList = <FavoriteInfo>[].obs;

  /// 分类列表
  final categoryList = <CategoryInfo>[].obs;

  /// 统计信息
  final stats = Rx<FavoriteStats?>(null);

  /// 当前选中的分类ID
  final selectedCategoryID = Rx<String?>(null);

  /// 当前收藏类型筛选
  final selectedFavoriteType = 0.obs;

  /// 搜索关键词
  final searchKeyword = ''.obs;

  /// 搜索结果列表
  final searchResultList = <FavoriteInfo>[].obs;

  /// 多选模式状态
  final isMultiSelectMode = false.obs;

  /// 多选中的收藏列表
  final selectedFavoriteList = <FavoriteInfo>[].obs;

  // ==================== 加载状态 ====================

  /// 收藏列表加载状态
  final isLoadingFavorites = false.obs;

  /// 分类列表加载状态
  final isLoadingCategories = false.obs;

  /// 统计信息加载状态
  final isLoadingStats = false.obs;

  /// 搜索加载状态
  final isSearching = false.obs;

  /// 是否有更多数据
  final hasMoreFavorites = true.obs;

  // ==================== 错误状态 ====================

  /// 错误信息
  final errorMessage = Rx<String?>(null);

  /// 是否显示错误状态
  final hasError = false.obs;

  // ==================== 控制器和分页 ====================

  /// 搜索输入控制器
  final searchController = TextEditingController();

  /// 搜索焦点节点
  final searchFocusNode = FocusNode();

  /// 当前页码
  int _currentPage = 1;

  /// 每页数量
  static const int _pageSize = 20;

  /// 搜索防抖定时器
  Timer? _searchDebounceTimer;

  // ==================== 生命周期方法 ====================

  @override
  void onInit() {
    super.onInit();
    
    // 初始化搜索监听
    _initSearchListener();
    
    // 监听分类变化，自动刷新收藏列表
    ever(selectedCategoryID, (_) => refreshFavoriteList());
    ever(selectedFavoriteType, (_) => refreshFavoriteList());
  }

  @override
  void onReady() {
    super.onReady();
    
    // 页面准备完成后加载初始数据
    _loadInitialData();
  }

  @override
  void onClose() {
    // 释放资源
    searchController.dispose();
    searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.onClose();
  }

  // ==================== 初始化方法 ====================

  /// 初始化搜索监听器
  void _initSearchListener() {
    searchController.addListener(() {
      final keyword = searchController.text.trim();
      searchKeyword.value = keyword;
      
      // 防抖搜索
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (keyword.isNotEmpty) {
          searchFavorites(keyword);
        } else {
          clearSearchResults();
        }
      });
    });
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadCategoryList(),
      loadFavoriteStats(),
      refreshFavoriteList(),
    ]);
  }

  // ==================== 收藏列表管理 ====================

  /// 刷新收藏列表
  Future<void> refreshFavoriteList([RefreshController? controller]) async {
    try {
      isLoadingFavorites.value = true;
      hasError.value = false;
      errorMessage.value = null;
      _currentPage = 1;

      final userID = _getCurrentUserID();
      final categoryID = selectedCategoryID.value;
      final favoriteType = selectedFavoriteType.value == 0 ? null : selectedFavoriteType.value;

      // 先尝试从缓存获取数据
      final cachedFavorites = await _cacheService.getCachedFavoriteList(
        userID: userID,
        categoryID: categoryID,
        favoriteType: favoriteType,
      );

      if (cachedFavorites != null) {
        // 使用缓存数据
        favoriteList.assignAll(cachedFavorites);
        hasMoreFavorites.value = cachedFavorites.length >= _pageSize;
        isLoadingFavorites.value = false;
        controller?.refreshCompleted();

        // Logger.print('使用缓存的收藏列表数据');

        // 后台刷新数据
        _refreshFavoriteListInBackground();
        return;
      }

      // 缓存无效，从网络获取数据
      await _loadFavoriteListFromNetwork();
      controller?.refreshCompleted();
    } catch (e) {
      _handleError(e, '加载收藏列表失败');
      controller?.refreshFailed();
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  /// 从网络加载收藏列表
  Future<void> _loadFavoriteListFromNetwork() async {
    final userID = _getCurrentUserID();
    final categoryID = selectedCategoryID.value;
    final favoriteType = selectedFavoriteType.value == 0 ? null : selectedFavoriteType.value;

    // Logger.print('从网络加载收藏列表，分类: $categoryID, 类型: $favoriteType');

    final request = GetFavoriteListRequest(
      userID: userID,
      favoriteType: favoriteType,
      categoryID: categoryID,
      pagination: PaginationRequest(
        pageNumber: _currentPage,
        showNumber: _pageSize,
      ),
    );

    final result = await _apiService.getFavoriteList(request);
    final favorites = result['favorites'] as List<FavoriteInfo>;
    final hasMore = result['hasMore'] as bool;

    favoriteList.assignAll(favorites);
    hasMoreFavorites.value = hasMore;

    // Logger.print('网络加载收藏列表成功，数量: ${favorites.length}，还有更多: $hasMore');

    // 缓存数据
    await _cacheService.cacheFavoriteList(
      favorites,
      userID: userID,
      categoryID: categoryID,
      favoriteType: favoriteType,
    );

    // 刷新完成，状态由页面逻辑控制
  }

  /// 后台刷新收藏列表
  Future<void> _refreshFavoriteListInBackground() async {
    try {
      await _loadFavoriteListFromNetwork();
    } catch (e) {
      // Logger.print('后台刷新收藏列表失败: $e');
      // 后台刷新失败不影响用户体验，只记录日志
    }
  }

  /// 加载更多收藏
  Future<void> loadMoreFavorites() async {
    if (!hasMoreFavorites.value || isLoadingFavorites.value) return;

    try {
      _currentPage++;
      // Logger.print('加载更多收藏，页码: $_currentPage');

      final userID = _getCurrentUserID();
      final categoryID = selectedCategoryID.value;
      final favoriteType = selectedFavoriteType.value == 0 ? null : selectedFavoriteType.value;

      final request = GetFavoriteListRequest(
        userID: userID,
        favoriteType: favoriteType,
        categoryID: categoryID,
        pagination: PaginationRequest(
          pageNumber: _currentPage,
          showNumber: _pageSize,
        ),
      );

      final result = await _apiService.getFavoriteList(request);
      final favorites = result['favorites'] as List<FavoriteInfo>;
      final hasMore = result['hasMore'] as bool;

      // 去重处理：避免重复添加相同的收藏
      final existingIds = favoriteList.map((f) => f.favoriteID).toSet();
      final newFavorites = favorites.where((f) => !existingIds.contains(f.favoriteID)).toList();

      favoriteList.addAll(newFavorites);
      hasMoreFavorites.value = hasMore;

      // Logger.print('加载更多收藏成功，新增: ${newFavorites.length}，总数: ${favoriteList.length}');
    } catch (e) {
      _currentPage--;
      // Logger.print('加载更多收藏失败: $e');
      _handleError(e, '加载更多收藏失败');
    }
  }

  /// 添加收藏
  Future<FavoriteInfo?> addFavorite({
    required int favoriteType,
    required String sourceID,
    String? conversationID,
    String? title,
    String? content,
    String? thumbnailURL,
    String? categoryID,
    List<String>? tags,
    String? notes,
  }) async {
    // 创建临时收藏对象用于乐观更新
    final tempFavorite = FavoriteInfo(
      favoriteID: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userID: _getCurrentUserID(),
      favoriteType: favoriteType,
      sourceID: sourceID,
      conversationID: conversationID,
      title: title,
      content: content,
      thumbnailURL: thumbnailURL,
      categoryID: categoryID,
      tags: tags,
      notes: notes,
      createTime: DateTime.now().millisecondsSinceEpoch,
      isOptimistic: true, // 标记为乐观更新
    );

    // 乐观更新：立即添加到列表顶部
    favoriteList.insert(0, tempFavorite);
    IMViews.showToast('正在收藏...');

    try {
      final request = AddFavoriteRequest(
        userID: _getCurrentUserID(),
        favoriteType: favoriteType,
        sourceID: sourceID,
        conversationID: conversationID,
        title: title,
        content: content,
        thumbnailURL: thumbnailURL,
        categoryID: categoryID,
        tags: tags,
        notes: notes,
      );

      final favoriteInfo = await _apiService.addFavorite(request);

      // 成功：替换临时对象为真实对象
      final tempIndex = favoriteList.indexWhere((item) => item.favoriteID == tempFavorite.favoriteID);
      if (tempIndex != -1) {
        favoriteList[tempIndex] = favoriteInfo;
      }

      // 清除相关缓存
      await _clearRelatedCache();

      // 更新统计信息
      loadFavoriteStats();

      IMViews.showToast('收藏成功');
      return favoriteInfo;
    } catch (e) {
      // 失败：回滚乐观更新
      favoriteList.removeWhere((item) => item.favoriteID == tempFavorite.favoriteID);
      _handleError(e, '收藏失败');
      return null;
    }
  }

  /// 删除收藏
  Future<bool> removeFavorite(String favoriteID) async {
    // 找到要删除的收藏项
    final favoriteToDelete = favoriteList.firstWhereOrNull((item) => item.favoriteID == favoriteID);
    final searchFavoriteToDelete = searchResultList.firstWhereOrNull((item) => item.favoriteID == favoriteID);

    if (favoriteToDelete == null) {
      IMViews.showToast('收藏项不存在');
      return false;
    }

    // 乐观更新：立即从列表中移除
    favoriteList.removeWhere((item) => item.favoriteID == favoriteID);
    searchResultList.removeWhere((item) => item.favoriteID == favoriteID);
    IMViews.showToast('正在删除...');

    try {
      final request = RemoveFavoriteRequest(
        userID: _getCurrentUserID(),
        favoriteIDs: [favoriteID],
      );

      await _apiService.removeFavorite(request);

      // 清除相关缓存
      await _clearRelatedCache();

      // 更新统计信息
      loadFavoriteStats();

      IMViews.showToast('删除成功');
      return true;
    } catch (e) {
      // 失败：回滚乐观更新
      if (favoriteToDelete != null) {
        // 找到合适的位置重新插入
        final insertIndex = _findInsertPosition(favoriteToDelete);
        favoriteList.insert(insertIndex, favoriteToDelete);
      }
      if (searchFavoriteToDelete != null) {
        searchResultList.add(searchFavoriteToDelete);
      }

      _handleError(e, '删除失败');
      return false;
    }
  }

  /// 找到收藏项的插入位置（按时间排序）
  int _findInsertPosition(FavoriteInfo favorite) {
    final createTime = favorite.createTime ?? 0;
    for (int i = 0; i < favoriteList.length; i++) {
      final itemCreateTime = favoriteList[i].createTime ?? 0;
      if (createTime > itemCreateTime) {
        return i;
      }
    }
    return favoriteList.length;
  }

  /// 更新收藏
  Future<FavoriteInfo?> updateFavorite({
    required String favoriteID,
    String? title,
    String? categoryID,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      final request = UpdateFavoriteRequest(
        userID: _getCurrentUserID(),
        favoriteID: favoriteID,
        title: title,
        categoryID: categoryID,
        tags: tags,
        notes: notes,
      );

      final updatedFavorite = await _apiService.updateFavorite(request);
      
      // 更新列表中的对应项
      final index = favoriteList.indexWhere((item) => item.favoriteID == favoriteID);
      if (index != -1) {
        favoriteList[index] = updatedFavorite;
      }
      
      // 更新搜索结果中的对应项
      final searchIndex = searchResultList.indexWhere((item) => item.favoriteID == favoriteID);
      if (searchIndex != -1) {
        searchResultList[searchIndex] = updatedFavorite;
      }
      
      IMViews.showToast('更新成功');
      return updatedFavorite;
    } catch (e) {
      _handleError(e, '更新失败');
      return null;
    }
  }

  // ==================== 工具方法 ====================

  /// 获取当前用户ID
  String _getCurrentUserID() {
    return imLogic.userInfo.value.userID ?? '';
  }

  /// 统一错误处理
  void _handleError(dynamic error, String defaultMessage) {
    final message = error.toString().contains('Exception:') 
        ? error.toString().replaceFirst('Exception: ', '')
        : defaultMessage;
    
    errorMessage.value = message;
    hasError.value = true;
    
    // Logger.print('FavoriteController错误: $error');
    // 注释掉弹窗提示，避免频繁的错误提示干扰用户体验
    // IMViews.showToast(message);
  }

  /// 清除错误状态
  void clearError() {
    hasError.value = false;
    errorMessage.value = null;
  }

  // ==================== 分类管理 ====================

  /// 加载分类列表
  Future<void> loadCategoryList() async {
    try {
      isLoadingCategories.value = true;

      final userID = _getCurrentUserID();

      // 先尝试从缓存获取数据
      final cachedCategories = await _cacheService.getCachedCategoryList(userID);

      if (cachedCategories != null) {
        // 使用缓存数据
        categoryList.assignAll(cachedCategories);
        isLoadingCategories.value = false;

        // Logger.print('使用缓存的分类列表数据');

        // 后台刷新数据
        _refreshCategoryListInBackground();
        return;
      }

      // 缓存无效，从网络获取数据
      await _loadCategoryListFromNetwork();
    } catch (e) {
      _handleError(e, '加载分类列表失败');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// 从网络加载分类列表
  Future<void> _loadCategoryListFromNetwork() async {
    final userID = _getCurrentUserID();
    final request = GetCategoryListRequest(userID: userID);
    final categories = await _apiService.getCategoryList(request);

    categoryList.assignAll(categories);

    // 缓存数据
    await _cacheService.cacheCategoryList(categories, userID);
  }

  /// 后台刷新分类列表
  Future<void> _refreshCategoryListInBackground() async {
    try {
      await _loadCategoryListFromNetwork();
    } catch (e) {
      // Logger.print('后台刷新分类列表失败: $e');
      // 后台刷新失败不影响用户体验，只记录日志
    }
  }

  /// 创建分类
  Future<CategoryInfo?> createCategory({
    required String categoryName,
    String? categoryColor,
    int? sortOrder,
  }) async {
    try {
      final request = CreateCategoryRequest(
        userID: _getCurrentUserID(),
        categoryName: categoryName,
        categoryColor: categoryColor ?? CategoryColor.getRandomColor(),
        sortOrder: sortOrder ?? categoryList.length,
      );

      final categoryInfo = await _apiService.createCategory(request);

      // 添加到分类列表
      categoryList.add(categoryInfo);

      // 清除分类相关缓存
      await _clearCategoryRelatedCache();

      IMViews.showToast('分类创建成功');
      return categoryInfo;
    } catch (e) {
      _handleError(e, '创建分类失败');
      return null;
    }
  }

  /// 更新分类
  Future<CategoryInfo?> updateCategory({
    required String categoryID,
    String? categoryName,
    String? categoryColor,
    int? sortOrder,
  }) async {
    try {
      final request = UpdateCategoryRequest(
        userID: _getCurrentUserID(),
        categoryID: categoryID,
        categoryName: categoryName,
        categoryColor: categoryColor,
        sortOrder: sortOrder,
      );

      final updatedCategory = await _apiService.updateCategory(request);

      // 更新分类列表中的对应项
      final index = categoryList.indexWhere((item) => item.categoryID == categoryID);
      if (index != -1) {
        categoryList[index] = updatedCategory;
      }

      IMViews.showToast('分类更新成功');
      return updatedCategory;
    } catch (e) {
      _handleError(e, '更新分类失败');
      return null;
    }
  }

  /// 删除分类
  Future<bool> deleteCategory(String categoryID, {bool moveToDefault = true}) async {
    try {
      final request = DeleteCategoryRequest(
        userID: _getCurrentUserID(),
        categoryID: categoryID,
        moveToDefault: moveToDefault,
      );

      await _apiService.deleteCategory(request);

      // 从分类列表中移除
      categoryList.removeWhere((item) => item.categoryID == categoryID);

      // 如果当前选中的分类被删除，清除选择
      if (selectedCategoryID.value == categoryID) {
        selectedCategoryID.value = null;
      }

      IMViews.showToast('分类删除成功');
      return true;
    } catch (e) {
      _handleError(e, '删除分类失败');
      return false;
    }
  }

  /// 设置分类筛选
  void setCategoryFilter(String? categoryID) {
    selectedCategoryID.value = categoryID;
  }

  /// 设置类型筛选
  void setTypeFilter(int favoriteType) {
    selectedFavoriteType.value = favoriteType;
    refreshFavoriteList();
  }

  /// 清除所有筛选条件
  void clearAllFilters() {
    selectedCategoryID.value = null;
    selectedFavoriteType.value = 0;
    refreshFavoriteList();
  }

  // ==================== 搜索功能 ====================

  /// 搜索收藏
  Future<void> searchFavorites(String keyword) async {
    if (keyword.trim().isEmpty) {
      clearSearchResults();
      return;
    }

    try {
      isSearching.value = true;

      final request = SearchFavoriteRequest(
        userID: _getCurrentUserID(),
        keyword: keyword.trim(),
        favoriteType: selectedFavoriteType.value == 0 ? null : selectedFavoriteType.value,
        categoryID: selectedCategoryID.value,
        pagination: PaginationRequest(pageNumber: 1, showNumber: 50),
      );

      final result = await _apiService.searchFavorites(request);
      final favorites = result['favorites'] as List<FavoriteInfo>;

      searchResultList.assignAll(favorites);
    } catch (e) {
      _handleError(e, '搜索失败');
    } finally {
      isSearching.value = false;
    }
  }

  /// 搜索收藏（公开方法）
  Future<Map<String, dynamic>> searchFavoritesWithRequest(SearchFavoriteRequest request) async {
    try {
      isSearching.value = true;

      final result = await _apiService.searchFavorites(request);
      return result;
    } catch (e) {
      _handleError(e, '搜索失败');
      return {'favorites': <FavoriteInfo>[], 'total': 0, 'hasMore': false};
    } finally {
      isSearching.value = false;
    }
  }

  /// 清除搜索结果
  void clearSearchResults() {
    searchResultList.clear();
    searchController.clear();
    searchKeyword.value = '';
    searchFocusNode.unfocus();
  }

  // ==================== 统计信息 ====================

  /// 加载收藏统计信息
  Future<void> loadFavoriteStats() async {
    try {
      isLoadingStats.value = true;

      final userID = _getCurrentUserID();

      // 先尝试从缓存获取数据
      final cachedStats = await _cacheService.getCachedStats(userID);

      if (cachedStats != null) {
        // 使用缓存数据
        stats.value = cachedStats;
        isLoadingStats.value = false;

        // Logger.print('使用缓存的统计信息数据');

        // 后台刷新数据
        _refreshStatsInBackground();
        return;
      }

      // 缓存无效，从网络获取数据
      await _loadStatsFromNetwork();
    } catch (e) {
      _handleError(e, '加载统计信息失败');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// 从网络加载统计信息
  Future<void> _loadStatsFromNetwork() async {
    final userID = _getCurrentUserID();
    final request = GetFavoriteStatsRequest(userID: userID);
    final statsInfo = await _apiService.getFavoriteStats(request);

    stats.value = statsInfo;

    // 缓存数据
    await _cacheService.cacheStats(statsInfo, userID);
  }

  /// 后台刷新统计信息
  Future<void> _refreshStatsInBackground() async {
    try {
      await _loadStatsFromNetwork();
    } catch (e) {
      // Logger.print('后台刷新统计信息失败: $e');
      // 后台刷新失败不影响用户体验，只记录日志
    }
  }

  // ==================== 多选功能 ====================

  /// 进入多选模式
  void enterMultiSelectMode() {
    isMultiSelectMode.value = true;
    selectedFavoriteList.clear();
  }

  /// 退出多选模式
  void exitMultiSelectMode() {
    isMultiSelectMode.value = false;
    selectedFavoriteList.clear();
  }

  /// 切换收藏选中状态
  void toggleFavoriteSelection(FavoriteInfo favorite) {
    if (selectedFavoriteList.contains(favorite)) {
      selectedFavoriteList.remove(favorite);
    } else {
      selectedFavoriteList.add(favorite);
    }
  }

  /// 全选/取消全选
  void toggleSelectAll() {
    if (selectedFavoriteList.length == favoriteList.length) {
      // 当前全选，执行取消全选
      selectedFavoriteList.clear();
    } else {
      // 执行全选
      selectedFavoriteList.assignAll(favoriteList);
    }
  }

  /// 批量删除选中的收藏
  Future<bool> batchDeleteSelected() async {
    if (selectedFavoriteList.isEmpty) {
      IMViews.showToast('请先选择要删除的收藏');
      return false;
    }

    try {
      final favoriteIDs = selectedFavoriteList.map((item) => item.favoriteID!).toList();

      final request = RemoveFavoriteRequest(
        userID: _getCurrentUserID(),
        favoriteIDs: favoriteIDs,
      );

      await _apiService.removeFavorite(request);

      // 从列表中移除已删除的项
      for (final favorite in selectedFavoriteList) {
        favoriteList.remove(favorite);
        searchResultList.remove(favorite);
      }

      // 退出多选模式
      exitMultiSelectMode();

      // 更新统计信息
      loadFavoriteStats();

      IMViews.showToast('批量删除成功');
      return true;
    } catch (e) {
      _handleError(e, '批量删除失败');
      return false;
    }
  }

  /// 批量移动到分类
  Future<bool> batchMoveToCategory(String categoryID) async {
    if (selectedFavoriteList.isEmpty) {
      IMViews.showToast('请先选择要移动的收藏');
      return false;
    }

    try {
      final favoriteIDs = selectedFavoriteList.map((item) => item.favoriteID!).toList();

      final request = BatchOperateFavoriteRequest(
        userID: _getCurrentUserID(),
        favoriteIDs: favoriteIDs,
        operation: BatchOperationType.moveCategory,
        targetCategoryID: categoryID,
      );

      await _apiService.batchOperateFavorites(request);

      // 更新本地数据
      for (final favorite in selectedFavoriteList) {
        favorite.categoryID = categoryID;
      }

      // 退出多选模式
      exitMultiSelectMode();

      IMViews.showToast('批量移动成功');
      return true;
    } catch (e) {
      _handleError(e, '批量移动失败');
      return false;
    }
  }

  // ==================== 便捷方法 ====================

  /// 检查收藏是否存在
  Future<bool> isFavoriteExists(String sourceID, int favoriteType) async {
    return await _apiService.isFavoriteExists(
      userID: _getCurrentUserID(),
      sourceID: sourceID,
      favoriteType: favoriteType,
    );
  }

  /// 获取收藏详情
  Future<FavoriteInfo?> getFavoriteInfo(String favoriteID) async {
    try {
      final request = GetFavoriteInfoRequest(
        userID: _getCurrentUserID(),
        favoriteID: favoriteID,
      );

      return await _apiService.getFavoriteInfo(request);
    } catch (e) {
      _handleError(e, '获取收藏详情失败');
      return null;
    }
  }

  /// 获取或创建默认分类
  Future<CategoryInfo> getOrCreateDefaultCategory() async {
    return await _apiService.getOrCreateDefaultCategory(_getCurrentUserID());
  }

  // ==================== 缓存管理 ====================

  /// 清除相关缓存
  Future<void> _clearRelatedCache() async {
    final userID = _getCurrentUserID();
    await _cacheService.clearFavoriteListCache(userID: userID);
    await _cacheService.clearStatsCache(userID: userID);
  }

  /// 清除分类相关缓存
  Future<void> _clearCategoryRelatedCache() async {
    final userID = _getCurrentUserID();
    await _cacheService.clearFavoriteListCache(userID: userID);
    await _cacheService.clearCategoryListCache(userID: userID);
    await _cacheService.clearStatsCache(userID: userID);
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }
}
