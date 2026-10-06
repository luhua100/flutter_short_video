import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_model.dart';
import '../player/video_player_pool.dart';
import 'video_progress_bar.dart';
import 'video_side_actions.dart';

/// 信息流中的一屏。
///
/// 与旧实现的差异（也是体验问题的主因）：
/// 1. 不再在播放回调里 setState 整屏，进度相关 UI 交给 ValueListenableBuilder；
/// 2. 首帧出画前显示封面，消除滑动后的黑屏；
/// 3. 有明确的加载失败态与重试入口，不再永远转圈；
/// 4. 布局基于安全区与约束，不再硬编码偏移量；
/// 5. 支持单击暂停、双击点赞、横拖进度。
class ShortVideoItem extends StatefulWidget {
  const ShortVideoItem({
    super.key,
    required this.video,
    required this.entry,
    required this.active,
    required this.muted,
    this.showLoadingMore = false,
    this.onLike,
    this.onDoubleLike,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onToggleMute,
  });

  final VideoModel video;

  /// 来自播放器池的复用单元，切屏不重新下载。
  final VideoPlayerEntry entry;

  /// 是否是当前可见的一屏。
  final bool active;

  final bool muted;
  final bool showLoadingMore;

  /// 点击右侧心形：切换点赞。
  final VoidCallback? onLike;

  /// 双击屏幕：只点赞，不取消。
  final VoidCallback? onDoubleLike;

  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;
  final ValueChanged<bool>? onToggleMute;

  @override
  State<ShortVideoItem> createState() => _ShortVideoItemState();
}

class _ShortVideoItemState extends State<ShortVideoItem> {
  /// 单击暂停需要等双击判定结束，否则双击点赞会顺带暂停视频。
  Timer? _tapTimer;

  final List<_HeartBurstData> _bursts = <_HeartBurstData>[];

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    widget.entry.addListener(_onEntryChanged);
    // 起播由页面层的播放窗口统一调度，这里只负责渲染与手势，
    // 避免出现两处同时 seek 造成的首帧回退。
  }

  @override
  void didUpdateWidget(covariant ShortVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      oldWidget.entry.removeListener(_onEntryChanged);
      widget.entry.addListener(_onEntryChanged);
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    widget.entry.removeListener(_onEntryChanged);
    super.dispose();
  }

  /// 注意这里移除的是同一个引用 —— 旧实现在 dispose 里传了一个新的匿名闭包，
  /// 导致监听器根本没被移除，dispose 后仍会回调 setState 而崩溃。
  void _onEntryChanged() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final VideoPlayerController? controller = widget.entry.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      unawaited(widget.entry.pause());
    } else {
      unawaited(widget.entry.play());
    }
    setState(() {});
  }

  void _handleTap() {
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) _togglePlay();
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    _tapTimer?.cancel();
    final Offset local = details.localPosition;
    final int id = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _bursts.add(_HeartBurstData(id: id, offset: local));
    });
    if (widget.onDoubleLike != null) {
      widget.onDoubleLike!();
    } else {
      widget.onLike?.call();
    }
  }

  void _removeBurst(int id) {
    if (!mounted) return;
    setState(() {
      _bursts.removeWhere((_HeartBurstData e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildVideoLayer(),
        _buildGradientScrim(),
        _buildGestureLayer(),
        _buildBottomInfo(bottomPadding),
        _buildSideActions(bottomPadding),
        _buildProgress(bottomPadding),
        _buildStatusLayer(),
        if (widget.showLoadingMore) _buildLoadingMore(bottomPadding),
        ..._bursts.map(
          (_HeartBurstData data) => _HeartBurst(
            key: ValueKey<int>(data.id),
            offset: data.offset,
            onCompleted: () => _removeBurst(data.id),
          ),
        ),
      ],
    );
  }

  /// 视频层：就绪前用封面占位，避免黑屏。
  Widget _buildVideoLayer() {
    final VideoPlayerEntry entry = widget.entry;
    if (entry.isReady) {
      final VideoPlayerController controller = entry.controller!;
      final Size size = controller.value.size;
      return AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 200),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            // 用视频真实像素尺寸，而不是写死 9:16，
            // 否则非竖屏素材会被裁切错位。
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF101010),
        child: widget.video.coverUrl.isEmpty
            ? null
            : Image.network(
                widget.video.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
      ),
    );
  }

  /// 上下渐变，保证白色文字在浅色画面上仍然可读。
  Widget _buildGradientScrim() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0x66000000),
              Colors.transparent,
              Colors.transparent,
              Color(0xB3000000),
            ],
            stops: <double>[0, 0.22, 0.62, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildGestureLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        onDoubleTapDown: _handleDoubleTap,
        onLongPress: () {},
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBottomInfo(double bottomPadding) {
    final VideoModel video = widget.video;
    return Positioned(
      left: 16,
      right: 84,
      bottom: bottomPadding + 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            video.authorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              video.desc,
              maxLines: _expanded ? 8 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.music_note, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  video.musicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideActions(double bottomPadding) {
    return Positioned(
      right: 10,
      bottom: bottomPadding + 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          VideoSideActions(
            video: widget.video,
            spinning: widget.active,
            onLike: widget.onLike ?? () {},
            onComment: widget.onComment ?? () {},
            onShare: widget.onShare ?? () {},
            onFollow: widget.onFollow ?? () {},
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => widget.onToggleMute?.call(!widget.muted),
            child: Icon(
              widget.muted ? Icons.volume_off : Icons.volume_up,
              size: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(double bottomPadding) {
    final VideoPlayerEntry entry = widget.entry;
    if (!entry.isReady) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPadding,
      child: VideoProgressBar(controller: entry.controller!),
    );
  }

  /// 加载中 / 失败态。旧实现把错误静默吞掉，用户只能看到无限转圈。
  Widget _buildStatusLayer() {
    final VideoPlayerEntry entry = widget.entry;
    if (entry.status == VideoLoadStatus.failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.white70, size: 36),
            const SizedBox(height: 8),
            const Text(
              '视频加载失败',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {});
                unawaited(entry.ensureInitialized().then((_) {
                  if (mounted && widget.active) {
                    unawaited(entry.replay());
                  }
                }));
              },
              child: const Text('点击重试'),
            ),
          ],
        ),
      );
    }

    if (entry.status == VideoLoadStatus.loading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingMore(double bottomPadding) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPadding + 8,
      child: const IgnorePointer(
        child: Center(
          child: Text(
            '正在加载更多…',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _HeartBurstData {
  _HeartBurstData({required this.id, required this.offset});

  final int id;
  final Offset offset;
}

/// 双击时在手指位置炸开的心形。
class _HeartBurst extends StatefulWidget {
  const _HeartBurst({
    super.key,
    required this.offset,
    required this.onCompleted,
  });

  final Offset offset;
  final VoidCallback onCompleted;

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.4, end: 1.15)
      .chain(CurveTween(curve: Curves.easeOutBack))
      .animate(_controller);
  late final Animation<double> _opacity =
      Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1, curve: Curves.easeOut),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx - 50,
      top: widget.offset.dy - 50,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: const Icon(
              Icons.favorite,
              size: 100,
              color: Color(0xFFFF2C55),
            ),
          ),
        ),
      ),
    );
  }
}
