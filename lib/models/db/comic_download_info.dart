import 'package:zai_x/models/db/download_status.dart';
import 'package:hive/hive.dart';
part 'comic_download_info.g.dart';

@HiveType(typeId: 3)
class ComicDownloadInfo {
  ComicDownloadInfo({
    required this.addTime,
    required this.chapterId,
    required this.chapterSort,
    required this.comicCover,
    required this.comicId,
    required this.comicName,
    required this.files,
    required this.index,
    required this.savePath,
    required this.status,
    required this.taskId,
    required this.total,
    required this.volumeName,
    required this.urls,
    required this.chapterName,
    required this.isVip,
    required this.isLongComic,
  });

  ///TaskID 任務，由漫畫ID_章節ID組成
  @HiveField(0)
  String taskId;

  ///ComicID 漫畫ID
  @HiveField(1)
  int comicId;

  ///ComicName 漫畫名稱
  @HiveField(2)
  String comicName;

  ///ComicCover 漫畫封面
  @HiveField(3)
  String comicCover;

  ///ChapterID 章節ID
  @HiveField(4)
  int chapterId;

  @HiveField(5)
  String chapterName;

  ///VoulmeName 分卷名稱
  @HiveField(6)
  String volumeName;

  ///ChapterSort 排序
  @HiveField(7)
  int chapterSort;

  ///SavePath 儲存路徑
  @HiveField(8)
  String savePath;

  ///Files 檔案列表
  @HiveField(9)
  List<String> files;

  ///Index 當前下載頁數
  @HiveField(10)
  int index;

  ///Total 總計頁數
  @HiveField(11)
  int total;

  ///Status 當前狀態
  @HiveField(12)
  DownloadStatus status;

  ///AddTime 任務時間
  @HiveField(13)
  DateTime addTime;

  /// 下載圖片連結
  @HiveField(14)
  List<String> urls;

  /// 是否VIP章節
  /// * 暫時沒啥用，總之先加上
  @HiveField(15)
  bool isVip;

  /// 是否為條漫
  @HiveField(16)
  bool isLongComic;
}
