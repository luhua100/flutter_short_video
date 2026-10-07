import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../models/video_model.dart';
import '../player/video_player_pool.dart';
import 'feed_tab_view.dart';

/// 从「个人中心 - 收藏列表」点进来时的全屏播放页。
///
/// 与首页 [ShortVideoFeedPage] 的区别：
/// - 只一个频道（收藏），没有顶部 Tab；
/// - 支持从列表的任意位置进入（[initialIndex]），并用列表已加载的
///   [initialItems] 做种子数据，向上滑可回看、向下滑继续分页；
/// - 带返回按钮，出页时释放播放器池。
///
/// 收藏列表页这样跳转即可：
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => FavoritesFeedPage(
///     initialItems: favoritesList, // 列表内存里已分页加载的收藏视频
///     initialIndex: tappedIndex,   // 例如点的是第 6 条 → 5
///   ),
/// ));
/// ```
class FavoritesFeedPage extends StatefulWidget {
  const FavoritesFeedPage({
    super.key,
    required this.initialItems,
    this.initialIndex = 0,
    this.channel = '收藏',
  });

  /// 列表页已加载的收藏视频（分页累积的那一批）。
  final List<VideoModel> initialItems;

  /// 点击进入的视频下标（0 基）。
  final int initialIndex;

  /// 数据源频道名，真实接口据此路由到收藏列表接口。
  final String channel;

  @override
  State<FavoritesFeedPage> createState() => _FavoritesFeedPageState();
}

class _FavoritesFeedPageState extends State<FavoritesFeedPage>
    with WidgetsBindingObserver {
  late final VideoPlayerPool _pool;
  late final VideoRepository _repository;

  bool _muted = true;
  int _resumeToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pool = VideoPlayerPool(capacity: 4, volume: 0);
    _repository = VideoRepository();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _pool.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _resumeToken++);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pool.dispose();
    super.dispose();
  }

  Future<void> _setMuted(bool muted) async {
    await _pool.setMuted(muted);
    if (!mounted) return;
    setState(() => _muted = muted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FeedTabView(
              channel: widget.channel,
              pool: _pool,
              repository: _repository,
              active: true,
              muted: _muted,
              resumeToken: _resumeToken,
              initialIndex: widget.initialIndex,
              initialItems: widget.initialItems,
              onToggleMute: (bool value) => unawaited(_setMuted(value)),
              onComment: () {}, // TODO: 接入真实评论弹层
              onShare: () {}, // TODO: 接入真实分享弹层
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
