import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../controllers/favorite_controller.dart';
import '../../../models/favorite_models.dart';
import '../../../routes/app_navigator.dart';
import '../../../services/favorite_export_service.dart';

/// 收藏列表页面逻辑控制器
class FavoriteListLogic extends GetxController {
  /// 收藏控制器
  final favoriteController = Get.find<FavoriteController>();

  /// 下拉刷新控制器
  final refreshController = RefreshController();

  // ==================== 响应式状态 ====================

  /// 收藏列表（代理到FavoriteController）
  List<FavoriteInfo> get favoriteList => favoriteController.favoriteList;

  /// 分类列表（代理到FavoriteController）
  List<CategoryInfo> get categoryList => favoriteController.categoryList;

  /// 是否正在加载收藏
  RxBool get isLoadingFavorites => favoriteController.isLoadingFavorites;

  /// 是否有更多数据
  RxBool get hasMoreFavorites => favoriteController.hasMoreFavorites;

  /// 是否有错误
  RxBool get hasError => favoriteController.hasError;

  /// 错误消息
  Rx<String?> get errorMessage => favoriteController.errorMessage;

  /// 多选模式状态
  RxBool get isMultiSelectMode => favoriteController.isMultiSelectMode;

  /// 选中的收藏列表
  List<FavoriteInfo> get selectedFavoriteList => favoriteController.selectedFavoriteList;

  /// 当前选中的分类ID
  Rx<String?> get selectedCategoryID => favoriteController.selectedCategoryID;

  /// 当前选中的收藏类型
  RxInt get selectedFavoriteType => favoriteController.selectedFavoriteType;

  // ==================== 计算属性 ====================

