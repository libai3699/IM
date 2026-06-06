import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/favorite_controller.dart';
import '../models/favorite_models.dart';

/// 导出格式枚举
enum ExportFormat {
  json,
  csv,
  txt,
}

/// 收藏数据导出服务类
/// 
/// 提供收藏数据的导出功能，支持多种格式
/// 包括JSON、CSV、文本等格式的导出
class FavoriteExportService {
  /// 私有构造函数，实现单例模式
  FavoriteExportService._();

  /// 单例实例
  static final FavoriteExportService _instance = FavoriteExportService._();

  /// 获取单例实例
  static FavoriteExportService get instance => _instance;

  /// 收藏控制器
  final _favoriteController = Get.find<FavoriteController>();



  // ==================== 主要导出方法 ====================

  /// 导出所有收藏数据
  /// 
  /// [format] 导出格式
  /// [includeStats] 是否包含统计信息
  /// [includeCategories] 是否包含分类信息
  /// 返回导出文件的路径
  Future<String?> exportAllFavorites({
    ExportFormat format = ExportFormat.json,
    bool includeStats = true,
    bool includeCategories = true,
  }) async {
    try {
      // 检查权限
      if (!await _checkPermissions()) {
        IMViews.showToast('需要存储权限才能导出文件');
        return null;
      }

      // 获取所有收藏数据
      final favorites = await _getAllFavorites();
      if (favorites.isEmpty) {
        IMViews.showToast('暂无收藏数据可导出');
        return null;
      }

      // 获取统计和分类数据
      FavoriteStats? stats;
      List<CategoryInfo> categories = [];
      
      if (includeStats) {
        await _favoriteController.loadFavoriteStats();
        stats = _favoriteController.stats.value;
      }
      
      if (includeCategories) {
        await _favoriteController.loadCategoryList();
        categories = _favoriteController.categoryList;
      }

      // 根据格式导出
      String? filePath;
      switch (format) {
        case ExportFormat.json:
          filePath = await _exportToJson(favorites, stats, categories);
          break;
        case ExportFormat.csv:
          filePath = await _exportToCsv(favorites);
          break;
        case ExportFormat.txt:
          filePath = await _exportToText(favorites);
          break;
      }

      if (filePath != null) {
        IMViews.showToast('导出成功');
        return filePath;
      } else {
        IMViews.showToast('导出失败');
        return null;
      }
    } catch (e) {
      // Logger.print('导出收藏数据失败: $e');
      IMViews.showToast('导出失败：${e.toString()}');
      return null;
    }
  }

  /// 导出指定分类的收藏
  /// 
  /// [categoryID] 分类ID，null表示默认分类
  /// [format] 导出格式
  Future<String?> exportCategoryFavorites({
    String? categoryID,
    ExportFormat format = ExportFormat.json,
  }) async {
    try {
      if (!await _checkPermissions()) {
        IMViews.showToast('需要存储权限才能导出文件');
        return null;
      }

      final favorites = await _getFavoritesByCategory(categoryID);
      if (favorites.isEmpty) {
        IMViews.showToast('该分类下暂无收藏数据');
        return null;
      }

      String? filePath;
      switch (format) {
        case ExportFormat.json:
          filePath = await _exportToJson(favorites, null, []);
          break;
        case ExportFormat.csv:
          filePath = await _exportToCsv(favorites);
          break;
        case ExportFormat.txt:
          filePath = await _exportToText(favorites);
          break;
      }

      if (filePath != null) {
        IMViews.showToast('导出成功');
        return filePath;
      } else {
        IMViews.showToast('导出失败');
        return null;
      }
    } catch (e) {
      // Logger.print('导出分类收藏失败: $e');
      IMViews.showToast('导出失败：${e.toString()}');
      return null;
    }
  }

