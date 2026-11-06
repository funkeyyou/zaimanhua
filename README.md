# comic-index

再漫画X「本地漫画索引」的资料分支，由 `.github/workflows/comic_index.yml` 每天自动更新
（单一提交、每次强制覆盖）。产生工具：`tools/comic_index/build_comic_index.dart`。

- `comic_index.tsv.gz`：全站作品清单（id、标题、别名、作者、旗标、状态、热度）
- `comic_index.json`：版本、笔数与档案大小

App 会从这里下载最新清单，让官方搜索找不到的神隐等作品也能被搜到。