  /// 获取选中分类的显示名称
  String get selectedCategoryName {
    if (selectedCategoryID.value == null) return '全部分类';
    
    final category = categoryList.firstWhereOrNull(
      (cat) => cat.categoryID == selectedCategoryID.value,
    );
    return category?.displayName ?? '全部分类';
  }

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
  void onReady() {
    super.onReady();
    // 页面准备完成后刷新数据
    refreshFavoriteList();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  // ==================== 数据操作 ====================

  /// 刷新收藏列表
  Future<void> refreshFavoriteList() async {
    try {
      await favoriteController.refreshFavoriteList(refreshController);
      refreshController.refreshCompleted();
    } catch (e) {
      refreshController.refreshFailed();
    }
  }

  /// 加载更多收藏
  Future<void> loadMoreFavorites() async {
    try {
      await favoriteController.loadMoreFavorites();
      if (favoriteController.hasMoreFavorites.value) {
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
    } catch (e) {
      refreshController.loadFailed();
    }
  }

  // ==================== 用户交互 ====================

  /// 点击收藏项
  void onTapFavorite(FavoriteInfo favorite) {
    if (isMultiSelectMode.value) {
      // 多选模式下切换选中状态
      toggleFavoriteSelection(favorite);
    } else {
      // 普通模式下打开收藏详情
      AppNavigator.startFavoriteDetail(favoriteInfo: favorite);
    }
  }

  /// 长按收藏项
  void onLongPressFavorite(FavoriteInfo favorite) {
    if (!isMultiSelectMode.value) {
      // 进入多选模式并选中当前项
      favoriteController.enterMultiSelectMode();
      favoriteController.toggleFavoriteSelection(favorite);
    }
  }

  /// 切换收藏选中状态
  void toggleFavoriteSelection(FavoriteInfo favorite) {
    favoriteController.toggleFavoriteSelection(favorite);
  }

  /// 退出多选模式
  void exitMultiSelectMode() {
    favoriteController.exitMultiSelectMode();
  }

  /// 全选/取消全选
  void toggleSelectAll() {
    favoriteController.toggleSelectAll();
  }

  /// 显示批量移动分类对话框
  void showBatchMoveCategoryDialog() {
    if (selectedFavoriteList.isEmpty) {
      IMViews.showToast('请先选择要移动的收藏');
      return;
    }

    Get.bottomSheet(
      _buildBatchMoveCategorySheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  /// 显示批量删除确认对话框
  void showBatchDeleteDialog() {
    if (selectedFavoriteList.isEmpty) {
      IMViews.showToast('请先选择要删除的收藏');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${selectedFavoriteList.length} 个收藏吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('取消', style: TextStyle(color: Styles.c_8E9AB0)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // 关闭对话框
              final success = await favoriteController.batchDeleteSelected();
              if (success) {
                IMViews.showToast('删除成功');
              }
            },
            child: Text('删除', style: TextStyle(color: Styles.c_FF381F)),
          ),
        ],
      ),
    );
  }

  /// 菜单选择处理
  void onMenuSelected(String value) {
    switch (value) {
      case 'multiSelect':
        favoriteController.enterMultiSelectMode();
        break;
      case 'category':
        AppNavigator.startCategoryManagement();
        break;
      case 'stats':
        AppNavigator.startFavoriteStats();
        break;
      case 'export':
        showExportDialog();
        break;
    }
  }

  /// 清除所有筛选条件
  void clearAllFilters() {
    favoriteController.clearAllFilters();
  }

  /// 打开搜索页面
  void openSearch() {
    AppNavigator.startFavoriteSearch();
  }

  /// 显示分类筛选
  void showCategoryFilter() {
    Get.bottomSheet(
      _buildCategoryFilterSheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  /// 显示类型筛选
  void showTypeFilter() {
    Get.bottomSheet(
      _buildTypeFilterSheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  // ==================== 私有方法 ====================

  /// 构建分类筛选底部弹窗
  Widget _buildCategoryFilterSheet() {
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
                '选择分类',
                style: Styles.ts_0C1C33_18sp_medium,
              ),
              const Spacer(),
              IconButton(
                onPressed: Get.back,
                icon: Icon(Icons.close, size: 20.w),
              ),
            ],
          ),
          16.verticalSpace,
          // 分类列表
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300.h),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 全部分类选项
                  _buildCategoryOption(
                    categoryID: null,
                    categoryName: '全部分类',
                    categoryColor: '#8E9AB0',
                    isSelected: selectedCategoryID.value == null,
                  ),
                  // 具体分类选项
                  ...categoryList.map((category) => _buildCategoryOption(
                    categoryID: category.categoryID,
                    categoryName: category.displayName,
                    categoryColor: category.displayColor,
                    isSelected: selectedCategoryID.value == category.categoryID,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建类型筛选底部弹窗
  Widget _buildTypeFilterSheet() {
    final typeOptions = [
      {'type': 0, 'name': '全部类型', 'icon': Icons.all_inclusive},
      {'type': FavoriteType.message, 'name': '消息', 'icon': Icons.chat_bubble_outline},
      {'type': FavoriteType.image, 'name': '图片', 'icon': Icons.image_outlined},
      {'type': FavoriteType.video, 'name': '视频', 'icon': Icons.videocam_outlined},
      {'type': FavoriteType.audio, 'name': '语音', 'icon': Icons.mic_outlined},
      {'type': FavoriteType.file, 'name': '文件', 'icon': Icons.insert_drive_file_outlined},
      {'type': FavoriteType.link, 'name': '链接', 'icon': Icons.link_outlined},
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.8, // 限制最大高度为屏幕的80%
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Text(
                '选择类型',
                style: Styles.ts_0C1C33_18sp_medium,
              ),
              const Spacer(),
              IconButton(
                onPressed: Get.back,
                icon: Icon(Icons.close, size: 20.w),
              ),
            ],
          ),
          16.verticalSpace,
          // 类型列表 - 使用可滚动容器
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: typeOptions.map((option) => _buildTypeOption(
                  favoriteType: option['type'] as int,
                  typeName: option['name'] as String,
                  typeIcon: option['icon'] as IconData,
                  isSelected: selectedFavoriteType.value == option['type'],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类选项
  Widget _buildCategoryOption({
    required String? categoryID,
    required String categoryName,
    required String categoryColor,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          color: Color(int.parse(categoryColor.replaceFirst('#', '0xFF'))),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        categoryName,
        style: isSelected ? Styles.ts_1B72EC_16sp : Styles.ts_0C1C33_16sp,
      ),
      trailing: isSelected ? Icon(Icons.check, color: Styles.c_1B72EC, size: 20.w) : null,
      onTap: () {
        favoriteController.setCategoryFilter(categoryID);
        Get.back();
      },
    );
  }

  /// 构建类型选项
  Widget _buildTypeOption({
    required int favoriteType,
    required String typeName,
    required IconData typeIcon,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        typeIcon,
        size: 20.w,
        color: isSelected ? Styles.c_1B72EC : Styles.c_8E9AB0,
      ),
      title: Text(
        typeName,
        style: isSelected ? Styles.ts_1B72EC_16sp : Styles.ts_0C1C33_16sp,
      ),
      trailing: isSelected ? Icon(Icons.check, color: Styles.c_1B72EC, size: 20.w) : null,
      onTap: () {
        favoriteController.setTypeFilter(favoriteType);
        Get.back();
      },
    );
  }

  /// 构建批量移动分类底部弹窗
  Widget _buildBatchMoveCategorySheet() {
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
                '移动到分类',
                style: Styles.ts_0C1C33_18sp_medium,
              ),
              const Spacer(),
              Text(
                '已选择 ${selectedFavoriteList.length} 项',
                style: Styles.ts_8E9AB0_14sp,
              ),
              IconButton(
                onPressed: Get.back,
                icon: Icon(Icons.close, size: 20.w),
              ),
            ],
          ),
          16.verticalSpace,
          // 分类列表
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300.h),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 默认分类选项
                  _buildBatchMoveCategoryOption(
                    categoryID: null,
                    categoryName: '默认分类',
                    categoryColor: '#8E9AB0',
                  ),
                  // 具体分类选项
                  ...categoryList.map((category) => _buildBatchMoveCategoryOption(
                    categoryID: category.categoryID,
                    categoryName: category.displayName,
                    categoryColor: category.displayColor,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建批量移动分类选项
  Widget _buildBatchMoveCategoryOption({
    required String? categoryID,
    required String categoryName,
    required String categoryColor,
  }) {
    return ListTile(
      leading: Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          color: Color(int.parse(categoryColor.replaceFirst('#', '0xFF'))),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        categoryName,
        style: Styles.ts_0C1C33_16sp,
      ),
      onTap: () async {
        Get.back(); // 关闭底部弹窗

        // 执行批量移动
        final success = await favoriteController.batchMoveToCategory(categoryID ?? '');
        if (success) {
          IMViews.showToast('移动成功');
        }
      },
    );
  }

  /// 显示导出对话框
  void showExportDialog() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Text(
                  '导出收藏数据',
                  style: Styles.ts_0C1C33_18sp_medium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: Get.back,
                  icon: Icon(Icons.close, size: 20.w),
                ),
              ],
            ),
            16.verticalSpace,
            // 导出选项
            _buildExportOption(
              title: 'JSON格式',
              subtitle: '包含完整数据结构，适合备份',
              icon: Icons.code,
              onTap: () => _exportData(ExportFormat.json),
            ),
            _buildExportOption(
              title: 'CSV格式',
              subtitle: '表格格式，适合Excel打开',
              icon: Icons.table_chart,
              onTap: () => _exportData(ExportFormat.csv),
            ),
            _buildExportOption(
              title: '文本格式',
              subtitle: '纯文本格式，易于阅读',
              icon: Icons.text_snippet,
              onTap: () => _exportData(ExportFormat.txt),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导出选项
  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24.w, color: Styles.c_1B72EC),
      title: Text(title, style: Styles.ts_0C1C33_16sp),
      subtitle: Text(subtitle, style: Styles.ts_8E9AB0_12sp),
      onTap: onTap,
    );
  }

  /// 执行数据导出
  Future<void> _exportData(ExportFormat format) async {
    Get.back(); // 关闭底部弹窗

    try {
      // 显示加载对话框
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              16.verticalSpace,
              const Text('正在导出数据...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // 执行导出
      final filePath = await FavoriteExportService.instance.exportAllFavorites(
        format: format,
        includeStats: true,
        includeCategories: true,
      );

      Get.back(); // 关闭加载对话框

      if (filePath != null) {
        // 显示导出成功对话框
        Get.dialog(
          AlertDialog(
            title: const Text('导出成功'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('文件已保存到：'),
                8.verticalSpace,
                Text(
                  filePath,
                  style: Styles.ts_8E9AB0_12sp,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text('确定'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  FavoriteExportService.instance.shareExportFile(filePath);
                },
                child: const Text('分享'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Get.back(); // 关闭加载对话框
      // Logger.print('导出失败: $e');
      IMViews.showToast('导出失败：${e.toString()}');
    }
  }
}
