import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../controllers/favorite_controller.dart';
import '../../../models/favorite_models.dart';

/// 收藏搜索页面逻辑控制器
class FavoriteSearchLogic extends GetxController {
  /// 收藏控制器
  final favoriteController = Get.find<FavoriteController>();

  /// 搜索输入控制器
  final searchController = TextEditingController();

  /// 搜索焦点节点
  final searchFocusNode = FocusNode();

  // ==================== 响应式状态 ====================

  /// 搜索关键词
  final searchKeyword = ''.obs;

  /// 搜索结果列表
  final searchResultList = <FavoriteInfo>[].obs;

  /// 是否正在搜索
  final isSearching = false.obs;

  /// 搜索历史
  final searchHistory = <String>[].obs;

  /// 选中的分类ID
  final selectedCategoryID = Rx<String?>(null);

  /// 选中的收藏类型
  final selectedFavoriteType = 0.obs;

  /// 选中的标签列表
  final selectedTags = <String>[].obs;

  /// 搜索防抖定时器
  Timer? _searchDebounceTimer;

  // ==================== 计算属性 ====================

  /// 分类列表（代理到FavoriteController）
  List<CategoryInfo> get categoryList => favoriteController.categoryList;

  /// 获取选中类型的显示名称
  String get selectedTypeName {
    switch (selectedFavoriteType.value) {
      case FavoriteType.message:
        return '消息';
      case FavoriteType.image:
        return '图片';
      case FavoriteType.video:
        return '视频';
      case FavoriteType.audio:
        return '语音';
      case FavoriteType.file:
        return '文件';
      case FavoriteType.link:
        return '链接';
      default:
        return '全部类型';
    }
  }

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();
    
    // 初始化搜索监听
    _initSearchListener();
    
    // 加载搜索历史
    _loadSearchHistory();
    
