import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import '../utils/logger.dart';
import 'video_side_actions.dart';

/// 信息流中的「图片 / 宣传图」一屏。
///
/// 与视频/直播不同，图片没有播放器，因此：
/// - 整屏展示 [FeedItem.posterUrl]，无进度条、无播放/暂停手势；
/// - 复用了右侧互动栏（点赞/评论/分享/关注）与底部文案；
/// - 支持 [FeedItem.actionUrl] 驱动的「查看详情」入口（落地页 / H5 / 活动页等）；
/// - 双击图片点赞，与视频双击体验保持一致。
class ImageFeedItem extends StatefulWidget {
  const ImageFeedItem({
    super.key,
    required this.item,
    required this.active,
    this.onLike,
    this.onDoubleLike,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onAction,
    this.onCellTap,
  });

  final FeedItem item;
  final bool active;

  final VoidCallback? onLike;
  final VoidCallback? onDoubleLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;

  /// 点击「查看详情」时触发，一般带用户跳转到活动/商品/H5 页。
  final VoidCallback? onAction;

  /// 单击整张图片（非双击）：当前仅用于埋点，不进入详情页。
  final VoidCallback? onCellTap;

  @override
  State<ImageFeedItem> createState() => _ImageFeedItemState();
}

class _ImageFeedItemState extends State<ImageFeedItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildImageLayer(),
        _buildGradientScrim(),
        _buildGestureLayer(),
        _buildBottomInfo(bottomPadding),
        _buildSideActions(bottomPadding),
      ],
    );
  }

  Widget _buildImageLayer() {
    final String url = widget.item.posterUrl;
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFF101010));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFF101010),
          child: Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        );
      },
      errorBuilder: (BuildContext context, Object error, _) =>
          const ColoredBox(
        color: Color(0xFF101010),
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
        ),
      ),
    );
  }

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
        onTap: widget.onCellTap,
        onDoubleTap: () {
          if (widget.onDoubleLike != null) {
            widget.onDoubleLike!();
          } else {
            widget.onLike?.call();
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBottomInfo(double bottomPadding) {
    final FeedItem item = widget.item;
    return Positioned(
      left: 16,
      right: 84,
      bottom: bottomPadding + 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.authorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 6),
          if (item.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD66B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: <Shadow>[Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              logEvent('desc_toggle', <String, dynamic>{
                'item_id': widget.item.id,
                'expanded': _expanded,
              });
            },
            child: Text(
              item.desc,
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
          if (item.actionUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: widget.onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2C55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '查看详情 ›',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
            item: widget.item,
            spinning: false,
            onLike: widget.onLike ?? () {},
            onComment: widget.onComment ?? () {},
            onShare: widget.onShare ?? () {},
            onFollow: widget.onFollow ?? () {},
          ),
        ],
      ),
    );
  }
}
