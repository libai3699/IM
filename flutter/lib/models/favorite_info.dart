import 'dart:convert';

/// 收藏信息数据模型
/// 
/// 根据后端API文档定义的收藏信息结构创建
/// 支持JSON序列化和反序列化
class FavoriteInfo {
  /// 收藏ID，唯一标识符
  String? favoriteID;

  /// 用户ID
  String? userID;

  /// 收藏类型
  /// 1: 消息, 2: 文件, 3: 图片, 4: 视频, 5: 音频, 6: 链接
  int? favoriteType;

  /// 源内容ID（消息ID、文件ID等）
  String? sourceID;

  /// 会话ID
  String? conversationID;

  /// 收藏标题
  String? title;

  /// 收藏内容
  String? content;

  /// 缩略图URL
  String? thumbnailURL;

  /// 分类ID
  String? categoryID;

  /// 标签数组
  List<String>? tags;

  /// 备注信息
  String? notes;

  /// 创建时间戳（毫秒）
  int? createTime;

  /// 更新时间戳（毫秒）
  int? updateTime;

  /// 扩展字段，用于存储额外信息
  String? ex;

  /// 扩展字段的Map形式，便于客户端使用
  Map<String, dynamic> exMap = {};

  /// 是否为乐观更新（临时状态）
  bool? isOptimistic;

  // ==================== 扩展属性 ====================

  /// 显示标题
  String get displayTitle {
    if (title?.isNotEmpty == true) {
      return title!;
    }
    if (content?.isNotEmpty == true) {
      return content!.length > 50 ? '${content!.substring(0, 50)}...' : content!;
    }
    return '收藏内容';
  }

  /// 分类名称
  String? get categoryName {
    // 这里应该从分类ID获取分类名称，暂时返回null
    // 在实际使用中，应该通过FavoriteController获取分类信息
    return null;
  }

  /// 分类颜色
  String? get categoryColor {
    // 这里应该从分类ID获取分类颜色，暂时返回默认颜色
    return '#2196F3';
  }

  /// 创建时间文本
  String get createTimeText {
    if (createTime == null) return '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(createTime!);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 构造函数
  FavoriteInfo({
    this.favoriteID,
    this.userID,
    this.favoriteType,
    this.sourceID,
    this.conversationID,
    this.title,
    this.content,
    this.thumbnailURL,
    this.categoryID,
    this.tags,
    this.notes,
    this.createTime,
    this.updateTime,
    this.ex,
    this.exMap = const <String, dynamic>{},
    this.isOptimistic,
  });

  /// 从JSON创建FavoriteInfo对象
  FavoriteInfo.fromJson(Map<String, dynamic> json) {
    favoriteID = json['favoriteID'];
    userID = json['userID'];
    favoriteType = json['favoriteType'];
    sourceID = json['sourceID'];
    conversationID = json['conversationID'];
    title = json['title'];
    content = json['content'];
    thumbnailURL = json['thumbnailURL'];
    categoryID = json['categoryID'];
    
    // 处理标签数组
    if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => '$e').toList();
    }
    
    notes = json['notes'];
    createTime = json['createTime'];
    updateTime = json['updateTime'];
    ex = json['ex'];
    
    // 处理扩展字段
    exMap = json['exMap'] ?? {};
    
    // 如果ex字段存在且是JSON字符串，尝试解析到exMap
    if (ex != null && ex!.isNotEmpty) {
      try {
        final decoded = jsonDecode(ex!);
        if (decoded is Map<String, dynamic>) {
          exMap.addAll(decoded);
        }
      } catch (e) {
        // 解析失败时忽略，保持原有exMap
      }
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['favoriteID'] = favoriteID;
    data['userID'] = userID;
    data['favoriteType'] = favoriteType;
    data['sourceID'] = sourceID;
    data['conversationID'] = conversationID;
    data['title'] = title;
    data['content'] = content;
    data['thumbnailURL'] = thumbnailURL;
    data['categoryID'] = categoryID;
    data['tags'] = tags;
    data['notes'] = notes;
    data['createTime'] = createTime;
    data['updateTime'] = updateTime;
    data['ex'] = ex;
    data['exMap'] = exMap;
    return data;
  }

