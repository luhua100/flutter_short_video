import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../models/video_model.dart';
import 'favorites_feed_page.dart';
import 'favorites_list_page.dart';

/// 个人中心：从首页顶栏头像点进来。
///
/// 里面提供「我的收藏」入口，点击进入 [FavoritesListPage]（收藏列表页）。
/// 收藏列表页再点某条视频 → [FavoritesFeedPage]（全屏播放）。
///
/// 完整入口链：
/// 首页顶栏头像 → 个人中心 → 我的收藏 → 收藏列表 → 点某条 → 全屏播放。
class PersonalCenterPage extends StatefulWidget {
  const PersonalCenterPage({super.key, required this.repository});

  final VideoRepository repository;

  @override
  State<PersonalCenterPage> createState() => _PersonalCenterPageState();
}

class _PersonalCenterPageState extends State<PersonalCenterPage> {
  static const String _channel = '收藏';

  List<VideoModel> _favoritesPreview = <VideoModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreview());
  }

  Future<void> _loadPreview() async {
    try {
      // 取第一页前几条做预览，完整列表交给 FavoritesListPage 分页加载。
      final List<VideoModel> list = await widget.repository.fetchFeed(
        channel: _channel,
        page: 0,
      );
      if (!mounted) return;
      setState(() {
        _favoritesPreview = list.take(6).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openAllFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesListPage(repository: widget.repository),
      ),
    );
  }

  void _openPlayer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesFeedPage(
          initialItems: _favoritesPreview,
          initialIndex: index,
          channel: _channel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('个人中心',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          _buildProfileHeader(),
          const SizedBox(height: 8),
          _buildFavoritesSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 34,
            backgroundImage:
                NetworkImage('https://picsum.photos/seed/me_center/200/200'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('我的短视频账号',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('抖音风格 Demo · 记录生活',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: const <Widget>[
                    _StatItem(value: '128', label: '关注'),
                    SizedBox(width: 24),
                    _StatItem(value: '1.2w', label: '粉丝'),
                    SizedBox(width: 24),
                    _StatItem(value: '35.6w', label: '获赞'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              const Text('我的收藏',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: _openAllFavorites,
                child: const Row(
                  children: <Widget>[
                    Text('查看全部',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 13)),
                    Icon(Icons.chevron_right,
                        color: Colors.white60, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.66,
            ),
            itemCount: _favoritesPreview.length,
            itemBuilder: (BuildContext context, int index) {
              final VideoModel item = _favoritesPreview[index];
              return GestureDetector(
                onTap: () => _openPlayer(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.white10),
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_outline,
                          color: Colors.white54, size: 30),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
