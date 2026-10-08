import '../models/feed_item.dart';

/// 视频数据源。真实项目里替换成自己的接口即可，
/// UI 层只依赖这个类，不关心数据从哪来。
class VideoRepository {
  VideoRepository({this.pageSize = 8});

  final int pageSize;

  /// 模拟后端返回的「单条内容」清单：每一条都是**完整**的 FeedItem 对象，
  /// 除视频外还包含直播（live，HLS 流 + 在线人数）与图片（image，宣传图 + 跳转）。
  /// 与真实接口「一个 JSON 对象包含内容全部字段、用 type 区分形态」的结构完全一致。
  /// 接入真实接口时，把这份清单换成网络返回的数组、直接 FeedItem.fromJson 即可，
  /// 无需改动任何字段拼接逻辑。
  static const List<Map<String, dynamic>> _mockFeed =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'video',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'coverUrl': 'https://picsum.photos/seed/blazes/540/960',
      'desc': '周末 citywalk 合集，治愈一整周的通勤 🌿',
      'authorName': '阿布在路上',
      'authorAvatar': 'https://picsum.photos/seed/avatar_abu/100/100',
      'musicName': '原声 - 阿布在路上',
      'likeCount': 128400,
      'commentCount': 3201,
      'shareCount': 540,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'live',
      'url': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      'coverUrl': 'https://picsum.photos/seed/live_1/540/960',
      'desc': '正在直播：环球影城全天逛吃打卡',
      'authorName': '玩乐日记',
      'authorAvatar': 'https://picsum.photos/seed/avatar_live/100/100',
      'musicName': '直播中 · 原声',
      'likeCount': 89200,
      'commentCount': 1543,
      'shareCount': 1203,
      'viewerCount': 13400,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'image',
      'imageUrl': 'https://picsum.photos/seed/promo_1/540/960',
      'title': '618 大促 · 至高省 2000',
      'actionUrl': 'https://example.com/promo/618',
      'desc': '点开领取你的专属优惠券，先到先得 >>>',
      'authorName': '官方活动号',
      'authorAvatar': 'https://picsum.photos/seed/avatar_promo/100/100',
      'musicName': '',
      'likeCount': 256000,
      'commentCount': 8900,
      'shareCount': 4300,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'video',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'coverUrl': 'https://picsum.photos/seed/escapes/540/960',
      'desc': '三分钟看懂宇宙的尺度，震撼到说不出话',
      'authorName': '星河观测站',
      'authorAvatar': 'https://picsum.photos/seed/avatar_star/100/100',
      'musicName': 'Interstellar · Hans Zimmer',
      'likeCount': 89200,
      'commentCount': 1543,
      'shareCount': 1203,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'live',
      'url': 'https://test-streams.mux.dev/pts_shift/master.m3u8',
      'coverUrl': 'https://picsum.photos/seed/live_2/540/960',
      'desc': '正在直播：深夜电台，点歌送祝福',
      'authorName': '城市夜未眠',
      'authorAvatar': 'https://picsum.photos/seed/avatar_night/100/100',
      'musicName': '直播中 · 原声',
      'likeCount': 64500,
      'commentCount': 980,
      'shareCount': 760,
      'viewerCount': 8200,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'image',
      'imageUrl': 'https://picsum.photos/seed/promo_2/540/960',
      'title': '新店开业 · 第二杯半价',
      'actionUrl': 'https://example.com/promo/newshop',
      'desc': '收藏本店，到店出示即可享专属福利～',
      'authorName': '本地生活',
      'authorAvatar': 'https://picsum.photos/seed/avatar_local/100/100',
      'musicName': '',
      'likeCount': 173800,
      'commentCount': 5200,
      'shareCount': 2100,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'video',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'coverUrl': 'https://picsum.photos/seed/fun/540/960',
      'desc': '猫咪的迷惑行为大赏，笑到邻居来敲门',
      'authorName': '橘座本座',
      'authorAvatar': 'https://picsum.photos/seed/avatar_cat/100/100',
      'musicName': '快乐崇拜 · 温岚',
      'likeCount': 256000,
      'commentCount': 8900,
      'shareCount': 4300,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'live',
      'url': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      'coverUrl': 'https://picsum.photos/seed/live_3/540/960',
      'desc': '正在直播：健身房公开训练课',
      'authorName': '撸铁不打烊',
      'authorAvatar': 'https://picsum.photos/seed/avatar_gym/100/100',
      'musicName': '直播中 · 原声',
      'likeCount': 54300,
      'commentCount': 760,
      'shareCount': 430,
      'viewerCount': 5100,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'image',
      'imageUrl': 'https://picsum.photos/seed/promo_3/540/960',
      'title': '周年庆 · 抽免单',
      'actionUrl': 'https://example.com/promo/anniv',
      'desc': '转发活动页并@三位好友，即有机会免单！',
      'authorName': '会员中心',
      'authorAvatar': 'https://picsum.photos/seed/avatar_vip/100/100',
      'musicName': '',
      'likeCount': 134500,
      'commentCount': 4400,
      'shareCount': 3300,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'type': 'video',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      'coverUrl': 'https://picsum.photos/seed/joyrides/540/960',
      'desc': '骑行川西小环线，每一帧都是壁纸',
      'authorName': '风一样自由',
      'authorAvatar': 'https://picsum.photos/seed/avatar_wind/100/100',
      'musicName': '原声 - 风一样自由',
      'likeCount': 64500,
      'commentCount': 980,
      'shareCount': 760,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
  ];

  /// 拉取一页数据。page 从 0 开始。
  ///
  /// [salt] 用于下拉刷新时换一批不同的内容，
  /// 否则刷新回来的数据和原来一模一样，用户会以为没生效。
  ///
  /// 返回的内容可能混合视频 / 直播 / 图片，由调用方按 [FeedItem.type] 分别渲染。
  Future<List<FeedItem>> fetchFeed({
    required String channel,
    required int page,
    int salt = 0,
  }) async {
    // 模拟网络耗时。
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return List<FeedItem>.generate(pageSize, (int i) {
      final int seed = salt * 1000 + page * pageSize + i;
      final Map<String, dynamic> raw = _mockFeed[seed % _mockFeed.length];
      // id 仅作为列表内的唯一 key 合成（channel + 序号）；
      // 其余字段全部来自 _mockFeed 这份 JSON，代码中不再硬编码任何内容字段。
      // 接入真实接口时，把 _mockFeed 换成网络返回的数组，直接 FeedItem.fromJson 即可。
      final Map<String, dynamic> json = <String, dynamic>{
        'id': '${channel}_$seed',
        ...raw,
      };
      return FeedItem.fromJson(json);
    });
  }
}
