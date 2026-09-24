import 'package:flutter/material.dart';
import 'hitomi_reader.dart';
import 'package:get/get.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'hitomi_filter_history.dart';
import 'package:zai_x/app/i18n.dart';
import 'hitomi_library.dart';
import 'hitomi_source.dart';
import 'hitomi_tag_picker.dart';
import 'hitomi_grid.dart';
import 'hitomi_title.dart';

class HitomiPage extends StatefulWidget {
  const HitomiPage(
      {super.key, required this.onHide, this.source, this.library});
  final VoidCallback onHide;
  final HitomiSource? source;
  final Future<HitomiLibrary>? library;
  @override
  State<HitomiPage> createState() => _HitomiPageState();
}

class _HitomiPageState extends State<HitomiPage> {
  late final source = widget.source ?? HitomiSource();
  final query = TextEditingController();
  late final Future<HitomiLibrary> library =
      widget.library ?? HitomiLibrary.open();
  List<int> ids = [];
  List<Map> galleries = [];
  String language = 'chinese';
  String category = '';
  List<String> selectedTags = [];
  late final HitomiFilterHistory? filterHistory =
      Get.isRegistered<LocalStorageService>()
          ? HitomiFilterHistory(LocalStorageService.instance.settingsBox)
          : null;

  Future<void> recentFilters() async {
    final entries = filterHistory?.read() ?? [];
    final choice = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
          child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(children: [
                ListTile(
                    title: Text('最近筛选'.i18n),
                    trailing: TextButton(
                        onPressed: () async {
                          await filterHistory?.clear();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text('清空'.i18n))),
                if (entries.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('暂无记录'.i18n)),
                Expanded(
                    child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          final tags = (e['tags'] as List).cast<String>();
                          final languageName = {
                                'chinese': '中文',
                                'japanese': '日本語',
                                'english': 'English',
                                'all': '全部语言'
                              }[e['language']] ??
                              e['language'].toString();
                          return ListTile(
                              title: Text(
                                  [
                                    if (e['query'] != '') e['query'] as String,
                                    ...tags,
                                    if (e['query'] == '' && tags.isEmpty)
                                      (HitomiSource.categories[e['category']] ??
                                              '')
                                          .i18n
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${(HitomiSource.categories[e['category']] ?? '').i18n} · ${languageName.i18n}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(context, e));
                        })),
              ]))),
    );
    if (!mounted || choice == null) return;
    query.text = choice['query'] as String;
    language = choice['language'] as String;
    category = choice['category'] as String;
    selectedTags = (choice['tags'] as List).cast<String>();
    load();
  }

  Future<void> chooseTags() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: HitomiTagPicker(source: source, selected: selectedTags)),
    );
    if (!mounted || result == null) return;
    selectedTags = result;
    load();
  }

  String? error;
  bool loading = false;
  int generation = 0;
  int offset = 0;
  int columns = 2;
  final scroll = ScrollController();
  void loadNearEnd() {
    if (!mounted || loading || error != null || offset >= ids.length) return;
    if (offset % columns != 0) {
      load(more: true, fillRowOnly: true);
    } else if (scroll.hasClients &&
        scroll.position.hasContentDimensions &&
        scroll.position.extentAfter < 400) {
      load(more: true);
    }
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener(loadNearEnd);
    load();
  }

  @override
  void dispose() {
    generation++;
    scroll.dispose();
    query.dispose();
    source.dio.close(force: true);
    super.dispose();
  }

  Future<void> load({bool more = false, bool fillRowOnly = false}) async {
    if (more && (loading || offset >= ids.length)) return;
    final token = ++generation;
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        ids = [];
        galleries = [];
        offset = 0;
      }
    });
    if (!more && scroll.hasClients) scroll.jumpTo(0);
    try {
      await source.refreshRules();
      final result = more
          ? ids
          : await source.filteredList(query.text, language, category,
              tags: selectedTags);
      if (!mounted || generation != token) return;
      ids = result;
      final chunk = <Map>[];
      final end =
          hitomiBatchEnd(offset, ids.length, columns, fillRowOnly: fillRowOnly);
      for (var i = offset; i < end; i += 3) {
        final batch = await Future.wait(
            ids.sublist(i, (i + 3).clamp(0, end)).map(source.gallery));
        if (!mounted || token != generation) return;
        chunk.addAll(batch);
      }
      setState(() {
        galleries = [...galleries, ...chunk];
        offset = end;
      });
      if (!more) {
        await filterHistory?.remember(
            query: query.text,
            language: language,
            category: category,
            tags: selectedTags);
      }
    } catch (_) {
      if (mounted && token == generation) {
        setState(() => error = '加载失败，请重试'.i18n);
      }
    } finally {
      if (mounted && token == generation) {
        setState(() => loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => loadNearEnd());
      }
    }
  }

  Future<void> open(Map gallery) async {
    try {
      await source.refreshRules();
      final store = await library;
      if (!mounted) return;
      await openHitomiReader(gallery, source, store);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('加载失败，请重试'.i18n)));
      }
    }
  }

  Widget grid(List<Map> items) => LayoutBuilder(
      builder: (context, box) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: hitomiColumns(box.maxWidth),
                childAspectRatio: .60,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final files = (item['files'] as List?) ?? [];
              return InkWell(
                  onTap: () => open(item),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: SizedBox(
                                width: double.infinity,
                                child: files.isEmpty
                                    ? const Icon(Icons.broken_image_outlined)
                                    : Image.network(
                                        source.image(files.first as Map,
                                            thumbnail: true),
                                        headers: HitomiSource.headers,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.broken_image_outlined)))),
                        const SizedBox(height: 6),
                        Text(hitomiTitle(item),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('${files.length} P',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]));
            },
          ));

  Widget saved(bool favorites) => FutureBuilder<HitomiLibrary>(
      future: library,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('加载失败，请重试'.i18n));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SavedHitomi(
            library: snapshot.data!, favorites: favorites, grid: grid);
      });

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            title: Text('画廊'.i18n),
            actions: [
              IconButton(
                  tooltip: '隐藏入口'.i18n,
                  icon: const Icon(Icons.visibility_off_outlined),
                  onPressed: () async {
                    final hide = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                                title: Text('隐藏入口'.i18n),
                                content: Text('收藏与阅读记录会保留，再次点击作者名十次可开启。'.i18n),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('取消'.i18n)),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('隐藏'.i18n))
                                ]));
                    if (hide == true) widget.onHide();
                  })
            ],
            bottom: TabBar(tabs: [
              Tab(text: '探索'.i18n),
              Tab(text: '书架'.i18n),
              Tab(text: '浏览记录'.i18n)
            ])),
        body: TabBarView(children: [
          LayoutBuilder(builder: (context, box) {
            final count = hitomiColumns(box.maxWidth - 24);
            if (columns != count) {
              columns = count;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => loadNearEnd());
            }
            // Desktop windows can grow taller without changing the column
            // count; re-check whenever the viewport or content size changes.
            return NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0) loadNearEnd();
                  return false;
                },
                child: ListView(
                    key: const ValueKey('hitomi-explore-list'),
                    controller: scroll,
                    padding: const EdgeInsets.all(12),
                    children: [
                      TextField(
                          controller: query,
                          onSubmitted: (_) => load(),
                          decoration: InputDecoration(
                              labelText: '标签、作品 ID 或链接'.i18n,
                              helperText: 'tag / artist:name / group:name',
                              suffixIcon: IconButton(
                                  onPressed: () => load(),
                                  icon: const Icon(Icons.search)))),
                      Wrap(spacing: 12, children: [
                        OutlinedButton.icon(
                          onPressed: chooseTags,
                          icon: const Icon(Icons.label_outline),
                          label:
                              Text('${'分类标签'.i18n} (${selectedTags.length})'),
                        ),
                        TextButton.icon(
                            onPressed: recentFilters,
                            icon: const Icon(Icons.history),
                            label: Text('最近筛选'.i18n))
                      ]),
                      if (selectedTags.isNotEmpty)
                        Wrap(
                            spacing: 6,
                            children: selectedTags
                                .map((tag) => InputChip(
                                    label: Text(tag),
                                    onDeleted: () {
                                      selectedTags.remove(tag);
                                      load();
                                    }))
                                .toList()),
                      Row(children: [
                        Expanded(
                            child: DropdownButton<String>(
                          key: const ValueKey('hitomi-category'),
                          isExpanded: true,
                          value: category,
                          items: HitomiSource.categories.entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value.i18n,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (value) {
                            category = value!;
                            load();
                          },
                        )),
                        const SizedBox(width: 16),
                        Expanded(
                            child: DropdownButton<String>(
                                key: const ValueKey('hitomi-language'),
                                isExpanded: true,
                                value: language,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'chinese', child: Text('中文')),
                                  DropdownMenuItem(
                                      value: 'japanese', child: Text('日本語')),
                                  DropdownMenuItem(
                                      value: 'english', child: Text('English')),
                                  DropdownMenuItem(
                                      value: 'all', child: Text('All'))
                                ],
                                onChanged: (value) {
                                  language = value!;
                                  load();
                                })),
                        if (category.isNotEmpty ||
                            selectedTags.isNotEmpty ||
                            language != 'chinese' ||
                            query.text.isNotEmpty)
                          IconButton(
                              tooltip: '清除筛选'.i18n,
                              onPressed: () {
                                query.clear();
                                category = '';
                                selectedTags = [];
                                language = 'chinese';
                                load();
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined)),
                      ]),
                      if (error != null)
                        TextButton(
                            onPressed: () => load(more: galleries.isNotEmpty),
                            child: Text(error!)),
                      if (!loading && galleries.isEmpty && error == null)
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('没有找到作品'.i18n)),
                      grid(galleries),
                      if (loading)
                        const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator())),
                    ]));
          }),
          saved(true),
          saved(false),
        ]),
      ));
}

