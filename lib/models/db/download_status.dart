import 'package:hive/hive.dart';
part 'download_status.g.dart';

/// 下載狀態
@HiveType(typeId: 4)
enum DownloadStatus {
  /// 等待下載中
  @HiveField(0)
  wait,

  /// 正在讀取章節資訊
  @HiveField(1)
  loadding,

  /// 下載中
  @HiveField(2)
  downloading,

  /// 使用資料，自動暫停，當網路切換時恢復下載
  @HiveField(3)
  pauseCellular,

  /// 暫停
  @HiveField(4)
  pause,

  /// 已完成
  @HiveField(5)
  complete,

  /// 讀取資訊時出現錯誤
  @HiveField(6)
  errorLoad,

  /// 下載出錯
  @HiveField(7)
  error,

  /// 已取消
  @HiveField(8)
  cancel,

  /// 等待網路連線
  @HiveField(9)
  waitNetwork,
}
