import 'package:hive/hive.dart';

/// null 表示沿用全局设置；只保存用户为这部作品实际修改过的选项。
class ComicReaderPreferences {
  const ComicReaderPreferences(
      {this.direction, this.dualPage, this.coverAlone});

  final int? direction;
  final int? dualPage;
  final bool? coverAlone;
  bool get isCustom =>
      direction != null || dualPage != null || coverAlone != null;

  factory ComicReaderPreferences.fromMap(dynamic value) {
    if (value is! Map) return const ComicReaderPreferences();
    int? mode(dynamic value) =>
        value is int && value >= 0 && value <= 2 ? value : null;
    return ComicReaderPreferences(
      direction: mode(value['direction']),
      dualPage: mode(value['dualPage']),
      coverAlone:
          value['coverAlone'] is bool ? value['coverAlone'] as bool : null,
    );
  }

  ComicReaderPreferences copyWith(
          {int? direction, int? dualPage, bool? coverAlone}) =>
      ComicReaderPreferences(
        direction: direction ?? this.direction,
        dualPage: dualPage ?? this.dualPage,
        coverAlone: coverAlone ?? this.coverAlone,
      );

  Map<String, dynamic> toMap() => {
        if (direction != null) 'direction': direction,
        if (dualPage != null) 'dualPage': dualPage,
        if (coverAlone != null) 'coverAlone': coverAlone,
      };
}

class ComicReaderPreferencesStore {
  ComicReaderPreferencesStore(this.box);
  final Box box;
  String _key(int comicId) => 'ComicReaderPreferencesV1:$comicId';

  ComicReaderPreferences read(int comicId) =>
      ComicReaderPreferences.fromMap(box.get(_key(comicId)));

  Future<void> write(int comicId, ComicReaderPreferences value) =>
      box.put(_key(comicId), value.toMap());

  Future<void> reset(int comicId) => box.delete(_key(comicId));
}