class _SavedHitomi extends StatefulWidget {
  const _SavedHitomi(
      {required this.library, required this.favorites, required this.grid});
  final HitomiLibrary library;
  final bool favorites;
  final Widget Function(List<Map>) grid;
  @override
  State<_SavedHitomi> createState() => _SavedHitomiState();
}

class _SavedHitomiState extends State<_SavedHitomi> {
  String? tag;
  @override
  Widget build(BuildContext context) {
    final all = widget.library
        .entries(favorites: widget.favorites)
        .map((e) => e['gallery'] as Map)
        .toList();
    final tags = all
        .expand((e) => (e['tags'] as List? ?? []).map((t) => '${t['tag']}'))
        .toSet()
        .toList()
      ..sort();
    if (!tags.contains(tag)) tag = null;
    final items = tag == null
        ? all
        : all
            .where(
                (g) => (g['tags'] as List? ?? []).any((t) => t['tag'] == tag))
            .toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      if (widget.favorites)
        DropdownButton<String>(
            isExpanded: true,
            value: tag,
            hint: Text('全部标签'.i18n),
            items: [
              DropdownMenuItem<String>(value: null, child: Text('全部标签'.i18n)),
              ...tags.map((t) => DropdownMenuItem(
                  value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
            ],
            onChanged: (value) => setState(() => tag = value)),
      if (items.isEmpty)
        Padding(padding: const EdgeInsets.all(24), child: Text('暂无记录'.i18n)),
      widget.grid(items),
    ]);
  }
}
