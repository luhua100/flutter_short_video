import 'dart:convert';

import 'package:logger/logger.dart';

/// 轻量埋点 / 日志工具，底层使用 `logger` 包输出。
///
/// 所有 item 的点击事件统一走 [logEvent]，便于统计曝光、互动与留存。
/// 默认以 info 级别打印到控制台（带格式、带 emoji 关闭）；接入真实埋点
/// 平台时，在调用处自行替换为网络上报即可，[logEvent] 的签名保持不变。
final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 0,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

/// 记录一条业务事件（点击 / 曝光 / 切换）。
///
/// 示例：
/// ```dart
/// logEvent('comment_click', <String, dynamic>{'item_id': item.id});
/// ```
void logEvent(String event, [Map<String, dynamic>? params]) {
  final String payload =
      params != null ? ' ${const JsonEncoder().convert(params)}' : '';
  _logger.i('[track] $event$payload');
}

/// 便捷 info 级日志（非事件类，如页面生命周期）。
void logInfo(String message) => _logger.i(message);

/// 便捷 error 级日志。
void logError(String message, [Object? error]) =>
    _logger.e(message, error: error);
