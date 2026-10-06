import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 底部进度条。
///
/// 关键：用 [ValueListenableBuilder] 只重建这一个组件，
/// 而不是在播放回调里 setState 整屏（旧实现那样做会每帧重建整个 Stack，
/// 是滑动与播放卡顿的主要来源）。
class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar({
    super.key,
    required this.controller,
    this.activeHeight = 3,
    this.idleHeight = 1.5,
  });

  final VideoPlayerController controller;
  final double activeHeight;
  final double idleHeight;

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _dragging = false;
  double _dragValue = 0;

  void _onDragStart(double width, double current) {
    if (width <= 0) return;
    setState(() {
      _dragging = true;
      _dragValue = current;
    });
  }

  void _onDragUpdate(double delta, double width) {
    if (width <= 0) return;
    setState(() {
      _dragValue = (_dragValue + delta / width).clamp(0.0, 1.0);
    });
  }

  Future<void> _onDragEnd() async {
    final int totalMs = widget.controller.value.duration.inMilliseconds;
    if (totalMs > 0) {
      final Duration target =
          Duration(milliseconds: (_dragValue * totalMs).round());
      await widget.controller.seekTo(target);
    }
    if (!mounted) return;
    setState(() => _dragging = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: widget.controller,
          builder: (BuildContext context, VideoPlayerValue value, Widget? _) {
            final int totalMs = value.duration.inMilliseconds;
            final int posMs = value.position.inMilliseconds;
            final double progress = _dragging
                ? _dragValue
                : totalMs > 0
                    ? (posMs / totalMs).clamp(0.0, 1.0)
                    : 0.0;

            final double height = _dragging ? widget.activeHeight : widget.idleHeight;
            return SizedBox(
              width: width,
              height: 22,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => _onDragStart(width, progress),
                onHorizontalDragUpdate: (DragUpdateDetails details) =>
                    _onDragUpdate(details.primaryDelta ?? 0, width),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                child: Center(
                  child: Container(
                    width: width,
                    height: height,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: Container(
                      width: width * progress,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
