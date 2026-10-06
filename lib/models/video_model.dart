/// 短视频信息流的数据模型。
///
/// 相比旧版 `VideoModel`，这里补齐了首屏体验必需的字段：
/// - [coverUrl]：视频首帧出画前的占位封面，用来消除滑动后的黑屏。
/// - [aspectRatio]：服务端下发的宽高比，避免首帧尺寸抖动导致布局跳变。
/// - 计数统一为 int，旧版把数量存成 String 只能在 UI 上硬拼。
class VideoModel {
  const VideoModel({
    required this.id,
    required this.url,
    required this.coverUrl,
    required this.desc,
    this.authorName = '',
    this.authorAvatar = '',
    this.musicName = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.aspectRatio = 9 / 16,
    this.liked = false,
    this.followed = false,
  });

  final String id;

  /// 视频播放地址。
  final String url;

  /// 封面图地址，首帧渲染前展示。
  final String coverUrl;

  /// 视频描述文案。
  final String desc;

  final String authorName;
  final String authorAvatar;
  final String musicName;

  final int likeCount;
  final int commentCount;
  final int shareCount;

  /// 宽 / 高。服务端下发时可避免首帧布局抖动。
  final double aspectRatio;

  final bool liked;
  final bool followed;

  VideoModel copyWith({
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? liked,
    bool? followed,
  }) {
    return VideoModel(
      id: id,
      url: url,
      coverUrl: coverUrl,
      desc: desc,
      authorName: authorName,
      authorAvatar: authorAvatar,
      musicName: musicName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      aspectRatio: aspectRatio,
      liked: liked ?? this.liked,
      followed: followed ?? this.followed,
    );
  }

  /// 后端字段类型经常不稳定（数字有时是 int，有时是字符串），
  /// 这里统一做容错，避免解析直接抛异常导致整页白屏。
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: _asString(json['id']),
      url: _asString(json['url']),
      coverUrl: _asString(json['coverUrl']),
      desc: _asString(json['desc']),
      authorName: _asString(json['authorName']),
      authorAvatar: _asString(json['authorAvatar']),
      musicName: _asString(json['musicName']),
      likeCount: _asInt(json['likeCount']),
      commentCount: _asInt(json['commentCount']),
      shareCount: _asInt(json['shareCount']),
      aspectRatio: _asDouble(json['aspectRatio']) ?? 9 / 16,
      liked: _asBool(json['liked']),
      followed: _asBool(json['followed']),
    );
  }

  static String _asString(dynamic value) => value?.toString() ?? '';

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == 'true' || value == '1';
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VideoModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 数量展示格式化：12345 -> 1.2w。
String formatCount(int count) {
  if (count < 10000) return '$count';
  return '${(count / 10000).toStringAsFixed(1)}w';
}
