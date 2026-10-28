import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 直播间入口胶囊：`▮▮▮ 点击进入直播间`。
///
/// 设计要点（对齐抖音/快手直播卡片的浮层形态）：
/// 1. 胶囊半透明深色底 + 细白描边，任何画面（白墙、户外强光）上文字都可读；
/// 2. 文字前的图标不是静态播放器，而是「音量条跳动」动画 ——
///    每根柱子有独立相位与振幅的正弦波动，比旋转/闪烁更像“正在直播”；
/// 3. 按下有轻微缩放 + 轻触觉反馈，点上去有“按到东西”的确定感；
/// 4. 离屏时（[animating] = false）停止动画，避免 PageView 预加载的相邻页空转耗电。
class LiveEntryCapsule extends StatefulWidget {
  const LiveEntryCapsule({
    super.key,
    this.label = '点击进入直播间',
    this.onTap,
    this.animating = true,
    this.barCount = 4,
  });

  /// 胶囊文案，默认「点击进入直播间」。
  final String label;

  final VoidCallback? onTap;

  /// 当前屏是否可见。不可见时停掉重复动画。
  final bool animating;

  /// 前置音量条数量。
  final int barCount;

  @override
  State<LiveEntryCapsule> createState() => _LiveEntryCapsuleState();
}

class _LiveEntryCapsuleState extends State<LiveEntryCapsule>
    with SingleTickerProviderStateMixin {
  /// 1200ms 一个循环：够慢，不抢视频的注意力；够快，能明显看出在“动”。
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.animating) _wave.repeat();
  }

  @override
  void didUpdateWidget(covariant LiveEntryCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!widget.animating && _wave.isAnimating) {
      _wave.stop();
      // 停的时候回落到静止帧，避免停在某个“跳动中”的高度看起来像卡住了。
      _wave.value = 0;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        // opaque：吃掉点击，避免穿透到下面整屏手势（直播里整屏单击也会进直播间，
        // 但两边都触发会重复 push 页面）。
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // 深色渐变而不是纯色：上浅下深，光感更像“浮在画面上”的玻璃。
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x73000000), Color(0x4D000000)],
              ),
              border: Border.all(color: const Color(0x4DFFFFFF), width: 0.8),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LiveWaveIcon(progress: _wave, barCount: widget.barCount),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    shadows: <Shadow>[
                      Shadow(color: Color(0x66000000), blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 直播“音量条”动画图标。
///
/// 用一根重复的 [Animation] 驱动 N 根柱子：每根柱子的高度 = 正弦波(进度 + 相位)，
/// 相位与振幅各不相同，于是看起来像一段随机跳动的音频波形，
/// 而实际上只有 1 个 AnimationController，开销极小。
class LiveWaveIcon extends StatelessWidget {
  const LiveWaveIcon({
    super.key,
    required this.progress,
    this.barCount = 4,
    this.height = 13,
    this.barWidth = 2.6,
    this.gap = 2.2,
    this.color = Colors.white,
  });

  /// 0 → 1 循环的动画进度，通常直接用 AnimationController。
  final Animation<double> progress;

  final int barCount;
  final double height;
  final double barWidth;
  final double gap;
  final Color color;

  /// 每根柱子的相位偏移（错开起跳时机）与相对振幅（高低错落）。
  static const List<double> _phases = <double>[0.0, 0.35, 0.62, 0.18, 0.48, 0.8];
  static const List<double> _amps = <double>[1.0, 0.62, 0.86, 0.55, 0.75, 0.92];

  @override
  Widget build(BuildContext context) {
    final int count = barCount < 1 ? 1 : barCount;
    return SizedBox(
      width: count * barWidth + (count - 1) * gap,
      height: height,
      child: AnimatedBuilder(
        animation: progress,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(count, (int i) {
              final double phase = _phases[i % _phases.length];
              final double amp = _amps[i % _amps.length];
              // 取模实现无缝循环：进度走到 1 时正好回到 0 的波形。
              final double t = (progress.value + phase) % 1.0;
              // 0 → 1 → 0 的余弦波，比线性往复更接近真实音量条。
              final double k = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
              final double h = height * (0.26 + 0.74 * amp * k);
              return Padding(
                padding: EdgeInsets.only(right: i == count - 1 ? 0 : gap),
                child: Container(
                  width: barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.65 + 0.35 * k),
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
