// 纯逻辑单测，不依赖 Flutter 引擎，可以直接 `dart test` 运行，
// 便于在 CI 里做快速校验。
import 'package:test/test.dart';

import 'package:flutter_short_video/models/video_model.dart';

void main() {
  group('VideoModel', () {
    test('数量格式化', () {
      expect(formatCount(999), '999');
      expect(formatCount(10000), '1.0w');
      expect(formatCount(12345), '1.2w');
    });

    test('copyWith 只覆盖传入字段', () {
      const VideoModel origin = VideoModel(
        id: '1',
        url: 'https://example.com/a.mp4',
        coverUrl: 'https://example.com/a.jpg',
        desc: 'desc',
        likeCount: 10,
      );

      final VideoModel liked = origin.copyWith(liked: true, likeCount: 11);

      expect(liked.id, origin.id);
      expect(liked.url, origin.url);
      expect(liked.liked, isTrue);
      expect(liked.likeCount, 11);
    });

    test('fromJson 对缺失字段有兜底', () {
      final VideoModel model = VideoModel.fromJson(<String, dynamic>{
        'id': '2',
        'url': 'https://example.com/b.mp4',
        'likeCount': '12',
      });

      expect(model.id, '2');
      expect(model.likeCount, 12);
      expect(model.aspectRatio, 9 / 16);
      expect(model.liked, isFalse);
    });
  });
}
