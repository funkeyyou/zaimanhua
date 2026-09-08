import 'package:flutter/material.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/widgets/net_image.dart';

/// A single row: wider windows reveal more books, without stretching covers.
class RecentComics extends StatelessWidget {
  const RecentComics({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DBService.instance;
    return StreamBuilder(
      stream: db.comicHistoryBox.watch(),
      builder: (context, _) => RecentComicsRow(
        histories: db.getComicHistoryList(),
        onSelected: (item) => AppNavigator.toComicDetail(item.comicId),
      ),
    );
  }
}

class RecentComicsRow extends StatelessWidget {
  const RecentComicsRow({
    super.key,
    required this.histories,
    required this.onSelected,
  });

  final List<ComicHistory> histories;
  final ValueChanged<ComicHistory> onSelected;

  @override
  Widget build(BuildContext context) {
    if (histories.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近阅读'.i18n,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('接着上次的故事'.i18n, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final count = ((constraints.maxWidth + 12) / (100 * scale + 12))
                .floor()
                .clamp(1, 24);
            final width = (constraints.maxWidth - (count - 1) * 12) / count;
            final visible = histories.take(count).toList();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in visible)
                  Padding(
                    padding:
                        EdgeInsets.only(right: item == visible.last ? 0 : 12),
                    child: SizedBox(
                      width: width,
                      child: Semantics(
                        button: true,
                        label:
                            '${item.comicName}，${item.chapterName}，第${item.page}页'
                                .i18n,
                        child: InkWell(
                          key: ValueKey('recent-${item.comicId}'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onSelected(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: NetImage(item.comicCover,
                                        borderRadius: 10, thumbnail: true),
                                  ),
                                  Positioned(
                                    left: 6,
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text('第${item.page}页'.i18n,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.comicName.i18n,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(item.chapterName.i18n,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
