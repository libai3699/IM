import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../models/favorite_models.dart';
import 'category_management_logic.dart';

/// 分类管理页面
class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<CategoryManagementLogic>();
    
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        title: Text('分类管理', style: Styles.ts_0C1C33_18sp_medium),
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Styles.c_0C1C33),
        ),
        actions: [
          // 添加分类按钮
          IconButton(
            onPressed: logic.showCreateCategoryDialog,
            icon: Icon(Icons.add, size: 24.w, color: Styles.c_0C1C33),
          ),
        ],
      ),
      body: Column(
        children: [
          // 提示信息
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Styles.c_1B72EC.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Styles.c_1B72EC.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20.w, color: Styles.c_1B72EC),
                12.horizontalSpace,
                Expanded(
                  child: Text(
                    '您可以创建自定义分类来更好地组织收藏内容',
                    style: TextStyle(fontSize: 14.sp, color: Styles.c_1B72EC),
                  ),
                ),
              ],
            ),
          ),
          // 分类列表
          Expanded(
            child: Obx(() {
              if (logic.isLoadingCategories.value && logic.categoryList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (logic.categoryList.isEmpty) {
                return _buildEmptyState(logic);
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: logic.categoryList.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  final category = logic.categoryList[index];
                  return _buildCategoryItem(logic, category, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(CategoryManagementLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64.w,
            color: Styles.c_8E9AB0,
          ),
          16.verticalSpace,
          Text(
            '暂无自定义分类',
            style: Styles.ts_8E9AB0_16sp,
          ),
          8.verticalSpace,
          Text(
            '点击右上角"+"创建分类',
            style: Styles.ts_8E9AB0_12sp,
          ),
          24.verticalSpace,
          ElevatedButton.icon(
            onPressed: logic.showCreateCategoryDialog,
            icon: Icon(Icons.add, size: 18.w),
            label: const Text('创建分类'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.c_1B72EC,
              foregroundColor: Styles.c_FFFFFF,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem(CategoryManagementLogic logic, CategoryInfo category, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Styles.c_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => logic.showCategoryDetail(category),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // 分类颜色指示器
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.displayColor.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category,
                    color: Styles.c_FFFFFF,
                    size: 20.w,
                  ),
                ),
                16.horizontalSpace,
                // 分类信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: Styles.ts_0C1C33_16sp_medium,
                      ),
                      4.verticalSpace,
                      Text(
                        category.favoriteCountText,
                        style: Styles.ts_8E9AB0_12sp,
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                PopupMenuButton<String>(
                  onSelected: (value) => logic.onCategoryMenuSelected(value, category),
                  itemBuilder: (context) => [
                    if (!category.isDefault) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16.w, color: Styles.c_0C1C33),
                            8.horizontalSpace,
                            Text('编辑', style: Styles.ts_0C1C33_14sp),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16.w, color: Styles.c_FF381F),
                            8.horizontalSpace,
                            Text('删除', style: TextStyle(fontSize: 14.sp, color: Styles.c_FF381F)),
                          ],
                        ),
                      ),
                    ] else ...[
                      PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16.w, color: Styles.c_8E9AB0),
                            8.horizontalSpace,
                            Text('默认分类不可编辑', style: Styles.ts_8E9AB0_14sp),
                          ],
                        ),
                      ),
                    ],
                  ],
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.more_vert,
                      size: 20.w,
                      color: Styles.c_8E9AB0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
