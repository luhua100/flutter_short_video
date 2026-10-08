import 'dart:async';

import 'package:flutter/material.dart';

import '../data/video_repository.dart';
import '../models/feed_item.dart';
import '../utils/logger.dart';
import 'favorites_feed_page.dart';

/// 收藏列表页：从「个人中心」点进来，展示分页加载的收藏视频网格。
///
/// 行为：
/// - 下拉刷新：重新拉第 0 页；
/// - 上拉到底：提前一屏预取下一页（[VideoRepository.fetchFeed] 按 page 递增返回）；
/// - 点某条：携带「当前已加载的全部列表」+「点击下标」进入 [FavoritesFeedPage]，
///   这样全屏页里向上滑可回看前面已加载的视频，向下滑继续分页，体验与抖音收藏一致。
class FavoritesListPage extends StatefulWidget {
  const FavoritesListPage({super.key, required this.repository});

  final VideoRepository repository;

  @override
  State<FavoritesListPage> createState() => _FavoritesListPageState();
}

class _FavoritesListPageState extends State<FavoritesListPage> {
  static const String _channel = '收藏';

  final List<FeedItem> _items = <FeedItem>[];
  final ScrollController _scrollController = ScrollController();

  int _page = 0;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    // 距底部还有约一屏时预取下一页，避免滑到底才转圈。
    if (pos.pixels >= pos.maxScrollExtent - 600 &&
        !_loadingMore &&
        _hasMore &&
        !_initialLoading) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage() async {
    try {
      final List<FeedItem> list = await widget.repository.fetchFeed(
        channel: _channel,
        page: 0,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _page = 0;
        _hasMore = list.length >= widget.repository.pageSize;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = '收藏加载失败，点击重试';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final List<FeedItem> list = await widget.repository.fetchFeed(
        channel: _channel,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _items.addAll(list);
        // 返回的条数不足一页即视为没有更多，停止继续请求。
        _hasMore = list.length >= widget.repository.pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _page = 0;
    _hasMore = true;
    await _loadFirstPage();
  }

  void _openPlayer(int index) {
    final FeedItem? item = index < _items.length ? _items[index] : null;
    logEvent('favorite_open', <String, dynamic>{
      if (item != null)
        ...<String, dynamic>{
          'item_id': item.id,
          'type': item.type.name,
        },
      'index': index,
      'from': 'favorites_list',
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesFeedPage(
          // 把内存里已分页加载的整批收藏带进去，作为全屏页的初始数据。
          initialItems: _items,
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
        title: const Text('我的收藏',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70));
    }
    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: () {
            setState(() => _initialLoading = true);
            unawaited(_loadFirstPage());
          },
          child: Text(_error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('还没有收藏任何视频',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.white,
      backgroundColor: Colors.black87,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 0.66,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _items.length) {
            // 列表底部加载更多指示器。
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white54),
              ),
            );
          }
          final FeedItem item = _items[index];
          return _buildCell(item, index);
        },
      ),
    );
  }

  Widget _buildCell(FeedItem item, int index) {
    return GestureDetector(
      onTap: () => _openPlayer(index),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            item.posterUrl,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? progress) {
              if (progress == null) return child;
              return Container(color: Colors.white12);
            },
            errorBuilder: (BuildContext context, Object error, _) =>
                Container(color: Colors.white10),
          ),
          // 居中播放图标，提示可点进全屏。
          const Center(
            child: Icon(Icons.play_circle_outline,
                color: Colors.white54, size: 34),
          ),
          // 底部渐变 + 描述 + 点赞数。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    Colors.black87,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.favorite,
                          size: 11, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(item.likeCount),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}w';
    }
    return '$value';
  }
}
