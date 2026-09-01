import 'dart:async';

import 'package:zai_x/app/log.dart';

/// 全域性事件
class EventBus {
  /// 點選了底部導航
  static const String kBottomNavigationBarClicked =
      "BottomNavigationBarClicked";

  /// 更新了漫畫記錄
  static const String kUpdatedComicHistory = "UpdateComicHistory";

  /// 更新了小說記錄
  static const String kUpdatedNovelHistory = "UpdateNovelHistory";

  /// 重新整理評論列表
  static const String kRefreshComment = "RefreshComment";
  static EventBus? _instance;

  static EventBus get instance {
    _instance ??= EventBus();
    return _instance!;
  }

  final Map<String, StreamController> _streams = {};

  /// 觸發事件
  void emit<T>(String name, T data) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }
    Log.d("Emit Event：$name\r\n$data");

    _streams[name]!.add(data);
  }

  /// 監聽事件
  StreamSubscription<dynamic> listen(String name, Function(dynamic)? onData) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }
    return _streams[name]!.stream.listen(onData);
  }
}
