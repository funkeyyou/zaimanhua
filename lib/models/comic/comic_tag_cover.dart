/// 本地标签封面
///
/// 被服务端隐藏的标签在 /comic/filter/category 里没有 cover 字段，
/// 分类页只能显示灰底占位。这里给它们配上本仓库自制的原创封面图。
///
/// 这个表是手工维护的，不会被 tools/tags/fetch_tags.py 覆盖。
/// 新增标签时把图片放进 assets/category/，再在这里补一行。
const Map<int, String> kComicTagCoverAsset = <int, String>{
  5: "assets/category/huanle.webp", // 欢乐向
  14: "assets/category/kongbu.webp", // 惊悚
  16: "assets/category/qita.webp", // 其他
  3242: "assets/category/shenghuo.webp", // 亲情
  3243: "assets/category/baihe.webp", // ゆり
  3246: "assets/category/chunai.webp", // 纯爱
  3250: "assets/category/lishi.webp", // 历史
  3251: "assets/category/zhanzheng.webp", // 战争
  3253: "assets/category/zhaixi.webp", // 宅系
  3324: "assets/category/wuxia.webp", // 武侠
  3325: "assets/category/jizhan.webp", // 机战
  3326: "assets/category/yinyue.webp", // 音乐舞蹈
  18522: "assets/category/aamanhua.webp", // AA
  23323: "assets/category/furui.webp", // 福瑞
  30788: "assets/category/richang.webp", // 日常
  31137: "assets/category/huaji.webp", // 画集
  34093: "assets/category/2025dong.webp", // 2025冬
  36172: "assets/category/2026chun.webp", // 2026春
};
