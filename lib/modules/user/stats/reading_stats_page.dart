import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/services/reading_stats_service.dart';

/// 阅读统计：全部在本机累计，不上传
class ReadingStatsPage extends StatelessWidget {
  const ReadingStatsPage({super.key});

  ReadingStatsService get stats => ReadingStatsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("阅读统计".i18n),
        actions: [
          TextButton(
            onPressed: () async {
              if (await DialogUtils.showAlertDialog(
                "清空后无法恢复，确定要清除吗？".i18n,
                title: "清除阅读统计".i18n,
              )) {
                await stats.clear();
              }
            },
            child: Text("清除".i18n),
          ),
        ],
      ),
      body: Obx(() {
        // 读一下 revision，看完漫画回到这页就会自动更新
        stats.revision.value;
        var today = stats.today;
        var week = stats.recentDays(7);
        var total = stats.total;
        var weekChapters =
            week.fold<int>(0, (value, item) => value + item.chapters);
        var weekSeconds =
            week.fold<int>(0, (value, item) => value + item.seconds);
        return ListView(
          padding: AppStyle.edgeInsetsA12,
          children: [
            Row(
              children: [
                _card("今天".i18n, today.chapters, today.seconds),
                AppStyle.hGap12,
                _card("最近 7 天".i18n, weekChapters, weekSeconds),
              ],
            ),
            AppStyle.vGap12,
            Row(
              children: [
                _card("总计".i18n, total.chapters, total.seconds),
                AppStyle.hGap12,
                _streakCard(),
              ],
            ),
            AppStyle.vGap12,
            Padding(
              padding: AppStyle.edgeInsetsV8,
              child: Text("最近 7 天".i18n, style: Get.textTheme.titleSmall),
            ),
            _chart(week),
            AppStyle.vGap12,
            Padding(
              padding: AppStyle.edgeInsetsV8,
              child: Text("分类".i18n, style: Get.textTheme.titleSmall),
            ),
            ListTile(
              title: Text("漫画".i18n),
              trailing: Text(_chapterText(total.comicChapters)),
            ),
            ListTile(
              title: Text("小说".i18n),
              trailing: Text(_chapterText(total.novelChapters)),
            ),
            ListTile(
              title: Text("有阅读的天数".i18n),
              trailing: Text(_dayText(stats.activeDays)),
            ),
          ],
        );
      }),
    );
  }

  Widget _card(String title, int chapters, int seconds) {
    return Expanded(
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppStyle.vGap8,
            Text(
              _chapterText(chapters),
              style: Get.textTheme.titleLarge,
            ),
            AppStyle.vGap4,
            Text(
              _durationText(seconds),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard() {
    return Expanded(
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "连续阅读".i18n,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppStyle.vGap8,
            Text(
              _dayText(stats.streak),
              style: Get.textTheme.titleLarge,
            ),
            AppStyle.vGap4,
            Text(
              "今天没看不会中断".i18n,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 简单的长条图，不引额外的图表套件
  Widget _chart(List<DailyReadingStat> days) {
    var max = days.fold<int>(1, (value, item) {
      return item.chapters > value ? item.chapters : value;
    });
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days
            .map(
              (e) => Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      e.chapters == 0 ? "" : e.chapters.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    AppStyle.vGap4,
                    Container(
                      height: 80.0 * e.chapters / max,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: e.chapters == 0
                            ? Colors.grey.withValues(alpha: .2)
                            : Get.theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      constraints: const BoxConstraints(minHeight: 4),
                    ),
                    AppStyle.vGap4,
                    Text(
                      _weekdayText(e.day),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _chapterText(int chapters) => '$chapters ${"话".i18n}';

  String _dayText(int days) => '$days ${"天".i18n}';

  String _durationText(int seconds) {
    if (seconds < 60) {
      return '$seconds ${"秒".i18n}';
    }
    var minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes ${"分钟".i18n}';
    }
    var hours = minutes ~/ 60;
    var rest = minutes % 60;
    return '$hours ${"小时".i18n} $rest ${"分钟".i18n}';
  }

  String _weekdayText(DateTime day) {
    const names = ["一", "二", "三", "四", "五", "六", "日"];
    return names[(day.weekday - 1).clamp(0, 6)].i18n;
  }
}
