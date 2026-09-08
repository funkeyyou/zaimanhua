import 'package:hive/hive.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/user_service.dart';

enum ComicUpdateState { unread, caughtUp, unknown }

/// 与旧版的「进入过章节」记录分开，只记读到末页或手动标记的章节。
/// 按账号隔离；不使用服务端「打开过详情」的 sub_readed 判断追平。
class ComicCompletionService {
  ComicCompletionService(this.box, this.accountId);

  factory ComicCompletionService.current() => ComicCompletionService(
        LocalStorageService.instance.settingsBox,
        UserService.instance.logined.value ? UserService.instance.userId : '',
      );

  final Box box;
  final String accountId;
  String _key(int comicId) => 'ComicCompletionV1:$accountId:$comicId';

  Map<String, bool> _read(int comicId) {
    final stored = box.get(_key(comicId));
    if (stored is! Map) return {};
    return {
      for (final entry in stored.entries)
        if (entry.value is bool) '${entry.key}': entry.value as bool,
    };
  }

  ComicUpdateState stateOf(UserSubscribeComicItemModel comic) {
    final latest = comic.lastUpdateChapterId;
    if (latest <= 0) return ComicUpdateState.unknown;
    final local = _read(comic.id)['$latest'];
    if (local != null) {
      return local ? ComicUpdateState.caughtUp : ComicUpdateState.unread;
    }
    final remote = comic.readingRecord;
    // 有确切总页数才接受远端末页；缺少总页数不能假装已读完。
    return remote.chapterId == latest &&
            remote.totalNum > 0 &&
            remote.record >= remote.totalNum
        ? ComicUpdateState.caughtUp
        : ComicUpdateState.unread;
  }

  Future<void> setChapters(
    int comicId,
    Iterable<int> chapterIds, {
    required bool completed,
  }) async {
    final values = _read(comicId);
    var changed = false;
    for (final id in chapterIds.where((id) => id > 0)) {
      if (values['$id'] != completed) {
        values['$id'] = completed;
        changed = true;
      }
    }
    if (!changed) return;
    await box.put(_key(comicId), values);
    EventBus.instance.emit(EventBus.kComicCompletionChanged, comicId);
  }
}
