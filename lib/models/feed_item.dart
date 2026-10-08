/// 信息流内容模型：同一条信息流里可能混合多种内容形态。
///
/// 用 [type] 区分：
/// - [FeedItemType.video]：普通短视频，走播放器池播放；
/// - [FeedItemType.live]：直播，同样走播放器池（通常是 HLS 流），但**不**支持 seek、
///   需展示「直播中」标记与在线人数；
/// - [FeedItemType.image]：一张宣传图/海报，无播放器，全屏展示图片并可配置跳转。
///
/// 相比旧版只支持视频的 `VideoModel`，这里把三类内容收敛到一个模型里，
/// 字段按类型可为空：视频/直播用 [url] 作为播放地址，图片用 [imageUrl] 作为主图。
enum FeedItemType {
  video,
  live,
  image,
}

class FeedItem {
  const FeedItem({
    required this.id,
    required this.type,
    this.url = '',
    this.coverUrl = '',
    this.imageUrl = '',
    this.desc = '',
    this.title = '',
    this.actionUrl = '',
    this.authorName = '',
    this.authorAvatar = '',
    this.musicName = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewerCount = 0,
    this.aspectRatio = 9 / 16,
    this.liked = false,
    this.followed = false,
  });

  final String id;

  /// 内容类型：决定这一屏用哪种渲染方式。
  final FeedItemType type;

  /// 视频 / 直播的播放地址（直播通常是 .m3u8 HLS 流）。
  final String url;

  /// 封面图地址，首帧渲染前展示（视频/直播用）。
  final String coverUrl;

  /// 图片类型的主图地址。为空时回退到 [url]。
  final String imageUrl;

  /// 视频/直播/图片的描述文案。
  final String desc;

  /// 图片类型的标题（如宣传主题）。
  final String title;

  /// 图片/直播点击后的跳转地址（H5、落地页等）。
  final String actionUrl;

  final String authorName;
  final String authorAvatar;
  final String musicName;

  final int likeCount;
  final int commentCount;
  final int shareCount;

  /// 直播在线人数。
  final int viewerCount;

  /// 宽 / 高。服务端下发时可避免首帧布局抖动。
  final double aspectRatio;

  final bool liked;
  final bool followed;

  bool get isVideo => type == FeedItemType.video;
  bool get isLive => type == FeedItemType.live;
  bool get isImage => type == FeedItemType.image;

  /// 统一媒体地址：图片用 [imageUrl]，其余用 [url]。
  String get mediaUrl => isImage ? (imageUrl.isEmpty ? url : imageUrl) : url;

  /// 占位/封面地址：封面优先，其次媒体地址。
  String get posterUrl => coverUrl.isEmpty ? mediaUrl : coverUrl;

  FeedItem copyWith({
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? liked,
    bool? followed,
  }) {
    return FeedItem(
      id: id,
      type: type,
      url: url,
      coverUrl: coverUrl,
      imageUrl: imageUrl,
      desc: desc,
      title: title,
      actionUrl: actionUrl,
      authorName: authorName,
      authorAvatar: authorAvatar,
      musicName: musicName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewerCount: viewerCount,
      aspectRatio: aspectRatio,
      liked: liked ?? this.liked,
      followed: followed ?? this.followed,
    );
  }

  /// 后端字段类型经常不稳定（数字有时是 int，有时是字符串），
  /// 这里统一做容错，避免解析直接抛异常导致整页白屏。
  ///
  /// 类型判别：优先读 `type` 字段（video / live / image），缺省或无法识别按视频处理。
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final String rawType = _asString(json['type']).toLowerCase();
    final FeedItemType type;
    switch (rawType) {
      case 'live':
        type = FeedItemType.live;
      case 'image':
        type = FeedItemType.image;
      default:
        type = FeedItemType.video;
    }

    return FeedItem(
      id: _asString(json['id']),
      type: type,
      url: _asString(json['url']),
      coverUrl: _asString(json['coverUrl']),
      imageUrl: _asString(json['imageUrl']),
      desc: _asString(json['desc']),
      title: _asString(json['title']),
      actionUrl: _asString(json['actionUrl']),
      authorName: _asString(json['authorName']),
      authorAvatar: _asString(json['authorAvatar']),
      musicName: _asString(json['musicName']),
      likeCount: _asInt(json['likeCount']),
      commentCount: _asInt(json['commentCount']),
      shareCount: _asInt(json['shareCount']),
      viewerCount: _asInt(json['viewerCount']),
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
      identical(this, other) || (other is FeedItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 数量展示格式化：12345 -> 1.2w。
String formatCount(int count) {
  if (count < 10000) return '$count';
  return '${(count / 10000).toStringAsFixed(1)}w';
}