    // 确保分类列表已加载
    if (categoryList.isEmpty) {
      favoriteController.loadCategoryList();
    }
  }

  @override
  void onReady() {
    super.onReady();
    
    // 自动聚焦搜索框
    searchFocusNode.requestFocus();
  }

  @override
  void onClose() {
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
          _performSearch(keyword);
        } else {
          searchResultList.clear();
        }
      });
    });
  }

  /// 加载搜索历史
  void _loadSearchHistory() {
    // 从本地存储加载搜索历史
    final history = DataSp.getFavoriteSearchHistory();
    searchHistory.assignAll(history);
  }

  /// 保存搜索历史
  void _saveSearchHistory() {
    DataSp.saveFavoriteSearchHistory(searchHistory);
  }

  // ==================== 搜索功能 ====================

  /// 执行搜索
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchResultList.clear();
      return;
    }

    try {
      isSearching.value = true;
      
      final result = await favoriteController.searchFavoritesWithRequest(SearchFavoriteRequest(
        userID: favoriteController.imLogic.userInfo.value.userID ?? '',
        keyword: keyword.trim(),
        favoriteType: selectedFavoriteType.value == 0 ? null : selectedFavoriteType.value,
        categoryID: selectedCategoryID.value,
        tags: selectedTags.isEmpty ? null : selectedTags,
        pagination: PaginationRequest(pageNumber: 1, showNumber: 100),
      ));
      final favorites = result['favorites'] as List<FavoriteInfo>;
      
      searchResultList.assignAll(favorites);
      
      // 添加到搜索历史
      _addToSearchHistory(keyword);
    } catch (e) {
      // Logger.print('搜索失败: $e');
      IMViews.showToast('搜索失败，请稍后重试');
    } finally {
      isSearching.value = false;
    }
  }

  /// 搜索提交处理
  void onSearchSubmitted(String keyword) {
    if (keyword.trim().isNotEmpty) {
      _performSearch(keyword.trim());
    }
  }

  /// 使用关键词搜索
  void searchWithKeyword(String keyword) {
    searchController.text = keyword;
    searchKeyword.value = keyword;
    _performSearch(keyword);
  }

  /// 添加到搜索历史
  void _addToSearchHistory(String keyword) {
    if (keyword.trim().isEmpty) return;
    
    // 移除已存在的相同关键词
    searchHistory.remove(keyword);
    
    // 添加到开头
    searchHistory.insert(0, keyword);
    
    // 限制历史记录数量
    if (searchHistory.length > 20) {
      searchHistory.removeRange(20, searchHistory.length);
    }
    
    // 保存到本地
    _saveSearchHistory();
  }

  /// 移除搜索历史项
  void removeSearchHistory(String keyword) {
    searchHistory.remove(keyword);
    _saveSearchHistory();
  }

  /// 清空搜索历史
  void clearSearchHistory() {
    Get.dialog(
      AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有搜索历史吗？'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('取消', style: TextStyle(color: Styles.c_8E9AB0)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              searchHistory.clear();
              _saveSearchHistory();
            },
            child: Text('清空', style: TextStyle(color: Styles.c_FF381F)),
          ),
        ],
      ),
    );
  }

  // ==================== 筛选功能 ====================

  /// 显示筛选对话框
  void showFilterDialog() {
    Get.bottomSheet(
      _buildFilterSheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  /// 设置分类筛选
  void setCategoryFilter(String? categoryID) {
    selectedCategoryID.value = categoryID;
    _refreshSearchIfNeeded();
  }

  /// 设置类型筛选
  void setTypeFilter(int favoriteType) {
    selectedFavoriteType.value = favoriteType;
    _refreshSearchIfNeeded();
  }

  /// 添加标签筛选
  void addTag(String tag) {
    if (!selectedTags.contains(tag)) {
      selectedTags.add(tag);
      _refreshSearchIfNeeded();
    }
  }

  /// 移除标签筛选
  void removeTag(String tag) {
    selectedTags.remove(tag);
    _refreshSearchIfNeeded();
  }

  /// 清除分类筛选
  void clearCategoryFilter() {
    selectedCategoryID.value = null;
    _refreshSearchIfNeeded();
  }

  /// 清除类型筛选
  void clearTypeFilter() {
    selectedFavoriteType.value = 0;
    _refreshSearchIfNeeded();
  }

  /// 清除所有筛选条件
  void clearAllFilters() {
    selectedCategoryID.value = null;
    selectedFavoriteType.value = 0;
    selectedTags.clear();
    _refreshSearchIfNeeded();
  }

  /// 如果有搜索关键词则刷新搜索
  void _refreshSearchIfNeeded() {
    if (searchKeyword.value.isNotEmpty) {
      _performSearch(searchKeyword.value);
    }
  }

  // ==================== 私有方法 ====================

  /// 构建筛选底部弹窗
  Widget _buildFilterSheet() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Text(
                '筛选条件',
                style: Styles.ts_0C1C33_18sp_medium,
              ),
              const Spacer(),
              TextButton(
                onPressed: clearAllFilters,
                child: Text('清除全部', style: TextStyle(color: Styles.c_8E9AB0)),
              ),
              IconButton(
                onPressed: Get.back,
                icon: Icon(Icons.close, size: 20.w),
              ),
            ],
          ),
          16.verticalSpace,
          // 分类筛选
          Text('分类', style: Styles.ts_0C1C33_16sp_medium),
          8.verticalSpace,
          Obx(() => Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildFilterOption(
                label: '全部分类',
                isSelected: selectedCategoryID.value == null,
                onTap: () => setCategoryFilter(null),
              ),
              ...categoryList.map((category) => _buildFilterOption(
                label: category.displayName,
                isSelected: selectedCategoryID.value == category.categoryID,
                onTap: () => setCategoryFilter(category.categoryID),
              )),
            ],
          )),
          16.verticalSpace,
          // 类型筛选
          Text('类型', style: Styles.ts_0C1C33_16sp_medium),
          8.verticalSpace,
          Obx(() => Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildFilterOption(
                label: '全部类型',
                isSelected: selectedFavoriteType.value == 0,
                onTap: () => setTypeFilter(0),
              ),
              _buildFilterOption(
                label: '消息',
                isSelected: selectedFavoriteType.value == FavoriteType.message,
                onTap: () => setTypeFilter(FavoriteType.message),
              ),
              _buildFilterOption(
                label: '图片',
                isSelected: selectedFavoriteType.value == FavoriteType.image,
                onTap: () => setTypeFilter(FavoriteType.image),
              ),
              _buildFilterOption(
                label: '视频',
                isSelected: selectedFavoriteType.value == FavoriteType.video,
                onTap: () => setTypeFilter(FavoriteType.video),
              ),
              _buildFilterOption(
                label: '语音',
                isSelected: selectedFavoriteType.value == FavoriteType.audio,
                onTap: () => setTypeFilter(FavoriteType.audio),
              ),
              _buildFilterOption(
                label: '文件',
                isSelected: selectedFavoriteType.value == FavoriteType.file,
                onTap: () => setTypeFilter(FavoriteType.file),
              ),
              _buildFilterOption(
                label: '链接',
                isSelected: selectedFavoriteType.value == FavoriteType.link,
                onTap: () => setTypeFilter(FavoriteType.link),
              ),
            ],
          )),
          24.verticalSpace,
        ],
      ),
    );
  }

  /// 构建筛选选项
  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Styles.c_1B72EC : Styles.c_F8F9FA,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? Styles.c_1B72EC : Styles.c_E8EAEF,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? Styles.c_FFFFFF : Styles.c_0C1C33,
          ),
        ),
      ),
    );
  }
}
