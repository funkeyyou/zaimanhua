import 'package:flutter/material.dart';
import 'package:zai_x/app/app_color.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/user/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';

class SettingsPage extends StatelessWidget {
  final int index;
  SettingsPage({required this.index, super.key});
  final controller = Get.put<SettingsController>(SettingsController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: index,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 56),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Get.isDarkMode ? Colors.white70 : Colors.black87,
              tabs: const [
                Tab(text: "常規"),
                Tab(text: "漫畫"),
                Tab(text: "小說"),
                Tab(text: "下載"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            buildGeneralSettings(),
            buildComicSettings(),
            buildNovelSettings(),
            buildDownloadSettings(),
          ],
        ),
      ),
    );
  }

  Widget buildGeneralSettings() {
    return Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          ListTile(
            title: const Text("清除圖片快取"),
            subtitle: Text(controller.imageCacheSize.value),
            trailing: OutlinedButton(
              onPressed: () {
                controller.cleanImageCache();
              },
              child: const Text("清除"),
            ),
          ),
          ListTile(
            title: const Text("清除小說快取"),
            subtitle: Text(controller.novelCacheSize.value),
            trailing: OutlinedButton(
              onPressed: () {},
              child: const Text("清除"),
            ),
          ),
          // SwitchListTile(
          //   value: controller.settings.comicSearchUseWebApi.value,
          //   onChanged: (e) {
          //     controller.settings.setComicSearchUseWebApi(e);
          //   },
          //   title: const Text("使用Web介面搜尋漫畫"),
          //   subtitle: const Text("開啟後可以搜尋到更多漫畫"),
          // ),
          SwitchListTile(
            value: controller.settings.eInkMode.value,
            onChanged: (e) {
              controller.settings.setEInkMode(e);
            },
            title: const Text("E-Ink 模式"),
            subtitle: const Text("關閉翻頁動畫和首頁輪播，開啟音量鍵翻頁"),
          ),
          SwitchListTile(
            value: controller.settings.useSystemFontSize.value,
            onChanged: (e) {
              controller.settings.setUseSystemFontSize(e);
            },
            title: const Text("字型大小跟隨系統"),
            subtitle: const Text("開啟可能會有佈局錯亂"),
          ),
          SwitchListTile(
            value: controller.settings.collectHideComic.value,
            onChanged: (e) {
              controller.settings.setCollectHideComic(e);
            },
            title: const Text("自動收藏神隱漫畫"),
            subtitle: const Text("瀏覽神隱漫畫時自動新增到本機收藏"),
          ),
          SwitchListTile(
            value: controller.settings.readerVolumeKeyTurnPage.value,
            onChanged: (e) {
              controller.settings.setReaderVolumeKeyTurnPage(e);
            },
            title: const Text("音量鍵翻頁"),
          ),
        ],
      ),
    );
  }

  Widget buildComicSettings() {
    return Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SwitchListTile(
            value: controller.settings.comicReaderHD.value,
            onChanged: (e) {
              controller.settings.setComicReaderHD(e);
            },
            title: const Text("優先載入高畫質圖"),
            subtitle: const Text("部分單行本可能未分頁"),
          ),
          ListTile(
            title: const Text("閱讀方向"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setComicReaderDirection(0);
                  },
                  selected: controller.settings.comicReaderDirection.value == 0,
                  child: const Icon(Remix.arrow_right_line),
                ),
                AppStyle.hGap8,
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setComicReaderDirection(2);
                  },
                  selected: controller.settings.comicReaderDirection.value == 2,
                  child: const Icon(Remix.arrow_left_line),
                ),
                AppStyle.hGap8,
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setComicReaderDirection(1);
                  },
                  selected: controller.settings.comicReaderDirection.value == 1,
                  child: const Icon(Remix.arrow_down_line),
                )
              ],
            ),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderLeftHandMode.value,
            onChanged: (e) {
              controller.settings.setComicReaderLeftHandMode(e);
            },
            title: const Text("操作反轉"),
            subtitle: const Text("點選左側下一頁，右側上一頁"),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderFullScreen.value,
            onChanged: (e) {
              controller.settings.setComicReaderFullScreen(e);
            },
            title: const Text("全屏閱讀"),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderShowStatus.value,
            onChanged: (e) {
              controller.settings.setComicReaderShowStatus(e);
            },
            title: const Text("顯示狀態資訊"),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderShowViewPoint.value,
            onChanged: (e) {
              controller.settings.setComicReaderShowViewPoint(e);
            },
            title: const Text("顯示吐槽"),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderOldViewPoint.value,
            onChanged: (e) {
              controller.settings.setComicReaderOldViewPoint(e);
            },
            title: const Text("舊版吐槽"),
          ),
          SwitchListTile(
            value: controller.settings.comicReaderPageAnimation.value,
            onChanged: (e) {
              controller.settings.setComicReaderPageAnimation(e);
            },
            title: const Text("翻頁動畫"),
          ),
        ],
      ),
    );
  }

  Widget buildNovelSettings() {
    return Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          ListTile(
            title: const Text("閱讀方向"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setNovelReaderDirection(0);
                  },
                  selected: controller.settings.novelReaderDirection.value == 0,
                  child: const Icon(Remix.arrow_right_line),
                ),
                AppStyle.hGap8,
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setNovelReaderDirection(2);
                  },
                  selected: controller.settings.novelReaderDirection.value == 2,
                  child: const Icon(Remix.arrow_left_line),
                ),
                AppStyle.hGap8,
                buildSelectedButton(
                  onTap: () {
                    controller.settings.setNovelReaderDirection(1);
                  },
                  selected: controller.settings.novelReaderDirection.value == 1,
                  child: const Icon(Remix.arrow_down_line),
                )
              ],
            ),
          ),
          SwitchListTile(
            value: controller.settings.novelReaderLeftHandMode.value,
            onChanged: (e) {
              controller.settings.setNovelReaderLeftHandMode(e);
            },
            title: const Text("操作反轉"),
            subtitle: const Text("點選左側下一頁，右側上一頁"),
          ),
          // SwitchListTile(
          //   value: settings.novelReaderFullScreen.value,
          //   onChanged: (e) {
          //     settings.setNovelReaderFullScreen(e);
          //   },
          //   title: const Text("全屏閱讀"),
          // ),
          SwitchListTile(
            value: controller.settings.novelReaderShowStatus.value,
            onChanged: (e) {
              controller.settings.setNovelReaderShowStatus(e);
            },
            title: const Text("顯示狀態資訊"),
          ),
          SwitchListTile(
            value: controller.settings.novelReaderPageAnimation.value,
            onChanged: (e) {
              controller.settings.setNovelReaderPageAnimation(e);
            },
            title: const Text("翻頁動畫"),
          ),
          ListTile(
            title: const Text("字型大小"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    controller.settings.setNovelReaderFontSize(
                      controller.settings.novelReaderFontSize.value + 1,
                    );
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                  ),
                ),
                AppStyle.hGap12,
                Text("${controller.settings.novelReaderFontSize.value}"),
                AppStyle.hGap12,
                OutlinedButton(
                  onPressed: () {
                    controller.settings.setNovelReaderFontSize(
                      controller.settings.novelReaderFontSize.value - 1,
                    );
                  },
                  child: const Icon(
                    Icons.remove,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text("字型"),
            subtitle: Text(controller.settings.novelReaderFontName),
            onTap: controller.showNovelReaderFontDialog,
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ),
          ListTile(
            title: const Text("行距"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    controller.settings.setNovelReaderLineSpacing(
                      controller.settings.novelReaderLineSpacing.value + 0.1,
                    );
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                  ),
                ),
                AppStyle.hGap12,
                Text((controller.settings.novelReaderLineSpacing.value)
                    .toStringAsFixed(1)),
                AppStyle.hGap12,
                OutlinedButton(
                  onPressed: () {
                    controller.settings.setNovelReaderLineSpacing(
                      controller.settings.novelReaderLineSpacing.value - 0.1,
                    );
                  },
                  child: const Icon(
                    Icons.remove,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text("閱讀主題"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: AppColor.novelThemes.keys
                  .map(
                    (e) => GestureDetector(
                      onTap: () {
                        controller.settings.setNovelReaderTheme(e);
                      },
                      child: Container(
                        margin: AppStyle.edgeInsetsL8,
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: AppColor.novelThemes[e]!.first,
                          borderRadius: AppStyle.radius24,
                        ),
                        child: Visibility(
                          visible:
                              AppColor.novelThemes.keys.toList().indexOf(e) ==
                                  controller.settings.novelReaderTheme.value,
                          child: Icon(
                            Icons.check,
                            color: AppColor.novelThemes[e]!.last,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            margin: AppStyle.edgeInsetsV12,
            padding: AppStyle.edgeInsetsA8,
            decoration: BoxDecoration(
              borderRadius: AppStyle.radius4,
              color: AppColor
                  .novelThemes[controller.settings.novelReaderTheme.value]!
                  .first,
            ),
            child: Text(
              """這是一段測試文字，可以預覽上面的設定效果。

　　晉太元中，武陵人捕魚為業。緣溪行，忘路之遠近。忽逢桃花林，夾岸數百步，中無雜樹，芳草鮮美，落英繽紛。漁人甚異之，復前行，欲窮其林。
　　林盡水源，便得一山，山有小口，彷彿若有光。便舍船，從口入。初極狹，才通人。復行數十步，豁然開朗。土地平曠，屋舍儼然，有良田、美池、桑竹之屬。阡陌交通，雞犬相聞。其中往來種作，男女衣著，悉如外人。黃髮垂髫，並怡然自樂……""",
              //不需要跟隨系統
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(
                fontFamily: controller.settings.novelReaderFontFamily,
                fontSize:
                    controller.settings.novelReaderFontSize.value.toDouble(),
                height: controller.settings.novelReaderLineSpacing.value,
                color: AppColor
                    .novelThemes[controller.settings.novelReaderTheme.value]!
                    .last,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDownloadSettings() {
    return Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SwitchListTile(
            value: controller.settings.downloadAllowCellular.value,
            onChanged: (e) {
              controller.settings.setDownloadAllowCellular(e);
            },
            title: const Text("允許使用流量下載"),
          ),
          ListTile(
            title: const Text("漫畫最大任務數"),
            onTap: () {
              controller.setDownloadComicTask();
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.settings.downloadComicTaskCount.value == 0
                      ? "無限制"
                      : controller.settings.downloadComicTaskCount.toString(),
                ),
                AppStyle.hGap4,
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text("小說最大任務數"),
            onTap: () {
              controller.setDownloadNovelTask();
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.settings.downloadNovelTaskCount.value == 0
                      ? "無限制"
                      : controller.settings.downloadNovelTaskCount.toString(),
                ),
                AppStyle.hGap4,
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSelectedButton(
      {required Widget child, bool selected = false, Function()? onTap}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.blue : Colors.grey,
        side: BorderSide(
          color: selected ? Colors.blue : Colors.grey,
        ),
      ),
      onPressed: onTap,
      child: child,
    );
  }
}
