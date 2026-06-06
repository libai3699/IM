import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/favorite_controller.dart';
import '../../../models/favorite_models.dart';
import '../../../routes/app_navigator.dart';
import '../../../core/controller/im_controller.dart';

/// 收藏详情页面逻辑控制器
class FavoriteDetailLogic extends GetxController {
  /// 收藏控制器
  final favoriteController = Get.find<FavoriteController>();

  /// IM控制器
  final imLogic = Get.find<IMController>();

  // ==================== 响应式状态 ====================

  /// 收藏信息
  final favoriteInfo = Rx<FavoriteInfo?>(null);

  /// 是否正在加载
  final isLoading = false.obs;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();
    
    // 从路由参数获取收藏信息
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['favoriteInfo'] != null) {
      favoriteInfo.value = arguments['favoriteInfo'] as FavoriteInfo;
    }
  }

  @override
  void onReady() {
    super.onReady();
    
    // 如果没有收藏信息，尝试从ID加载
    if (favoriteInfo.value == null) {
      final favoriteID = Get.parameters['favoriteID'];
      if (favoriteID?.isNotEmpty == true) {
        loadFavoriteInfo(favoriteID!);
      }
    }
  }

  // ==================== 数据操作 ====================

  /// 加载收藏详情
  Future<void> loadFavoriteInfo(String favoriteID) async {
    try {
      isLoading.value = true;
      
      final info = await favoriteController.getFavoriteInfo(favoriteID);
      if (info != null) {
        favoriteInfo.value = info;
      } else {
        IMViews.showToast('收藏信息不存在');
        Get.back();
      }
    } catch (e) {
      // Logger.print('加载收藏详情失败: $e');
      IMViews.showToast('加载失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新收藏信息
  Future<void> refreshFavoriteInfo() async {
    final favorite = favoriteInfo.value;
    if (favorite?.favoriteID != null) {
      await loadFavoriteInfo(favorite!.favoriteID!);
    }
  }

  // ==================== 用户交互 ====================

  /// 菜单选择处理
  void onMenuSelected(String value) {
    final favorite = favoriteInfo.value;
    if (favorite == null) return;

    switch (value) {
      case 'edit':
        editFavorite(favorite);
        break;
      case 'share':
        shareFavorite(favorite);
        break;
      case 'jumpToSource':
        jumpToSourceMessage(favorite);
        break;
      case 'delete':
        deleteFavorite(favorite);
        break;
    }
  }

  /// 编辑收藏
  void editFavorite(FavoriteInfo favorite) {
    AppNavigator.startFavoriteEdit(favoriteInfo: favorite);
  }

  /// 分享收藏
  void shareFavorite(FavoriteInfo favorite) {
    String shareContent = '';
    
    switch (favorite.favoriteType) {
      case FavoriteType.message:
        shareContent = favorite.content ?? '';
        break;
      case FavoriteType.image:
      case FavoriteType.video:
      case FavoriteType.audio:
      case FavoriteType.file:
        shareContent = '${favorite.title}\n${favorite.content}';
        break;
      case FavoriteType.link:
        shareContent = favorite.content ?? '';
        break;
      default:
        shareContent = favorite.content ?? favorite.title ?? '';
    }

    if (shareContent.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: shareContent));
      IMViews.showToast('已复制到剪贴板');
    } else {
      IMViews.showToast('无可分享的内容');
    }
  }

  /// 跳转到原消息
  void jumpToSourceMessage(FavoriteInfo favorite) async {
    if (favorite.conversationID?.isEmpty != false || favorite.sourceID?.isEmpty != false) {
      IMViews.showToast('无法定位原消息');
      return;
    }

    try {
      // 首先获取会话信息
      final conversations = await OpenIM.iMManager.conversationManager.getMultipleConversation(
        conversationIDList: [favorite.conversationID!],
      );

      if (conversations.isEmpty) {
        IMViews.showToast('会话不存在');
        return;
      }

      final conversationInfo = conversations.first;

      // 尝试根据clientMsgID查找消息
      Message? targetMessage;
      bool messageExists = false;

      try {
        // 方法1: 尝试直接获取历史消息
        final historyMessages = await OpenIM.iMManager.messageManager.getAdvancedHistoryMessageList(
          conversationID: favorite.conversationID!,
          startMsg: null, // 从最新消息开始
          count: 100, // 获取最近100条消息
        );

        // 在历史消息中查找目标消息
        targetMessage = historyMessages.messageList?.firstWhereOrNull(
          (msg) => msg.clientMsgID == favorite.sourceID,
        );

        if (targetMessage != null) {
          messageExists = true;
        } else {
          // 方法2: 如果在最近消息中没找到，尝试更大范围搜索
          try {
            final moreMessages = await OpenIM.iMManager.messageManager.getAdvancedHistoryMessageList(
              conversationID: favorite.conversationID!,
              startMsg: historyMessages.messageList?.isNotEmpty == true ? historyMessages.messageList!.first : null,
              count: 500, // 扩大搜索范围
            );

            targetMessage = moreMessages.messageList?.firstWhereOrNull(
              (msg) => msg.clientMsgID == favorite.sourceID,
            );

            if (targetMessage != null) {
              messageExists = true;
            }
          } catch (e) {
            // Logger.print('扩大范围搜索消息失败: $e');
          }
        }
      } catch (e) {
        // Logger.print('获取历史消息失败: $e');
      }

      // 跳转到聊天页面
      AppNavigator.startChat(
        conversationInfo: conversationInfo,
        searchMessage: targetMessage, // 如果找到消息则定位，否则正常打开聊天
      );

      // 只有在确实没有找到消息时才显示删除提示
      if (!messageExists) {
        Future.delayed(const Duration(milliseconds: 500), () {
          IMViews.showToast('原消息可能已被删除');
        });
      }
    } catch (e) {
      // Logger.print('跳转到原消息失败: $e');
      IMViews.showToast('跳转失败，请稍后重试');
    }
  }

  /// 删除收藏
  void deleteFavorite(FavoriteInfo favorite) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个收藏吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('取消', style: TextStyle(color: Styles.c_8E9AB0)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // 关闭对话框
              
              final success = await favoriteController.removeFavorite(favorite.favoriteID!);
              if (success) {
                Get.back(); // 返回上一页
              }
            },
            child: Text('删除', style: TextStyle(color: Styles.c_FF381F)),
          ),
        ],
      ),
    );
  }

  // ==================== 内容操作 ====================

  /// 预览图片
  void previewImage(FavoriteInfo favorite) {
    if (favorite.content?.isNotEmpty == true) {
      AppNavigator.startPreviewImage(
        imageUrls: [favorite.content!],
        initialIndex: 0,
      );
    }
  }

  /// 播放视频
  void playVideo(FavoriteInfo favorite) {
    if (favorite.content?.isNotEmpty == true) {
      AppNavigator.startVideoPlayer(
        videoUrl: favorite.content!,
        title: favorite.title,
      );
    }
  }

  /// 播放音频
  void playAudio(FavoriteInfo favorite) {
    if (favorite.content?.isNotEmpty == true) {
      // 这里可以集成音频播放器
      IMViews.showToast('音频播放功能开发中');
    }
  }

  /// 打开文件
  void openFile(FavoriteInfo favorite) {
    if (favorite.content?.isNotEmpty == true) {
      // 这里可以下载并打开文件
      _downloadAndOpenFile(favorite);
    }
  }

  /// 打开链接
  void openLink(FavoriteInfo favorite) async {
    if (favorite.content?.isNotEmpty == true) {
      try {
        final uri = Uri.parse(favorite.content!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          IMViews.showToast('无法打开链接');
        }
      } catch (e) {
        // Logger.print('打开链接失败: $e');
        IMViews.showToast('链接格式错误');
      }
    }
  }

  // ==================== 辅助方法 ====================

  /// 获取会话名称
  String getConversationName(FavoriteInfo favorite) {
    // 这里可以根据conversationID查询会话信息
    // 暂时返回会话ID
    return favorite.conversationID ?? '未知会话';
  }

  /// 下载并打开文件
  void _downloadAndOpenFile(FavoriteInfo favorite) {
    // 显示下载进度对话框
    Get.dialog(
      AlertDialog(
        title: const Text('下载文件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            16.verticalSpace,
            Text('正在下载 ${favorite.title}...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // 模拟下载过程
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // 关闭下载对话框
      IMViews.showToast('文件下载完成');
      
      // 这里可以调用系统文件管理器打开文件
      // 或者使用第三方插件如 open_file
    });
  }

  /// 复制内容到剪贴板
  void copyContent() {
    final favorite = favoriteInfo.value;
    if (favorite?.content?.isNotEmpty == true) {
      Clipboard.setData(ClipboardData(text: favorite!.content!));
      IMViews.showToast('已复制到剪贴板');
    }
  }

  /// 添加到其他分类
  void moveToCategory() {
    final favorite = favoriteInfo.value;
    if (favorite == null) return;

    // 显示分类选择对话框
    Get.bottomSheet(
      _buildCategorySelectSheet(favorite),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
    );
  }

  /// 构建分类选择底部弹窗
  Widget _buildCategorySelectSheet(FavoriteInfo favorite) {
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
                children: favoriteController.categoryList.map((category) {
                  final isSelected = category.categoryID == favorite.categoryID;
                  return ListTile(
                    leading: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.displayColor.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      category.displayName,
                      style: isSelected ? Styles.ts_1B72EC_16sp : Styles.ts_0C1C33_16sp,
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: Styles.c_1B72EC, size: 20.w) : null,
                    onTap: isSelected ? null : () async {
                      Get.back();
                      
                      final success = await favoriteController.updateFavorite(
                        favoriteID: favorite.favoriteID!,
                        categoryID: category.categoryID,
                      );
                      
                      if (success != null) {
                        favoriteInfo.value = success;
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
