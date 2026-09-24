import 'package:flutter/material.dart';
import 'package:zai_x/app/i18n.dart';
import 'hitomi_source.dart';
import 'tag_search.dart';

class HitomiTagPicker extends StatefulWidget {
  const HitomiTagPicker(
      {super.key, required this.source, required this.selected});
  final HitomiSource source;
  final List<String> selected;
  @override
  State<HitomiTagPicker> createState() => _HitomiTagPickerState();
}

class _HitomiTagPickerState extends State<HitomiTagPicker> {
  late final selected = widget.selected.toSet();
  String letter = 'a';
  String keyword = '';
  late Future<List<String>> catalog = widget.source.tags(letter);
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text('分类标签'.i18n,
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton(
                onPressed: () => setState(selected.clear),
                child: Text('清空'.i18n)),
            FilledButton(
                onPressed: () => Navigator.pop(context, selected.toList()),
                child: Text('${'应用'.i18n} (${selected.length})'))
          ]),
          Text('同时满足所选标签；取消关闭不会修改当前筛选。'.i18n),
          if (selected.isNotEmpty)
            ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 96),
                child: SingleChildScrollView(
                    child: Wrap(
                        spacing: 6,
                        children: selected
                            .map((t) => InputChip(
                                label: Text(t),
                                onDeleted: () =>
                                    setState(() => selected.remove(t))))
                            .toList()))),
          SizedBox(
              height: 52,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['123', ...'abcdefghijklmnopqrstuvwxyz'.split('')]
                      .map((value) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                              label: Text(value.toUpperCase()),
                              selected: letter == value,
                              onSelected: (_) => setState(() {
                                    letter = value;
                                    keyword = '';
                                    search.clear();
                                    catalog = widget.source.tags(letter);
                                  }))))
                      .toList())),
          TextField(
              controller: search,
              decoration: InputDecoration(
                  labelText: '模糊搜索全部标签'.i18n,
                  helperText: '支持部分名称、多个词和少量拼写错误'.i18n,
                  prefixIcon: const Icon(Icons.search)),
              onChanged: (value) => setState(() {
                    keyword = value.toLowerCase().trim();
                    catalog = keyword.isEmpty
                        ? widget.source.tags(letter)
                        : widget.source.allTags();
                  })),
          Expanded(
              child: FutureBuilder<List<String>>(
                  future: catalog,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: TextButton(
                              onPressed: () => setState(() => catalog =
                                  keyword.isEmpty
                                      ? widget.source.tags(letter)
                                      : widget.source.allTags()),
                              child: Text('加载失败，请重试'.i18n)));
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tags = searchTags(snapshot.data!, keyword);
                    if (tags.isEmpty) {
                      return Center(child: Text('没有匹配的标签'.i18n));
                    }
                    return ListView.builder(
                        itemCount: tags.length,
                        itemBuilder: (context, i) => CheckboxListTile(
                            dense: true,
                            title: Text(tags[i]),
                            value: selected.contains(tags[i]),
                            onChanged: (checked) => setState(() {
                                  checked == true
                                      ? selected.add(tags[i])
                                      : selected.remove(tags[i]);
                                })));
                  })),
        ]),
      ));
}
