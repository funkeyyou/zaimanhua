import 'package:zai_x/models/db/download_status.dart';
import 'package:hive/hive.dart';
part 'novel_download_info.g.dart';

@HiveType(typeId: 5)
class NovelDownloadInfo {
  NovelDownloadInfo({
    required this.addTime,
    required this.chapterId,
    required this.chapterSort,
    required this.novelCover,
    required this.novelId,
    required this.novelName,
    required this.fileName,
    required this.imageFiles,
    required this.savePath,
    required this.status,
    required this.taskId,
    required this.isImage,
    required this.volumeName,
    required this.progress,
    required this.chapterName,
    required this.volumeID,
    required this.isVip,
    required this.volumeOrder,
    required this.imageUrls,
  });

  ///TaskID 任務，由小說ID_章節ID組成
  @HiveField(0)
  String taskId;

  ///NovelID 小說ID
  @HiveField(1)
  int novelId;

  ///NovelName 小說名稱
  @HiveField(2)
  String novelName;

  ///NovelCover 小說封面
  @HiveField(3)
  String novelCover;

  ///ChapterID 章節ID
  @HiveField(4)
  int chapterId;

  ///chapterName 章節名稱
  @HiveField(5)
  String chapterName;

  ///VoulmeID 分卷ID
  @HiveField(6)
  int volumeID;

  ///VoulmeName 分卷名稱
  @HiveField(7)
  String volumeName;

  ///volumeOrder 分卷排序
  @HiveField(8)
  int volumeOrder;

  ///ChapterSort 排序
  @HiveField(9)
  int chapterSort;

  ///SavePath 儲存路徑
  @HiveField(10)
  String savePath;

  ///Files 檔案列表
  @HiveField(11)
  String fileName;

  ///isImage 是否為插圖
  @HiveField(12)
  bool isImage;

  /// 圖片儲存路徑
  @HiveField(13)
  List<String> imageFiles;

  ///下載進度 0-100
  @HiveField(14)
  int progress;

  ///Status 當前狀態
  @HiveField(15)
  DownloadStatus status;

  ///AddTime 任務時間
  @HiveField(16)
  DateTime addTime;

  /// 是否VIP章節
  /// * 暫時沒啥用，總之先加上
  @HiveField(17)
  bool isVip;

  /// 下載圖片連結
  @HiveField(18)
  List<String> imageUrls;
}
