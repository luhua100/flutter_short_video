import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../player/video_player_pool.dart';
import '../widgets/sheets.dart';
import 'feed_tab_view.dart';
import 'personal_center_page.dart';

/// 短视频首页：顶部关注 / 推荐两个频道，下方竖向信息流。
class ShortVideoFeedPage extends StatefulWidget {
  const ShortVideoFeedPage({super.key});

  @override
  State<ShortVideoFeedPage> createState() => _ShortVideoFeedPageState();
}

class _ShortVideoFeedPageState extends State<ShortVideoFeedPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<String> _tabs = <String>['关注', '推荐'];

  late final TabController _tabController;
  late final VideoPlayerPool _pool;
  late final VideoRepository _repository;

  int _activeTab = 1;

  /// 短视频默认静音进入，避免打开 App 就外放。
  bool _muted = true;

  int _resumeToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pool = VideoPlayerPool(capacity: 4, volume: 0);
    _repository = VideoRepository();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _activeTab,
    )..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.index == _activeTab) return;
    // 切频道先全部暂停，目标频道会在 didUpdateWidget 里重新起播。
    _pool.pauseAll();
    setState(() => _activeTab = _tabController.index);
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
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
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
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned.fill(
            child: TabBarView(
              controller: _tabController,
              // 横向切频道由 TabController 控制，禁止手势横滑，
              // 否则会和竖向滑视频抢手势。
              physics: const NeverScrollableScrollPhysics(),
              children: List<Widget>.generate(_tabs.length, (int i) {
                return FeedTabView(
                  key: ValueKey<String>(_tabs[i]),
                  channel: _tabs[i],
                  pool: _pool,
                  repository: _repository,
                  active: i == _activeTab,
                  muted: _muted,
                  resumeToken: _resumeToken,
                  onToggleMute: (bool value) => unawaited(_setMuted(value)),
                  onComment: () => showCommentSheet(context),
                  onShare: () => showShareSheet(context),
                );
              }),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _buildTopBar()),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          _buildProfileButton(),
          const SizedBox(width: 4),
          Expanded(child: _buildTabBar()),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: _openPersonalCenter,
      child: const CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage('https://picsum.photos/seed/me/100/100'),
      ),
    );
  }

  void _openPersonalCenter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PersonalCenterPage(repository: _repository),
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((String e) => Tab(text: e)).toList(),
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2.5,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }
}