  /// 分享导出文件
  /// 
  /// [filePath] 文件路径
  /// [title] 分享标题
  Future<void> shareExportFile(String filePath, {String? title}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title ?? '我的收藏数据',
      );
    } catch (e) {
      // Logger.print('分享文件失败: $e');
      IMViews.showToast('分享失败');
    }
  }

  // ==================== 私有方法 ====================

  /// 检查存储权限
  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true; // Web平台不需要权限

    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    
    return true; // iOS不需要特殊权限
  }

  /// 获取所有收藏数据
  Future<List<FavoriteInfo>> _getAllFavorites() async {
    // 直接返回当前已加载的收藏列表
    // 在实际使用前应该确保数据已经加载
    return _favoriteController.favoriteList;
  }

  /// 获取指定分类的收藏
  Future<List<FavoriteInfo>> _getFavoritesByCategory(String? categoryID) async {
    // 从当前收藏列表中筛选指定分类的收藏
    return _favoriteController.favoriteList.where((favorite) {
      if (categoryID == null) {
        return favorite.categoryID == null || favorite.categoryID!.isEmpty;
      }
      return favorite.categoryID == categoryID;
    }).toList();
  }

  /// 导出为JSON格式
  Future<String?> _exportToJson(
    List<FavoriteInfo> favorites,
    FavoriteStats? stats,
    List<CategoryInfo> categories,
  ) async {
    try {
      final exportData = {
        'exportInfo': {
          'version': '1.0',
          'exportTime': DateTime.now().toIso8601String(),
          'totalCount': favorites.length,
        },
        'favorites': favorites.map((f) => f.toJson()).toList(),
        if (stats != null) 'statistics': stats.toJson(),
        if (categories.isNotEmpty) 'categories': categories.map((c) => c.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'favorites_${DateTime.now().millisecondsSinceEpoch}.json';
      
      return await _saveFile(fileName, jsonString);
    } catch (e) {
      // Logger.print('导出JSON失败: $e');
      return null;
    }
  }

  /// 导出为CSV格式
  Future<String?> _exportToCsv(List<FavoriteInfo> favorites) async {
    try {
      final csvLines = <String>[];
      
      // CSV头部
      csvLines.add('ID,标题,内容,类型,分类,标签,创建时间,备注');
      
      // CSV数据行
      for (final favorite in favorites) {
        final line = [
          _escapeCsvField(favorite.favoriteID ?? ''),
          _escapeCsvField(favorite.title ?? ''),
          _escapeCsvField(favorite.content ?? ''),
          _escapeCsvField(_getTypeDisplayName(favorite.favoriteType)),
          _escapeCsvField(favorite.categoryName ?? ''),
          _escapeCsvField(favorite.tags?.join(';') ?? ''),
          _escapeCsvField(favorite.createTimeText),
          _escapeCsvField(favorite.notes ?? ''),
        ].join(',');
        csvLines.add(line);
      }

      final csvContent = csvLines.join('\n');
      final fileName = 'favorites_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      return await _saveFile(fileName, csvContent);
    } catch (e) {
      // Logger.print('导出CSV失败: $e');
      return null;
    }
  }

  /// 导出为文本格式
  Future<String?> _exportToText(List<FavoriteInfo> favorites) async {
    try {
      final textLines = <String>[];
      
      textLines.add('我的收藏数据导出');
      textLines.add('导出时间：${DateTime.now().toString()}');
      textLines.add('总数量：${favorites.length}');
      textLines.add('=' * 50);
      textLines.add('');

      for (int i = 0; i < favorites.length; i++) {
        final favorite = favorites[i];
        textLines.add('${i + 1}. ${favorite.displayTitle}');
        textLines.add('   类型：${_getTypeDisplayName(favorite.favoriteType)}');
        textLines.add('   分类：${favorite.categoryName ?? '默认分类'}');
        textLines.add('   时间：${favorite.createTimeText}');
        if (favorite.content?.isNotEmpty == true) {
          textLines.add('   内容：${favorite.content}');
        }
        if (favorite.tags?.isNotEmpty == true) {
          textLines.add('   标签：${favorite.tags!.join(', ')}');
        }
        if (favorite.notes?.isNotEmpty == true) {
          textLines.add('   备注：${favorite.notes}');
        }
        textLines.add('');
      }

      final textContent = textLines.join('\n');
      final fileName = 'favorites_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      return await _saveFile(fileName, textContent);
    } catch (e) {
      // Logger.print('导出文本失败: $e');
      return null;
    }
  }

  /// 保存文件到本地
  Future<String?> _saveFile(String fileName, String content) async {
    try {
      Directory directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      
      return file.path;
    } catch (e) {
      // Logger.print('保存文件失败: $e');
      return null;
    }
  }

  /// 转义CSV字段
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 获取类型显示名称
  String _getTypeDisplayName(int? type) {
    switch (type) {
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
        return '未知';
    }
  }
}
