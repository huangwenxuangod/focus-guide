import 'dart:async';

/// 防抖动工具类 - 防止快速连续操作
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// 执行防抖动操作
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即执行并取消待定的操作
  void runNow(VoidCallback action) {
    _timer?.cancel();
    action();
  }

  /// 取消待定的操作
  void cancel() {
    _timer?.cancel();
  }

  /// 检查是否有待定的操作
  bool get isPending => _timer?.isActive ?? false;

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}

/// 防抖动回调类型
typedef VoidCallback = void Function();