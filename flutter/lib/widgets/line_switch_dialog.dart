import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class LineSwitchDialog extends StatelessWidget {
  final int currentIndex;
  final Function(int) onLineSelected;

  const LineSwitchDialog({
    super.key,
    required this.currentIndex,
    required this.onLineSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lines = Config.presetLines;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        width: 320.w,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '切换线路',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            16.verticalSpace,
            
            // 线路列表或空状态
            if (lines.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  '暂无可用线路',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              )
            else
              ...lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                final isSelected = index == currentIndex;
                
                return _buildLineItem(
                  line: line,
                  isSelected: isSelected,
                  onTap: () {
                    Get.back();
                    onLineSelected(index);
                  },
                );
              }).toList(),
            
            20.verticalSpace,
            
            // 取消按钮
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem({
    required Map<String, String> line,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFE3F2FD) : Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected ? Color(0xFF2196F3) : Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 线路名称
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line['name'] ?? '',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Color(0xFF2196F3) : Color(0xFF1C1C1E),
                        ),
                      ),
                      // 4.verticalSpace,
                      // Text(
                      //   line['serverIP'] ?? '',
                      //   style: TextStyle(
                      //     fontSize: 12.sp,
                      //     color: Color(0xFF8E8E93),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                
                // 选中状态指示器
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20.w,
                    color: Color(0xFF2196F3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示线路切换弹框
  static void show({
    required int currentIndex,
    required Function(int) onLineSelected,
  }) {
    // 调试信息
    // Logger.print('显示线路切换弹框，当前索引: $currentIndex');
    // Logger.print('当前线路配置: ${Config.presetLines[currentIndex]}');
    
    Get.dialog(
      LineSwitchDialog(
        currentIndex: currentIndex,
        onLineSelected: onLineSelected,
      ),
      barrierDismissible: true,
    );
  }
}
