# 短视频体验优化清单

> 结论先行：旧实现是一个"能跑通的 Demo"，不是可交付的信息流。
> 客户反馈的"卡、黑屏、刷新没反应、错位"，基本都能归到下面 12 个具体问题里。
> 本次已把 P0 / P1 / P2 全部修完，`flutter analyze` 无告警，单测通过。

---

## 一、P0：会导致崩溃或功能直接失效

| # | 问题 | 根因 | 改法 |
|---|---|---|---|
| 1 | 两个频道共用一个 `PageController` | 关注 / 推荐两个 `PageView` 绑同一个控制器，滚动位置互相污染，切频道后停在错误的位置 | 每个频道独立持有 `PageController`（`feed_tab_view.dart`） |
| 2 | 监听器根本没被移除 | `dispose()` 里写的是 `removeListener(() {})` —— 传进去的是一个**新的匿名闭包**，和 `initState` 里注册的那个不是同一个对象，等于没移除。页面销毁后回调继续触发 `setState`，抛 "setState() called after dispose()" | 播放器池不再注册任何 controller 监听器；UI 侧改用 `ValueListenableBuilder`，生命周期由框架托管 |
| 3 | 下拉刷新完全不生效 | 刷新函数里既没有 `setState`，又因为 `tabController.index` 判断写反，把"关注"频道的数据刷新成了"推荐"的数据 | `FeedTabView.onRefresh()` 替换整页数据 + 回到第一屏 + 重新调度播放；数据源加 `salt` 保证刷新回来的是新内容 |
| 4 | 进度条除零 | `value / total` 在 `duration` 为 0 时得到 NaN，直接抛渲染异常 | 进度计算统一做 `total > 0` 判断，兜底为 0 |
| 5 | release 包没有网络权限 | `INTERNET` 权限只写在 `android/app/src/debug/AndroidManifest.xml` 里，**只覆盖 debug 构建**。客户拿到的 release 包视频全部加载失败，表现为永远转圈 | 权限已补进 `android/app/src/main/AndroidManifest.xml` |
| 6 | 加载错误被静默吞掉 | `.onError((error, stackTrace) {})` 把异常吃掉，用户只能看到无限转圈 | 播放器池记录 `failed` 状态，UI 显示"加载失败 + 点击重试" |

---

## 二、P1：性能与首帧体验

| # | 问题 | 根因 | 改法 |
|---|---|---|---|
| 7 | 播放时每帧整屏重建 | 在 controller 的监听器里直接 `setState()`，而这个 `build` 里包含整个 `Stack`（视频层、右侧栏、弹层构建函数）。等于**每帧重建整屏**，这是滑动掉帧的主因 | 进度、播放态交给 `ValueListenableBuilder` 局部重建；整屏只在加载状态变化时重建一次 |
| 8 | 滑动必黑屏再转圈 | 没有任何预加载，滑到哪一屏才开始初始化 + 下载 | 新增播放器池：滑动时预加载前后各一屏，当前屏直接起播；窗口外的实例释放 |
| 9 | 二次进入同一视频重新下载 | 每次创建新的 `VideoPlayerController`，没有复用 | 池按 url 复用 + LRU，常驻实例上限 4，避免打爆解码器 |
| 10 | 滑到最后一个才开始加载 | `onPageChanged` 里判断 `index == length - 1` 才请求，还要空等 2 秒且无任何提示 | 距末尾还有 3 屏就预取，最后一屏底部显示"正在加载更多…" |
| 11 | 首帧尺寸写死 9:16 | 用固定 `SizedBox(16, 9)` 包视频，非竖屏素材会被裁切错位 | 取 `controller.value.size` 的真实像素尺寸，配 `FittedBox(cover)` |
| 12 | 循环播放靠秒级比较判断 | `currentSec == totalSec` 每帧比较，还会让视频提前 1 秒回滚 | 改用 `setLooping(true)` |

---

## 三、P2：体验细节