  /// 转换为字符串（JSON格式）
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// 判断是否为单聊收藏
  bool get isSingleChat => conversationID?.contains('single') == true;

  /// 判断是否为群聊收藏
  bool get isGroupChat => conversationID?.contains('group') == true;

  /// 获取收藏类型名称
  String get favoriteTypeName {
    switch (favoriteType) {
      case FavoriteType.message:
        return '消息';
      case FavoriteType.file:
        return '文件';
      case FavoriteType.image:
        return '图片';
      case FavoriteType.video:
        return '视频';
      case FavoriteType.audio:
        return '音频';
      case FavoriteType.link:
        return '链接';
      default:
        return '未知';
    }
  }

  /// 判断是否有缩略图
  bool get hasThumbnail => thumbnailURL != null && thumbnailURL!.isNotEmpty;

  /// 判断是否有标签
  bool get hasTags => tags != null && tags!.isNotEmpty;

  /// 获取标签字符串（用逗号分隔）
  String get tagsString => tags?.join(', ') ?? '';

  /// 更新收藏信息
  void update(FavoriteInfo other) {
    if (favoriteID != other.favoriteID) return;
    
    userID = other.userID ?? userID;
    favoriteType = other.favoriteType ?? favoriteType;
    sourceID = other.sourceID ?? sourceID;
    conversationID = other.conversationID ?? conversationID;
    title = other.title ?? title;
    content = other.content ?? content;
    thumbnailURL = other.thumbnailURL ?? thumbnailURL;
    categoryID = other.categoryID ?? categoryID;
    tags = other.tags ?? tags;
    notes = other.notes ?? notes;
    createTime = other.createTime ?? createTime;
    updateTime = other.updateTime ?? updateTime;
    ex = other.ex ?? ex;
    exMap.addAll(other.exMap);
  }

  /// 复制收藏信息
  FavoriteInfo copyWith({
    String? favoriteID,
    String? userID,
    int? favoriteType,
    String? sourceID,
    String? conversationID,
    String? title,
    String? content,
    String? thumbnailURL,
    String? categoryID,
    List<String>? tags,
    String? notes,
    int? createTime,
    int? updateTime,
    String? ex,
    Map<String, dynamic>? exMap,
  }) {
    return FavoriteInfo(
      favoriteID: favoriteID ?? this.favoriteID,
      userID: userID ?? this.userID,
      favoriteType: favoriteType ?? this.favoriteType,
      sourceID: sourceID ?? this.sourceID,
      conversationID: conversationID ?? this.conversationID,
      title: title ?? this.title,
      content: content ?? this.content,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      categoryID: categoryID ?? this.categoryID,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      ex: ex ?? this.ex,
      exMap: exMap ?? this.exMap,
    );
  }

  /// 重写相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteInfo && other.favoriteID == favoriteID;
  }

  /// 重写hashCode
  @override
  int get hashCode => favoriteID.hashCode;
}

/// 收藏类型常量定义
class FavoriteType {
  /// 消息类型
  static const int message = 1;
  
  /// 文件类型
  static const int file = 2;
  
  /// 图片类型
  static const int image = 3;
  
  /// 视频类型
  static const int video = 4;
  
  /// 音频类型
  static const int audio = 5;
  
  /// 链接类型
  static const int link = 6;

  /// 获取所有收藏类型
  static List<int> get allTypes => [message, file, image, video, audio, link];

  /// 获取收藏类型名称
  static String getTypeName(int type) {
    switch (type) {
      case message:
        return '消息';
      case file:
        return '文件';
      case image:
        return '图片';
      case video:
        return '视频';
      case audio:
        return '音频';
      case link:
        return '链接';
      default:
        return '未知';
    }
  }

  /// 判断是否为有效的收藏类型
  static bool isValidType(int type) {
    return allTypes.contains(type);
  }
}
