import 'package:zai_x/models/user/subscribe_comic_model.dart';

UserSubscribeComicItemModel shelfComic(int id,
        {int? latest, int time = 100, Map<String, dynamic>? history}) =>
    UserSubscribeComicItemModel.fromJson({
      'id': id,
      'title': 'Comic $id',
      'cover': '',
      'sub_readed': 1,
      'last_update_chapter_id': latest ?? id * 10,
      'last_update_chapter_name': 'Chapter',
      'last_updatetime': time,
      'comic_py': 'comic',
      'status': '连载中',
      'readingRecord': history ?? {},
    });