| # | 问题 | 改法 |
|---|---|---|
| 13 | 顶部 TabBar 写死 `top: 54`，右侧栏写死 `height/2 - 135` | 全部改用 `SafeArea` + `MediaQuery.paddingOf`，刘海屏和底部手势区不再被遮挡 |
| 14 | 打开 App 就外放 | 默认静音进入，右侧提供喇叭开关；播放器加 `mixWithOthers`，不抢走其他 App 的音频焦点 |
| 15 | 只有转圈，没有封面 | 视频就绪前显示封面图，配合上下渐变遮罩保证白字可读 |
| 16 | 单击暂停 / 双击点赞缺失 | 单击暂停（260ms 判定，避免与双击冲突）；双击在手指位置炸开红色心形 |
| 17 | 进度条暂停就消失、不能拖动 | 常驻细进度条，支持横向拖拽 seek，拖动时加粗 |
| 18 | 没有一个加载失败入口 | 见 P0-6；首屏同样有错误态与重试按钮 |
| 19 | 切到后台仍在播放 | 监听 `AppLifecycleState`，进入后台暂停全部，回到前台恢复当前屏 |
| 20 | 切频道后另一个频道仍在播放 | `TabController` 变化时先 `pauseAll`，目标频道再重新起播 |
| 21 | 描述文字是一串硬编码数字、不可折叠 | 描述支持 2 行折叠 / 点击展开，配作者名与音乐名 |
| 22 | 依赖被锁死在 2022 年 | `environment` 从 `>=2.18.4 <3.0.0` 放开到 `>=3.0.0 <4.0.0`，并补上 `flutter_lints` |

---

## 四、改动文件对照

```
lib/
├── main.dart                       重写：去掉计数器模板，暗色主题
├── models/video_model.dart         新增：补齐封面/作者/计数/宽高比，fromJson 容错
├── player/video_player_pool.dart   新增：播放器池（复用 + LRU + 预加载 + 错误态）
├── data/video_repository.dart      新增：数据源与分页，与 UI 解耦
├── widgets/short_video_item.dart   重写：单屏渲染与手势
├── widgets/video_progress_bar.dart 新增：可拖拽进度条（局部刷新）
├── widgets/video_side_actions.dart 新增：右侧互动栏、点赞动画、唱片
├── pages/short_video_feed_page.dart 重写：双频道容器、评论/分享弹层、生命周期
└── pages/feed_tab_view.dart        重写：单频道信息流，播放窗口调度

android/app/src/main/AndroidManifest.xml   补 INTERNET 权限
pubspec.yaml                               放开 Dart 约束、加静态检查
旧实现已移至 .workbuddy/backup_legacy/（未删除，可随时对照）
```

---

## 五、仍需要后端 / 业务配合

1. **封面图**：接口必须下发首帧图 URL，否则滑动仍有短暂灰底。
2. **宽高比**：下发 `width/height`，避免首帧布局抖动。
3. **分片与码率**：短视频建议 H.264/720p 起播 + 多档码率，弱网自动降档。
4. **分页游标**：现在的 `page` 只是模拟，真实接口应返回游标，避免刷新时重复。

---

## 六、下一阶段建议（本次未做，按收益排序）

1. **视频边播边缓存**：引入 `flutter_cache_manager` 或自研代理缓存，二次进入秒开。收益最大。
2. **升级 video_player**：当前锁在 2.4.8（2022 年）。约束已放开，可以升到 2.14+，底层播放器实现有大量修复。
3. **首帧秒开**：服务端下发 HLS/DASH 切片 + 预取首片，或接入厂商播放器 SDK（如 TXVodPlayer）。
4. **性能监控**：接入 FPS、起播耗时、卡顿率、加载失败率埋点，用数据代替"感觉卡"。
5. **弱网策略**：起播缓冲阈值自适应 + 失败自动降码率重试。
6. **内存兜底**：低端机把池容量降到 2~3，并对接 `onMemoryPressure` 主动释放。
