import '../models/video_model.dart';

/// 视频数据源。真实项目里替换成自己的接口即可，
/// UI 层只依赖这个类，不关心数据从哪来。
class VideoRepository {
  VideoRepository({this.pageSize = 8});

  final int pageSize;

  /// 模拟后端返回的「单条视频」清单：每一条都是**完整**的视频对象，
  /// url / coverUrl / 描述 / 作者 / 音乐 / 各项计数 / 宽高比全部写在这份 JSON 里，
  /// 与真实接口「一个 JSON 对象包含视频全部字段」的结构完全一致。
  /// 接入真实接口时，把这份清单换成网络返回的数组、直接 VideoModel.fromJson 即可，
  /// 无需改动任何字段拼接逻辑。
  static const List<Map<String, dynamic>> _mockFeed =
      <Map<String, dynamic>>[
    <String, dynamic>{
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
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      'coverUrl': 'https://picsum.photos/seed/meltdowns/540/960',
      'desc': '深夜放毒：十分钟搞定一桌硬菜',
      'authorName': '厨房小白变大神',
      'authorAvatar': 'https://picsum.photos/seed/avatar_food/100/100',
      'musicName': 'Riding Elevator · 纯音乐',
      'likeCount': 173800,
      'commentCount': 5200,
      'shareCount': 2100,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      'coverUrl': 'https://picsum.photos/seed/sintel/540/960',
      'desc': '独立动画短片，看完沉默了很久',
      'authorName': '光影手记',
      'authorAvatar': 'https://picsum.photos/seed/avatar_film/100/100',
      'musicName': 'Sintel Theme · 纯音乐',
      'likeCount': 98700,
      'commentCount': 2300,
      'shareCount': 1500,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      'coverUrl': 'https://picsum.photos/seed/tears/540/960',
      'desc': '科幻迷必看，开源电影的天花板',
      'authorName': '硬核电影控',
      'authorAvatar': 'https://picsum.photos/seed/avatar_scifi/100/100',
      'musicName': 'Tears of Steel · 原声',
      'likeCount': 54300,
      'commentCount': 760,
      'shareCount': 430,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
      'coverUrl': 'https://picsum.photos/seed/gti/540/960',
      'desc': '提车一个月真实测评，优缺点全说',
      'authorName': '老司机侃车',
      'authorAvatar': 'https://picsum.photos/seed/avatar_car/100/100',
      'musicName': '原声 - 老司机侃车',
      'likeCount': 76200,
      'commentCount': 3100,
      'shareCount': 890,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
      'coverUrl': 'https://picsum.photos/seed/bullrun/540/960',
      'desc': '超跑集结，发动机的声浪太上头',
      'authorName': '速度与激情日常',
      'authorAvatar': 'https://picsum.photos/seed/avatar_speed/100/100',
      'musicName': 'Gasoline · 纯音乐',
      'likeCount': 134500,
      'commentCount': 4400,
      'shareCount': 3300,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
    <String, dynamic>{
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
      'coverUrl': 'https://picsum.photos/seed/grand/540/960',
      'desc': '一万块能买到什么车？答案超出预期',
      'authorName': '二手车探长',
      'authorAvatar': 'https://picsum.photos/seed/avatar_used/100/100',
      'musicName': '原声 - 二手车探长',
      'likeCount': 45900,
      'commentCount': 2100,
      'shareCount': 670,
      'aspectRatio': 0.5625,
      'liked': false,
      'followed': false,
    },
  ];

  /// 拉取一页数据。page 从 0 开始。
  ///
  /// [salt] 用于下拉刷新时换一批不同的内容，
  /// 否则刷新回来的数据和原来一模一样，用户会以为没生效。
  Future<List<VideoModel>> fetchFeed({
    required String channel,
    required int page,
    int salt = 0,
  }) async {
    // 模拟网络耗时。
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return List<VideoModel>.generate(pageSize, (int i) {
      final int seed = salt * 1000 + page * pageSize + i;
      final Map<String, dynamic> raw = _mockFeed[seed % _mockFeed.length];
      // id 仅作为列表内的唯一 key 合成（channel + 序号）；
      // 其余字段全部来自 _mockFeed 这份 JSON，代码中不再硬编码任何内容字段。
      // 接入真实接口时，把 _mockFeed 换成网络返回的数组，直接 VideoModel.fromJson 即可。
      final Map<String, dynamic> json = <String, dynamic>{
        'id': '${channel}_$seed',
        ...raw,
      };
      return VideoModel.fromJson(json);
    });
  }
}
