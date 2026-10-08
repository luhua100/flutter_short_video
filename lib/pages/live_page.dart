import 'package:flutter/material.dart';

import '../models/feed_item.dart';

/// 直播详情页（占位）。
///
/// 信息流里直播类 item 点击整屏后会进入这里。当前为占位实现：
/// 仅提供顶部返回按钮与基础展示，真实的直播播放、聊天、礼物等能力后续接入。
class LivePage extends StatelessWidget {
  const LivePage({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2C55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.live_tv, size: 12, color: Colors.white),
                  SizedBox(width: 3),
                  Text('直播中',
                      style:
                          TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: isLandscape ? 0 : 180,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(12),
                image: item.posterUrl.isEmpty
                    ? null
                    : DecorationImage(
                        image: NetworkImage(item.posterUrl),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.live_tv, size: 72, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              '直播页面（占位）',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              '在线观众 ${formatCount(item.viewerCount)}',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
