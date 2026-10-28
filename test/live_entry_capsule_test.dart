import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_short_video/widgets/live_entry_capsule.dart';

void main() {
  testWidgets('胶囊渲染、动画运行且点击可触发回调', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: LiveEntryCapsule(onTap: () => taps++),
          ),
        ),
      ),
    );

    expect(find.text('点击进入直播间'), findsOneWidget);
    expect(find.byType(LiveWaveIcon), findsOneWidget);
    // 动画确实在跑（离屏/可见开关的行为由 animating 控制）。
    final LiveWaveIcon icon = tester.widget(find.byType(LiveWaveIcon));
    expect(icon.progress.isAnimating, isTrue);

    // 动画跑几帧不应抛异常（overflow / disposed animation 等）。
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(LiveEntryCapsule));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('窄屏不溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: LiveEntryCapsule()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
