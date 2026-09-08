import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/comic_completion_service.dart';
import 'package:zai_x/services/comic_shelf_repository.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/subscribe_tag_service.dart';
import 'package:zai_x/services/user_service.dart';

class ComicSubscribeController
    extends BasePageController<UserSubscribeComicItemModel>
    with WidgetsBindingObserver {
  ComicSubscribeController({UserRequest? request})
      : request = request ?? UserRequest();
  final UserRequest request;
  late final repository =
      ComicShelfRepository(LocalStorageService.instance.settingsBox);

  Map<int, String> get types => {1: '全部订阅'.i18n, 2: '连载中'.i18n, 3: '已完结'.i18n};
  final type = 1.obs;
  Map<int, String> get sorts => {
        0: '订阅时间 ↓'.i18n,
        1: '订阅时间 ↑'.i18n,
        2: '更新时间 ↓'.i18n,
        3: '更新时间 ↑'.i18n,
      };
  late final sort = AppSettingsService.instance.subscribeSort.value.obs;
  Map<int, String> get readFilters => {
        0: '全部进度'.i18n,
        1: '有未读更新'.i18n,
        2: '已追平'.i18n,
      };
  final readFilter = 0.obs;
  final tag = ''.obs;
  final tags = <String>[].obs;
  final tagLoading = false.obs;
  final editMode = false.obs;
  final preparing = false.obs;
  final refreshing = false.obs;
  final refreshFailed = false.obs;
  final hasPendingUpdate = false.obs;
  final savedAt = Rx<DateTime?>(null);
  final _all = <UserSubscribeComicItemModel>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  ComicShelfSnapshot? _pending;
  bool _hasSnapshot = false;
  int _generation = 0;
  String _owner = '';
  Future<void>? _tagFuture;

  String get _currentOwner =>
      UserService.instance.logined.value ? UserService.instance.userId : '';

  ComicUpdateState stateOf(UserSubscribeComicItemModel item) =>
      ComicCompletionService(LocalStorageService.instance.settingsBox, _owner)
          .stateOf(item);

  @override
  void onInit() {
    super.onInit();
    _switchAccount();
    _subscriptions.addAll([
      UserService.loginedStream.listen((_) {
        _switchAccount();
        unawaited(refreshInBackground());
      }),
      UserService.logoutStream.listen((_) => _switchAccount()),
      EventBus.instance.listen(EventBus.kComicCompletionChanged, (_) {
        applyFilterAndSort();
      }),
    ]);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(refreshInBackground());
  }

  void _switchAccount() {
    _generation++;
    if (_owner != _currentOwner) {
      UserService.instance.subscribedComicIds.clear();
    }
    _owner = _currentOwner;
    _all.clear();
    list.clear();
    _pending = null;
    hasPendingUpdate.value = false;
    _hasSnapshot = false;
    savedAt.value = null;
    refreshing.value = false;
    refreshFailed.value = false;
    pageError.value = false;
    pageEmpty.value = false;
    tag.value = '';
    tags.clear();
    editMode.value = false;
    preparing.value = _owner.isNotEmpty;
    final cached = repository.read(_owner);
    if (cached != null) _accept(cached);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        DateTime.now().difference(savedAt.value ?? DateTime(2000)).inMinutes >=
            2) {
      unawaited(refreshInBackground());
    }
  }

  @override
  Future<void> refreshData() => _refresh(background: false);

  Future<void> refreshInBackground() => _refresh(background: true);

  @override
  Future<void> loadData() => refreshData();

  Future<void> _refresh({required bool background}) async {
    if (_owner != _currentOwner) _switchAccount();
    if (refreshing.value || _owner.isEmpty || isClosed) return;
    final owner = _owner;
    final generation = ++_generation;
    refreshing.value = true;
    refreshFailed.value = false;
    pageError.value = false;
    preparing.value = !_hasSnapshot;
    bool active() =>
        !isClosed && generation == _generation && owner == _currentOwner;
    try {
      final snapshot = await repository.fetch((page) {
        if (!active()) throw StateError('Account changed');
        return request.comicSubscriptionPage(page: page);
      });
      if (!active()) return;
      await repository.save(owner, snapshot);
      if (!active()) return;
      UserService.instance.subscribedComicIds
          .addAll(snapshot.items.map((e) => e.id));
      if (_hasSnapshot && jsonEncode(snapshot.items) == jsonEncode(_all)) {
        savedAt.value = snapshot.savedAt;
        _pending = null;
        hasPendingUpdate.value = false;
        unawaited(_loadTags());
        return;
      }
      // 前景刷新不能在用户浏览中段时悄悄重排作品。
      if (_hasSnapshot &&
          (editMode.value ||
              (background &&
                  scrollController.hasClients &&
                  scrollController.offset > 0))) {
        _pending = snapshot;
        hasPendingUpdate.value = true;
      } else {
        _accept(snapshot);
      }
      unawaited(_loadTags());
    } catch (e) {
      if (!active()) return;
      refreshFailed.value = _hasSnapshot;
      if (!_hasSnapshot) {
        pageError.value = true;
        errorMsg.value = exceptionToString(e);
      }
    } finally {
      if (active()) {
        refreshing.value = false;
        preparing.value = false;
      }
    }
  }

  void _accept(ComicShelfSnapshot snapshot) {
    _all
      ..clear()
      ..addAll(snapshot.items);
    _hasSnapshot = true;
    UserService.instance.subscribedComicIds
        .addAll(snapshot.items.map((e) => e.id));
    savedAt.value = snapshot.savedAt;
    _pending = null;
    hasPendingUpdate.value = false;
    preparing.value = false;
    canLoadMore.value = false;
    tags.assignAll(
        SubscribeTagService.availableTags(_all.map((e) => e.id).toList()));
    applyFilterAndSort();
  }

  void showPendingUpdate() {
    final pending = _pending;
    if (pending == null || editMode.value) return;
    _accept(pending);
    _toTop();
  }

  Future<void> _loadTags() {
    if (_tagFuture != null) {
      return _tagFuture!.then((_) {
        if (!isClosed) return _loadTags();
      });
    }
    final owner = _owner;
    final ids = (_pending?.items ?? _all).map((e) => e.id).toList();
    tagLoading.value = true;
    return _tagFuture =
        SubscribeTagService.fetchMissing(ids, limit: ids.length).then((_) {
      if (isClosed || owner != _owner) return;
      tags.assignAll(
          SubscribeTagService.availableTags(_all.map((e) => e.id).toList()));
      if (tag.value.isNotEmpty) applyFilterAndSort();
    }).catchError((Object e) {
      Log.logPrint(e);
    }).whenComplete(() {
      _tagFuture = null;
      if (!isClosed) tagLoading.value = false;
    });
  }

  void applyFilterAndSort() {
    var items = _all.where((item) {
      if (type.value == 2 && item.status != '连载中') return false;
      if (type.value == 3 && !item.status.contains('完结')) return false;
      if (tag.value.isNotEmpty &&
          !SubscribeTagService.tagsOf(item.id).contains(tag.value)) {
        return false;
      }
      final state = stateOf(item);
      return readFilter.value == 0 ||
          (readFilter.value == 1 && state == ComicUpdateState.unread) ||
          (readFilter.value == 2 && state == ComicUpdateState.caughtUp);
    }).toList();
    if (sort.value == 1) items = items.reversed.toList();
    if (sort.value == 2 || sort.value == 3) {
      items.sort((a, b) {
        final order = sort.value == 2
            ? b.updateSortKey.compareTo(a.updateSortKey)
            : a.updateSortKey.compareTo(b.updateSortKey);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    }
    list.assignAll(items);
    pageEmpty.value = _hasSnapshot && items.isEmpty;
  }

  void _toTop() {
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  void setSort(int value) {
    sort.value = value;
    AppSettingsService.instance.setSubscribeSort(value);
    applyFilterAndSort();
    _toTop();
  }

  void setType(int value) {
    type.value = value;
    applyFilterAndSort();
    _toTop();
  }

  void setReadFilter(int value) {
    readFilter.value = value;
    applyFilterAndSort();
    _toTop();
  }

  Future<void> setTag(String value) async {
    tag.value = value;
    if (value.isNotEmpty && tagLoading.value) {
      preparing.value = true;
      await _tagFuture;
      if (isClosed) return;
      preparing.value = false;
    }
    applyFilterAndSort();
    _toTop();
  }

  Map<String, String> get tagOptions => {
        '': '全部'.i18n,
        for (final value in tags) value: value,
      };

  void cancelEdit() {
    for (var item in _all) {
      item.isChecked.value = false;
    }
    editMode.value = false;
  }

  void cancelSub() async {
    final ids = list.where((x) => x.isChecked.value).map((e) => e.id).toList();
    cancelEdit();
    if (ids.isEmpty) return;
    await UserService.instance.cancelSubscribe(ids, AppConstant.kTypeComic);
    await refreshData();
  }

  void addFavorite() {
    for (var item in list.where((x) => x.isChecked.value)) {
      DBService.instance.putComicFavorite(
          title: item.title, cover: item.cover, comicId: item.id);
    }
    cancelEdit();
    SmartDialog.showToast('已添加至本机收藏'.i18n);
  }

  @override
  void onClose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    scrollController.dispose();
    easyRefreshController.dispose();
    super.onClose();
  }
}
