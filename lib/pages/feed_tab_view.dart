import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../models/video_model.dart';
import '../player/video_player_pool.dart';
import '../widgets/short_video_item.dart';

/// 单个频道（关注 / 推荐）的信息流。
///
/// 这里是体验优化最集中的地方：
/// - 每个频道持有独立的 [PageController]（旧实现两个频道共用一个，会互相串位置）；
/// - 滑动时预加载前后各一屏，并释放窗口外的播放器；
/// - 距离末尾还有 3 屏时就开始加载更多，而不是滑到底才请求；
/// - 下拉刷新替换整页数据并回到第一屏（旧实现既不 setState 也刷错了列表）。
class FeedTabView extends StatefulWidget {
  const FeedTabView({
    super.key,
    required this.channel,
    required this.pool,
    required this.repository,
    required this.active,
    required this.muted,
    required this.resumeToken,
    this.onToggleMute,
    this.onComment,
    this.onShare,
  });

  final String channel;
  final VideoPlayerPool pool;
  final VideoRepository repository;

  /// 当前频道是否可见，不可见时暂停播放。
  final bool active;
  final bool muted;

  /// 由父层在 App 回到前台时递增，用于恢复播放。
  final int resumeToken;

  final ValueChanged<bool>? onToggleMute;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<FeedTabView> createState() => FeedTabViewState();
}

class FeedTabViewState extends State<FeedTabView>
    with AutomaticKeepAliveClientMixin {
  final List<VideoModel> _items = <VideoModel>[];

  late final PageController _pageController = PageController();

  int _currentIndex = 0;
  int _page = 0;
  int _salt = 0;

  bool _firstLoading = true;
  bool _loadingMore = false;
  String? _firstError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFirstPage());
  }

  @override
  void didUpdateWidget(covariant FeedTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _syncPlayback(resume: true);
      } else {
        widget.pool.pauseAll();
      }
    }
    if (oldWidget.resumeToken != widget.resumeToken && widget.active) {
      _syncPlayback(resume: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _firstLoading = true;
      _firstError = null;
    });
    try {
      final List<VideoModel> list = await widget.repository.fetchFeed(
        channel: widget.channel,
        page: 0,
        salt: _salt,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _page = 0;
        _currentIndex = 0;
        _firstLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPlayback(resume: true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _firstLoading = false;
        _firstError = '$e';
      });
    }
  }

  /// 下拉刷新：换一批数据并回到第一屏。
  Future<void> onRefresh() async {
    if (_pageController.hasClients && (_pageController.page ?? 0) > 0.5) {
      // 只在第一屏响应下拉，避免滑动过程中误触发。
      return;
    }
    _salt++;
    final List<VideoModel> list = await widget.repository.fetchFeed(
      channel: widget.channel,
      page: 0,
      salt: _salt,
    );
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(list);
      _page = 0;
      _currentIndex = 0;
    });
    if (_pageController.hasClients && _pageController.page != 0) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
    _syncPlayback(resume: true);
  }

  /// 提前 3 屏触发，避免滑到底才请求导致空等。
  Future<void> _loadMore() async {
    if (_loadingMore || _firstLoading) return;
    setState(() => _loadingMore = true);
    try {
      final List<VideoModel> list = await widget.repository.fetchFeed(
        channel: widget.channel,
        page: _page + 1,
        salt: _salt,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _items.addAll(list);
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _syncPlayback(resume: true);
    if (index >= _items.length - 3) {
      unawaited(_loadMore());
    }
  }

  /// 维护播放窗口：当前屏起播，前后各预加载一屏，窗口外释放。
  void _syncPlayback({bool resume = false}) {
    if (_items.isEmpty || !widget.active) return;
    final int index = _currentIndex.clamp(0, _items.length - 1);

    final Set<String> keep = <String>{};
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < _items.length) keep.add(_items[i].url);
    }
    widget.pool.retainOnly(keep);

    final List<String> preload = <String>[];
    if (index + 1 < _items.length) preload.add(_items[index + 1].url);
    if (index - 1 >= 0) preload.add(_items[index - 1].url);
    widget.pool.preload(preload);

    final VideoPlayerEntry entry = widget.pool.entryFor(_items[index].url);
    unawaited(
      entry.ensureInitialized().then((_) {
        if (!mounted || !widget.active || _currentIndex != index) return;
        if (resume) unawaited(entry.replay());
      }),
    );
  }

  void _toggleLike(int index) {
    final VideoModel v = _items[index];
    _items[index] = v.copyWith(
      liked: !v.liked,
      likeCount: v.likeCount + (v.liked ? -1 : 1),
    );
    setState(() {});
  }

  void _doubleTapLike(int index) {
    final VideoModel v = _items[index];
    if (v.liked) return; // 双击只点赞，不取消。
    _items[index] = v.copyWith(liked: true, likeCount: v.likeCount + 1);
    setState(() {});
  }

  void _toggleFollow(int index) {
    final VideoModel v = _items[index];
    _items[index] = v.copyWith(followed: !v.followed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_firstLoading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }

    if (_firstError != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.white70, size: 36),
              const SizedBox(height: 10),
              const Text(
                '加载失败，请检查网络',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: _loadFirstPage,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black87,
      onRefresh: onRefresh,
      child: PageView.builder(
        key: PageStorageKey<String>('feed_${widget.channel}'),
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (BuildContext context, int index) {
          final VideoModel video = _items[index];
          return ShortVideoItem(
            key: ValueKey<String>(video.id),
            video: video,
            entry: widget.pool.entryFor(video.url),
            active: widget.active && index == _currentIndex,
            muted: widget.muted,
            showLoadingMore: _loadingMore && index == _items.length - 1,
            onLike: () => _toggleLike(index),
            onDoubleLike: () => _doubleTapLike(index),
            onFollow: () => _toggleFollow(index),
            onComment: widget.onComment,
            onShare: widget.onShare,
            onToggleMute: widget.onToggleMute,
          );
        },
      ),
    );
  }
}
