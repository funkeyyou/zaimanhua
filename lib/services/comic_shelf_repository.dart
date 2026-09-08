import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:zai_x/app/app_error.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';

class ComicSubscriptionPage {
  const ComicSubscriptionPage(this.items, {this.total});
  final List<UserSubscribeComicItemModel> items;
  final int? total;
}

class ComicShelfSnapshot {
  const ComicShelfSnapshot(this.items, this.savedAt);
  final List<UserSubscribeComicItemModel> items;
  final DateTime savedAt;
}

/// 一次成功取得完整清单才替换快取；失败、重复分頁都不能发布半份排序结果。
class ComicShelfRepository {
  ComicShelfRepository(this.box);
  final Box box;
  String _key(String accountId) => 'ComicShelfV1:$accountId';

  ComicShelfSnapshot? read(String accountId) {
    if (accountId.isEmpty) return null;
    try {
      final raw = box.get(_key(accountId));
      if (raw is! String) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ComicShelfSnapshot(
        (data['items'] as List)
            .map((e) => UserSubscribeComicItemModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        DateTime.fromMillisecondsSinceEpoch(data['savedAt'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String accountId, ComicShelfSnapshot snapshot) async {
    if (accountId.isEmpty) return;
    await box.put(
        _key(accountId),
        jsonEncode({
          'savedAt': snapshot.savedAt.millisecondsSinceEpoch,
          'items': snapshot.items.map((e) => e.toJson()).toList(),
        }));
  }

  Future<ComicShelfSnapshot> fetch(
    Future<ComicSubscriptionPage> Function(int page) loadPage,
  ) async {
    final items = <UserSubscribeComicItemModel>[];
    final seen = <int>{};
    int? expectedTotal;
    // 防止服务端忽略 page 后无限请求；超过上限明确报错而不是静默截断。
    for (var page = 1; page <= 200; page++) {
      final result = await loadPage(page);
      expectedTotal ??= result.total;
      final fresh = result.items.where((item) => seen.add(item.id)).toList();
      items.addAll(fresh);
      if (expectedTotal != null && items.length >= expectedTotal) {
        return ComicShelfSnapshot(items, DateTime.now());
      }
      if (result.items.isEmpty && expectedTotal == null) {
        return ComicShelfSnapshot(items, DateTime.now());
      }
      if (fresh.isEmpty) break;
    }
    throw AppError('订阅列表未完整读取，请重试'.i18n);
  }
}
