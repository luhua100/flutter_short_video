import 'dart:math';

import '../models/video_model.dart';

/// 视频数据源。真实项目里替换成自己的接口即可，
/// UI 层只依赖这个类，不关心数据从哪来。
class VideoRepository {
  VideoRepository({this.pageSize = 8});

  final int pageSize;

  final Random _random = Random();

  static const List<String> _videoUrls = <String>[
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
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
      final String url = _videoUrls[seed % _videoUrls.length];
      return VideoModel(
        id: '${channel}_$seed',
        url: url,
        // 封面先用占位图服务，正式环境换成服务端下发的首帧图。
        coverUrl: 'https://picsum.photos/seed/$seed/540/960',
        desc: '[$channel] 第 $seed 条视频 · 这里是视频描述文案，'
            '支持话题与 @好友，超过两行自动折叠。',
        authorName: '@作者$seed',
        authorAvatar: 'https://picsum.photos/seed/avatar$seed/100/100',
        musicName: '原声 - 作者$seed',
        likeCount: 1000 + _random.nextInt(99000),
        commentCount: 100 + _random.nextInt(9900),
        shareCount: 10 + _random.nextInt(9900),
        aspectRatio: 16 / 9,
      );
    });
  }
}
