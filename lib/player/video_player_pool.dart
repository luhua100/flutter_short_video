import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 单个视频的加载状态。
enum VideoLoadStatus {
  /// 已创建但未开始加载。
  idle,

  /// 正在初始化 / 缓冲。
  loading,

  /// 已就绪，可以渲染首帧。
  ready,

  /// 加载失败，需要用户重试。
  failed,
}

/// 池中的一个播放单元。
///
/// 设计要点：
/// 1. 状态通过 [ChangeNotifier] 向外广播，UI 侧不再需要 FutureBuilder，
///    也不会出现旧实现里「播放回调中整页 setState」导致的每帧重建。
/// 2. 不持有任何 controller 监听器，进度监听交给 UI 侧的
///    ValueListenableBuilder，从根源上避免 dispose 后回调的崩溃与泄漏。
class VideoPlayerEntry extends ChangeNotifier {
  VideoPlayerEntry(this.url, {double volume = 0, this.live = false})
      : _volume = volume;

  final String url;

  /// 是否为直播流。直播流不支持 seek，[replay] 时只 play 不回到开头。
  bool live;

  VideoPlayerController? controller;

  VideoLoadStatus status = VideoLoadStatus.idle;

  Object? error;

  double _volume;

  bool _disposed = false;

  /// 防止快速滑动时同一个 entry 被并发初始化。
  Future<void>? _initializing;

  bool get isReady =>
      !_disposed && status == VideoLoadStatus.ready && controller != null;

  bool get isFailed => !_disposed && status == VideoLoadStatus.failed;

  double get volume => _volume;

  /// 初始化播放器。重复调用是安全的，失败后可再次调用实现重试。
  Future<void> ensureInitialized() {
    if (_disposed) return Future<void>.value();

    if (status == VideoLoadStatus.ready) return Future<void>.value();

    if (status == VideoLoadStatus.loading && _initializing != null) {
      return _initializing!;
    }

    // 失败重试：先清掉上一次的残留。
    if (status == VideoLoadStatus.failed) {
      status = VideoLoadStatus.idle;
      error = null;
      controller = null;
    }

    status = VideoLoadStatus.loading;
    error = null;
    _notify();

    final VideoPlayerController created = VideoPlayerController.network(
      url,
      // mixWithOthers：播放时不打断其他 App 的音频，
      // 配合默认静音策略，避免打开信息流就抢走音频焦点。
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    controller = created;

    final Future<void> task = _doInitialize(created);
    _initializing = task;
    return task;
  }

  Future<void> _doInitialize(VideoPlayerController created) async {
    try {
      await created.initialize();
      // 初始化过程中可能已经被滑走并释放。
      if (_disposed || !identical(controller, created)) {
        await created.dispose();
        return;
      }
      await created.setLooping(true);
      await created.setVolume(_volume);
      status = VideoLoadStatus.ready;
    } catch (e) {
      if (_disposed || !identical(controller, created)) {
        await created.dispose();
        return;
      }
      status = VideoLoadStatus.failed;
      error = e;
      controller = null;
      // 初始化失败的 controller 必须释放，否则 texture 一直被占用。
      await created.dispose();
    }
    _initializing = null;
    _notify();
  }

  Future<void> play() async {
    if (!isReady) return;
    try {
      await controller!.play();
    } catch (_) {
      // 播放调用在极端时序下可能抛异常，吞掉即可，不影响信息流。
    }
  }

  Future<void> pause() async {
    if (!isReady) return;
    try {
      await controller!.pause();
    } catch (_) {}
  }

  /// 回到开头播放，用于切屏复用同一个 controller。
  /// 直播流不支持 seek，只做 play。
  Future<void> replay() async {
    if (!isReady) return;
    try {
      if (!live) {
        await controller!.seekTo(Duration.zero);
      }
      await controller!.play();
    } catch (_) {}
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    if (isReady) {
      try {
        await controller!.setVolume(value);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    status = VideoLoadStatus.idle;
    controller?.dispose();
    controller = null;
    // ChangeNotifier 在 dispose 后不再通知，UI 侧用 ListenableBuilder 会自动解绑。
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}

/// 播放器池：负责 controller 复用、预加载与窗口外释放。
///
/// 短视频场景不能每屏都新建一个播放器：
/// - 播放器实例过多会打爆解码器，表现为黑屏或崩溃；
/// - 每屏都重新下载，二次进入必然转圈。
/// 这里用 LRU + 滑动窗口，把常驻实例控制在 [capacity] 以内。
class VideoPlayerPool {
  VideoPlayerPool({
    this.capacity = 4,
    double volume = 0,
  }) : _volume = volume;

  /// 同时持有的播放器上限，建议 3~5。
  final int capacity;

  double _volume;

  bool _disposed = false;

  /// key 为 url，按插入顺序维护 LRU（越靠前越久未使用）。
  final LinkedHashMap<String, VideoPlayerEntry> _entries =
      LinkedHashMap<String, VideoPlayerEntry>();

  bool get muted => _volume == 0;

  double get volume => _volume;

  /// 获取（或创建）url 对应的播放单元，同步返回，不阻塞首帧。
  /// [live] 为 true 时标记该单元为直播流（[replay] 不再 seek）。
  VideoPlayerEntry entryFor(String url, {bool live = false}) {
    assert(!_disposed, 'VideoPlayerPool 已释放');
    final VideoPlayerEntry? existing = _entries.remove(url);
    if (existing != null) {
      // 复用既有单元时同步 live 标记（同一 url 可能先按点播、后按直播复用）。
      if (existing.live != live) existing.live = live;
      _entries[url] = existing;
      return existing;
    }
    final VideoPlayerEntry entry =
        VideoPlayerEntry(url, volume: _volume, live: live);
    _entries[url] = entry;
    _enforceCapacity();
    return entry;
  }

  /// 预加载若干 url：初始化好并停在第一帧，等真正滑到时直接起播。
  void preload(Iterable<String> urls) {
    if (_disposed) return;
    for (final String url in urls) {
      if (url.isEmpty) continue;
      unawaited(entryFor(url).ensureInitialized());
    }
  }

  /// 只保留 [keep] 内的实例，其余释放。滑动过程中调用，控制内存与解码器占用。
  void retainOnly(Set<String> keep) {
    if (_disposed) return;
    final List<String> victims = _entries.keys.where((k) => !keep.contains(k)).toList();
    for (final String url in victims) {
      final VideoPlayerEntry? entry = _entries.remove(url);
      entry?.dispose();
    }
    _enforceCapacity();
  }

  /// 暂停全部（页面进入后台或切走时调用）。
  void pauseAll() {
    if (_disposed) return;
    for (final VideoPlayerEntry entry in _entries.values) {
      unawaited(entry.pause());
    }
  }

  /// 全局静音开关，短视频建议默认静音进入。
  Future<void> setMuted(bool muted) async {
    _volume = muted ? 0 : 1;
    for (final VideoPlayerEntry entry in _entries.values) {
      await entry.setVolume(_volume);
    }
  }

  void _enforceCapacity() {
    while (_entries.length > capacity) {
      final String oldest = _entries.keys.first;
      final VideoPlayerEntry? entry = _entries.remove(oldest);
      entry?.dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final VideoPlayerEntry entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
  }
}
