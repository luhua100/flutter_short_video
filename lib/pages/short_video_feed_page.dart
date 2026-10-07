import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../player/video_player_pool.dart';
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
                  onComment: _showCommentSheet,
                  onShare: _showShareSheet,
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

  void _showCommentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '评论区',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: 30,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white70),
                          ),
                          title: Text(
                            '用户 $index',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          subtitle: Text(
                            '这条评论来自第 $index 位观众',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.favorite_border,
                              size: 18, color: Colors.white54),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 230,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 14),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: <Widget>[
                    for (final String name in const <String>[
                      '微信',
                      '朋友圈',
                      'QQ',
                      '微博',
                      '私信',
                      '复制链接',
                      '收藏',
                      '举报',
                    ])
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFF2F2F2),
                            child: Text(
                              name.characters.first,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消',
                      style: TextStyle(fontSize: 15, color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
