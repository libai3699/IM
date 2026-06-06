import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../controllers/favorite_controller.dart';
import '../../../models/favorite_models.dart';

/// 分类管理页面逻辑控制器
class CategoryManagementLogic extends GetxController {
  /// 收藏控制器
  final favoriteController = Get.find<FavoriteController>();

  // ==================== 响应式状态 ====================

  /// 分类列表（代理到FavoriteController）
  List<CategoryInfo> get categoryList => favoriteController.categoryList;

  /// 是否正在加载分类
  RxBool get isLoadingCategories => favoriteController.isLoadingCategories;

  // ==================== 生命周期 ====================

  @override
  void onReady() {
    super.onReady();
    // 页面准备完成后加载分类列表
    loadCategoryList();
  }

  // ==================== 数据操作 ====================

  /// 加载分类列表
  Future<void> loadCategoryList() async {
    await favoriteController.loadCategoryList();
  }

  // ==================== 用户交互 ====================

  /// 显示创建分类对话框
  void showCreateCategoryDialog() {
    _showCategoryDialog(
      title: '创建分类',
      confirmText: '创建',
      onConfirm: (name, color) => _createCategory(name, color),
    );
  }

  /// 显示编辑分类对话框
  void showEditCategoryDialog(CategoryInfo category) {
    _showCategoryDialog(
      title: '编辑分类',
      confirmText: '保存',
      initialName: category.categoryName,
      initialColor: category.categoryColor,
      onConfirm: (name, color) => _updateCategory(category, name, color),
    );
  }

  /// 显示分类详情
  void showCategoryDetail(CategoryInfo category) {
    Get.bottomSheet(
      _buildCategoryDetailSheet(category),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  /// 分类菜单选择处理
  void onCategoryMenuSelected(String value, CategoryInfo category) {
    switch (value) {
      case 'edit':
        showEditCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteConfirmDialog(category);
        break;
      case 'info':
        // 默认分类信息，不做处理
        break;
    }
  }

  // ==================== 私有方法 ====================

  /// 创建分类
  Future<void> _createCategory(String name, String color) async {
    final result = await favoriteController.createCategory(
      categoryName: name,
      categoryColor: color,
      sortOrder: categoryList.length,
    );
    
    if (result != null) {
      Get.back(); // 关闭对话框
    }
  }

  /// 更新分类
  Future<void> _updateCategory(CategoryInfo category, String name, String color) async {
    final result = await favoriteController.updateCategory(
      categoryID: category.categoryID!,
      categoryName: name,
      categoryColor: color,
    );
    
    if (result != null) {
      Get.back(); // 关闭对话框
    }
  }

  /// 删除分类
  Future<void> _deleteCategory(CategoryInfo category) async {
    final success = await favoriteController.deleteCategory(
      category.categoryID!,
      moveToDefault: true,
    );
    
    if (success) {
      Get.back(); // 关闭确认对话框
    }
  }

  /// 显示分类对话框
  void _showCategoryDialog({
    required String title,
    required String confirmText,
    String? initialName,
    String? initialColor,
    required Function(String name, String color) onConfirm,
  }) {
    final nameController = TextEditingController(text: initialName);
    final selectedColor = (initialColor ?? CategoryColor.defaultColor).obs;

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类名称输入
            Text('分类名称', style: Styles.ts_0C1C33_14sp_medium),
            8.verticalSpace,
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: '请输入分类名称',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              maxLength: 20,
            ),
            16.verticalSpace,
            // 颜色选择
            Text('分类颜色', style: Styles.ts_0C1C33_14sp_medium),
            8.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: Obx(() => Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: CategoryColor.predefinedColors.map((color) {
                  final isSelected = selectedColor.value == color;
                  return GestureDetector(
                    onTap: () => selectedColor.value = color,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Styles.c_0C1C33, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: Styles.c_FFFFFF, size: 14.w)
                          : null,
                    ),
                  );
                }).toList(),
              )),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('取消', style: TextStyle(color: Styles.c_8E9AB0)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                IMViews.showToast('请输入分类名称');
                return;
              }
              if (name.length > 20) {
                IMViews.showToast('分类名称不能超过20个字符');
                return;
              }
              onConfirm(name, selectedColor.value);
            },
            child: Text(confirmText, style: TextStyle(color: Styles.c_1B72EC)),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(CategoryInfo category) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除分类"${category.displayName}"吗？'),
            8.verticalSpace,
            if (category.hasFavorites)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Styles.c_FF9500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, size: 16.w, color: Styles.c_FF9500),
                    8.horizontalSpace,
                    Expanded(
                      child: Text(
                        '该分类下有${category.favoriteCount}个收藏，删除后将移动到默认分类',
                        style: TextStyle(fontSize: 12.sp, color: Styles.c_FF9500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('取消', style: TextStyle(color: Styles.c_8E9AB0)),
          ),
          TextButton(
            onPressed: () => _deleteCategory(category),
            child: Text('删除', style: TextStyle(color: Styles.c_FF381F)),
          ),
        ],
      ),
    );
  }

  /// 构建分类详情底部弹窗
  Widget _buildCategoryDetailSheet(CategoryInfo category) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: Color(int.parse(category.displayColor.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              12.horizontalSpace,
              Text(
                category.displayName,
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
          // 详细信息
          _buildDetailRow('收藏数量', category.favoriteCountText),
          _buildDetailRow('创建时间', category.createTimeText),
          _buildDetailRow('分类ID', category.categoryID ?? ''),
          16.verticalSpace,
          // 操作按钮
          if (!category.isDefault) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      showEditCategoryDialog(category);
                    },
                    icon: Icon(Icons.edit_outlined, size: 16.w),
                    label: const Text('编辑'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Styles.c_1B72EC,
                      side: BorderSide(color: Styles.c_1B72EC),
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showDeleteConfirmDialog(category);
                    },
                    icon: Icon(Icons.delete_outline, size: 16.w),
                    label: const Text('删除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Styles.c_FF381F,
                      side: BorderSide(color: Styles.c_FF381F),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Styles.c_8E9AB0.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.w, color: Styles.c_8E9AB0),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      '默认分类不可编辑或删除',
                      style: Styles.ts_8E9AB0_12sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: Styles.ts_8E9AB0_14sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Styles.ts_0C1C33_14sp,
            ),
          ),
        ],
      ),
    );
  }
}
