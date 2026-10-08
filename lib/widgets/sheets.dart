import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart' as modal;

/// 底部弹框统一走 `modal_bottom_sheet` 组件实现（可拖拽、圆角、支持自定义高度）。
/// 评论与分享两个弹层抽成共享函数，首页信息流与个人中心收藏全屏页复用同一套。

/// 评论弹层：基于 [modal.showModalBottomSheet] 的可拖拽底部弹框。
void showCommentSheet(BuildContext context) {
  modal.showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _CommentSheetBody(
        height: MediaQuery.of(context).size.height * 0.62,
      );
    },
  );
}

/// 分享弹层：基于 [modal.showModalBottomSheet] 的底部弹框。
void showShareSheet(BuildContext context) {
  modal.showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const _ShareSheetBody(height: 230);
    },
  );
}

class _CommentSheetBody extends StatelessWidget {
  const _CommentSheetBody({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
              itemCount: 30,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white70),
                  ),
                  title: Text(
                    '用户 $index',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  subtitle: Text(
                    '这条评论来自第 $index 位观众',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
  }
}

class _ShareSheetBody extends StatelessWidget {
  const _ShareSheetBody({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
                          name[0],
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
  }
}
