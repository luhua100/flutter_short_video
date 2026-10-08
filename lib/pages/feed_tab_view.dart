import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../models/feed_item.dart';
import '../player/video_player_pool.dart';
import '../utils/logger.dart';
import '../widgets/image_feed_item.dart';
import '../widgets/short_video_item.dart';
import 'live_page.dart';

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
    this.initialIndex = 0,
    this.initialItems = const <FeedItem>[],
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

  /// 进入信息流时定位到的视频下标。
  /// 例如从「个人中心-收藏列表」第 6 条点进来，这里传 5（0 基）。
  /// 默认 0：从首页信息流进入时无需传。
  final int initialIndex;

  /// 进入时已经分页加载好的视频列表（收藏列表内存里已有的那一批）。
  /// 传入后信息流直接以这些为初始数据并定位到 [initialIndex]：
  /// - 向上滑可回看前面的视频（数据已在内存，无需重新请求）；
  /// - 向下滑继续分页加载更多（[VideoRepository.fetchFeed] 按 page 递增）。
  /// 不传则走首页逻辑：从 page 0 拉取。
  final List<FeedItem> initialItems;

  final ValueChanged<bool>? onToggleMute;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<FeedTabView> createState() => FeedTabViewState();
}

class FeedTabViewState extends State<FeedTabView>
    with AutomaticKeepAliveClientMixin {
  final List<FeedItem> _items = <FeedItem>[];

  late final PageController _pageController;

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
    // 从收藏列表等入口进入时，PageController 要直接定位到点击的那一条。
    _pageController = PageController(initialPage: widget.initialIndex);

    if (widget.initialItems.isNotEmpty) {
      // 用列表页已加载好的数据做种子：向上滑可回看，向下滑继续分页。
      _items.addAll(widget.initialItems);
      // 已加载页数 = 数据条数 / 每页条数 - 1（假设列表按整页加载）。
      _page = (widget.initialItems.length ~/ widget.repository.pageSize) - 1;
      if (_page < 0) _page = 0;
      _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
      _firstLoading = false;
      _syncPlayback(resume: true);
    } else {
      unawaited(_loadFirstPage());
    }
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
      final List<FeedItem> list = await widget.repository.fetchFeed(
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
    final List<FeedItem> list = await widget.repository.fetchFeed(
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
      final List<FeedItem> list = await widget.repository.fetchFeed(
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
    if (index >= 0 && index < _items.length) {
      // 划到某一条即视为一次曝光，便于做完播/停留埋点。
      logEvent('feed_item_impression', _trackParams(_items[index], index));
    }
    _syncPlayback(resume: true);
    if (index >= _items.length - 3) {
      unawaited(_loadMore());
    }
  }

  /// 构造埋点公共参数：item 维度 + 频道/下标/页码。
  Map<String, dynamic> _trackParams(FeedItem item, int index) =>
      <String, dynamic>{
        'item_id': item.id,
        'type': item.type.name,
        'channel': widget.channel,
        'index': index,
        'page': _page,
      };

  /// 维护播放窗口：当前屏起播，前后各预加载一屏，窗口外释放。
  /// 图片类型没有播放器，直接跳过；直播用 play() 而非 seek 到开头的 replay()。
  void _syncPlayback({bool resume = false}) {
    if (_items.isEmpty || !widget.active) return;
    final int index = _currentIndex.clamp(0, _items.length - 1);

    final Set<String> keep = <String>{};
    final List<String> preload = <String>[];
    for (int i = index - 1; i <= index + 1; i++) {
      if (i < 0 || i >= _items.length) continue;
      final FeedItem item = _items[i];
      if (item.isImage) continue; // 图片无播放器，不占用播放窗口。
      keep.add(item.url);
      if (i != index) preload.add(item.url);
    }
    widget.pool.retainOnly(keep);
    widget.pool.preload(preload);

    final FeedItem current = _items[index];
    if (current.isImage) return; // 图片：无需起播。

    final VideoPlayerEntry entry =
        widget.pool.entryFor(current.url, live: current.isLive);
    unawaited(
      entry.ensureInitialized().then((_) {
        if (!mounted || !widget.active || _currentIndex != index) return;
        if (resume) {
          // 直播不支持 seek，只 play；点播则回到开头重新播放。
          unawaited(current.isLive ? entry.play() : entry.replay());
        }
      }),
    );
  }

  void _toggleLike(int index) {
    final FeedItem v = _items[index];
    final bool nextLiked = !v.liked;
    _items[index] = v.copyWith(
      liked: nextLiked,
      likeCount: v.likeCount + (v.liked ? -1 : 1),
    );
    logEvent('like_toggle', <String, dynamic>{
      ..._trackParams(v, index),
      'liked': nextLiked,
    });
    setState(() {});
  }

  void _doubleTapLike(int index) {
    final FeedItem v = _items[index];
    if (v.liked) return; // 双击只点赞，不取消。
    _items[index] = v.copyWith(liked: true, likeCount: v.likeCount + 1);
    logEvent('like_double', _trackParams(v, index));
    setState(() {});
  }

  void _toggleFollow(int index) {
    final FeedItem v = _items[index];
    final bool nextFollowed = !v.followed;
    _items[index] = v.copyWith(followed: nextFollowed);
    logEvent('follow_toggle', <String, dynamic>{
      ..._trackParams(v, index),
      'followed': nextFollowed,
    });
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
          final FeedItem item = _items[index];
          final bool isCurrent = widget.active && index == _currentIndex;

          // 评论 / 分享 / 查看详情：统一在此埋点，再转交上层回调。
          void onComment() {
            logEvent('comment_click', _trackParams(item, index));
            widget.onComment?.call();
          }

          void onShare() {
            logEvent('share_click', _trackParams(item, index));
            widget.onShare?.call();
          }

          void onAction() {
            logEvent('image_detail_click', <String, dynamic>{
              ..._trackParams(item, index),
              'action_url': item.actionUrl,
            });
            widget.onShare?.call();
          }

          // 图片类型：无播放器，走独立的全屏图片渲染。
          // 整屏单击仅埋点，不进入详情页。
          if (item.isImage) {
            return ImageFeedItem(
              key: ValueKey<String>(item.id),
              item: item,
              active: isCurrent,
              onLike: () => _toggleLike(index),
              onDoubleLike: () => _doubleTapLike(index),
              onFollow: () => _toggleFollow(index),
              onComment: onComment,
              onShare: onShare,
              onAction: onAction,
              onCellTap: () {
                logEvent('image_cell_click', _trackParams(item, index));
              },
            );
          }

          // 直播：整屏单击进入直播页（占位页，仅返回按钮）。
          void onOpenLive() {
            logEvent('live_cell_click', _trackParams(item, index));
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LivePage(item: item),
                ),
              ),
            );
          }

          // 视频 / 直播：共用播放器组件，直播额外标记 live 以隐藏进度条。
          // 视频单击=暂停/播放；直播单击=进入直播页。
          return ShortVideoItem(
            key: ValueKey<String>(item.id),
            item: item,
            entry: widget.pool.entryFor(item.url, live: item.isLive),
            active: isCurrent,
            muted: widget.muted,
            showLoadingMore: _loadingMore && index == _items.length - 1,
            onLike: () => _toggleLike(index),
            onDoubleLike: () => _doubleTapLike(index),
            onFollow: () => _toggleFollow(index),
            onComment: onComment,
            onShare: onShare,
            onToggleMute: widget.onToggleMute,
            onOpenLive: item.isLive ? onOpenLive : null,
          );
        },
      ),
    );
  }
}
