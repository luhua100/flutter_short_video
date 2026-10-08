import 'package:flutter/material.dart';

import '../models/feed_item.dart';

/// 视频/直播/图片右侧共用的互动操作栏。
///
/// 这里所有元素都是无状态的展示 + 回调，交互状态由外层持有，
/// 避免点赞一个按钮导致整屏重建。
class VideoSideActions extends StatelessWidget {
  const VideoSideActions({
    super.key,
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
    this.spinning = false,
  });

  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onFollow;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _AvatarWithFollow(
          avatarUrl: item.authorAvatar,
          followed: item.followed,
          onFollow: onFollow,
        ),
        const SizedBox(height: 16),
        _LikeButton(
          count: item.likeCount,
          liked: item.liked,
          onTap: onLike,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.comment,
          label: formatCount(item.commentCount),
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.share,
          label: formatCount(item.shareCount),
          onTap: onShare,
        ),
        const SizedBox(height: 16),
        _SpinningDisc(coverUrl: item.coverUrl, spinning: spinning),
      ],
    );
  }
}

class _AvatarWithFollow extends StatelessWidget {
  const _AvatarWithFollow({
    required this.avatarUrl,
    required this.followed,
    required this.onFollow,
  });

  final String avatarUrl;
  final bool followed;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: Colors.white24,
            ),
            child: ClipOval(
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white70)
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      // 头像加载失败时不要抛异常堆栈，直接给占位。
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white70),
                    ),
            ),
          ),
          if (!followed)
            Positioned(
              bottom: -8,
              child: GestureDetector(
                onTap: onFollow,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2C55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  const _LikeButton({
    required this.count,
    required this.liked,
    required this.onTap,
  });

  final int count;
  final bool liked;
  final VoidCallback onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.35)
      .chain(CurveTween(curve: Curves.easeOutBack))
      .animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.liked ? const Color(0xFFFF2C55) : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ScaleTransition(
            scale: _scale,
            child: Icon(Icons.favorite, size: 34, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            formatCount(widget.count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 32, color: Colors.white, shadows: const <Shadow>[
            Shadow(blurRadius: 4, color: Colors.black54),
          ]),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}

/// 右下角唱片。仅在视频播放时旋转，暂停时停住，
/// 给用户一个「当前是否在播放」的隐性反馈。
class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({required this.coverUrl, required this.spinning});

  final String coverUrl;
  final bool spinning;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C2C2C),
          image: widget.coverUrl.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(widget.coverUrl),
                  fit: BoxFit.cover,
                  opacity: 0.85,
                ),
        ),
        child: const Icon(Icons.music_note, size: 18, color: Colors.white),
      ),
    );
  }
}
