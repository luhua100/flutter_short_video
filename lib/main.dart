import 'package:flutter/material.dart';

import 'pages/short_video_feed_page.dart';

void main() {
  runApp(const ShortVideoApp());
}

class ShortVideoApp extends StatelessWidget {
  const ShortVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '短视频',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF2C55),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ShortVideoFeedPage(),
    );
  }
}
