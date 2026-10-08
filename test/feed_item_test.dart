// 纯逻辑单测，不依赖 Flutter 引擎，可以直接 `dart test` 运行，
// 便于在 CI 里做快速校验。
import 'package:test/test.dart';

import 'package:flutter_short_video/models/feed_item.dart';

void main() {
  group('FeedItem', () {
    test('数量格式化', () {
      expect(formatCount(999), '999');
      expect(formatCount(10000), '1.0w');
      expect(formatCount(12345), '1.2w');
    });

    test('copyWith 只覆盖传入字段', () {
      const FeedItem origin = FeedItem(
        id: '1',
        type: FeedItemType.video,
        url: 'https://example.com/a.mp4',
        coverUrl: 'https://example.com/a.jpg',
        desc: 'desc',
        likeCount: 10,
      );

      final FeedItem liked = origin.copyWith(liked: true, likeCount: 11);

      expect(liked.id, origin.id);
      expect(liked.url, origin.url);
      expect(liked.liked, isTrue);
      expect(liked.likeCount, 11);
    });

    test('fromJson 按 type 区分视频/直播/图片', () {
      final FeedItem video = FeedItem.fromJson(<String, dynamic>{
        'id': 'v1',
        'type': 'video',
        'url': 'https://example.com/b.mp4',
        'likeCount': '12',
      });
      expect(video.type, FeedItemType.video);
      expect(video.isVideo, isTrue);
      expect(video.likeCount, 12);
      expect(video.aspectRatio, 9 / 16);

      final FeedItem live = FeedItem.fromJson(<String, dynamic>{
        'id': 'l1',
        'type': 'live',
        'url': 'https://example.com/live.m3u8',
        'viewerCount': 8800,
      });
      expect(live.isLive, isTrue);
      expect(live.viewerCount, 8800);

      final FeedItem image = FeedItem.fromJson(<String, dynamic>{
        'id': 'i1',
        'type': 'image',
        'imageUrl': 'https://example.com/poster.jpg',
        'title': '活动',
        'actionUrl': 'https://example.com/act',
      });
      expect(image.isImage, isTrue);
      // 图片的媒体地址回退到 imageUrl。
      expect(image.mediaUrl, 'https://example.com/poster.jpg');
    });

    test('未知 type 缺省按视频处理', () {
      final FeedItem fallback = FeedItem.fromJson(<String, dynamic>{
        'id': 'x1',
        'url': 'https://example.com/x.mp4',
      });
      expect(fallback.type, FeedItemType.video);
    });

    test('posterUrl 封面优先，其次媒体地址', () {
      final FeedItem withCover = FeedItem(
        id: 'c',
        type: FeedItemType.video,
        url: 'https://example.com/v.mp4',
        coverUrl: 'https://example.com/cover.jpg',
      );
      expect(withCover.posterUrl, 'https://example.com/cover.jpg');

      final FeedItem noCover = FeedItem(
        id: 'n',
        type: FeedItemType.video,
        url: 'https://example.com/v.mp4',
      );
      expect(noCover.posterUrl, 'https://example.com/v.mp4');
    });
  });
}
