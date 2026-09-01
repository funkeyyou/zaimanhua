import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zai_x/app/log.dart';
import 'package:get/get.dart';

class NovelHorizontalReader extends StatefulWidget {
  final String text;
  final EdgeInsets? padding;
  final TextStyle style;
  final PageController? controller;
  final bool reverse;
  final Function(int index, int max)? onPageChanged;
  const NovelHorizontalReader(
    this.text, {
    required this.style,
    this.controller,
    this.padding,
    this.reverse = false,
    this.onPageChanged,
    super.key,
  });

  @override
  State<NovelHorizontalReader> createState() => _NovelHorizontalReaderState();
}

class _NovelHorizontalReaderState extends State<NovelHorizontalReader>
    with WidgetsBindingObserver {
  List<List<String>> textPages = [];
  Size _lastSize = const Size(0, 0);
  TextStyle textStyle = const TextStyle();
  double maxWidth = 500;
  double maxHeight = 800;
  String text = "";
  double fontHieght = 16.0;
  EdgeInsets padding = EdgeInsets.zero;

  int index = 0;

  @override
  void initState() {
    super.initState();
    _lastSize = Get.size;
    WidgetsBinding.instance.addObserver(this);
    resetText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_lastSize != Get.size) {
      _lastSize = Get.size;
      resetText();
    }
  }

  void resetText() {
    text = widget.text;
    textStyle = widget.style;

    padding = widget.padding ?? EdgeInsets.zero;
    maxWidth = Get.width - padding.left - padding.right;
    maxHeight = Get.height -
        //AppStyle.statusBarHeight -
        //AppStyle.bottomBarHeight -
        padding.top -
        padding.bottom;
    if (text.isEmpty) {
      setState(() {
        textPages = [];
      });
      return;
    }
    initText();
  }

  @override
  void didUpdateWidget(covariant NovelHorizontalReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.text != oldWidget.text) ||
        widget.style != oldWidget.style ||
        widget.padding != oldWidget.padding) {
      if (widget.text != oldWidget.text) {
        index = 0;
        setState(() {
          textPages = [];
        });
      }
      resetText();
    }
  }

  /// 分割文字
  Future initText() async {
    var startTime = DateTime.now().millisecondsSinceEpoch;
    var fontSize = (textStyle.fontSize ?? 16).toDouble();
    var lineHeight = textStyle.height ?? 1.5;
    // 計算出出各個型別的大小
    Size chineseCharSize = calcFontSize("中",
        fontSize: fontSize.toDouble(), lineHeight: lineHeight);
    fontHieght = chineseCharSize.height;
    Size englishCharSize = calcFontSize("z",
        fontSize: fontSize.toDouble(), lineHeight: lineHeight);
    Size symbolCharSize = calcFontSize(",",
        fontSize: fontSize.toDouble(), lineHeight: lineHeight);
    Size spaceCharSize = calcFontSize(" ",
        fontSize: fontSize.toDouble(), lineHeight: lineHeight);
    // 計算可渲染的最大行數
    int maxLine = (maxHeight / chineseCharSize.height).floor();
    // 在新執行緒中進行分頁

    var pages = await compute(
      splitText,
      ComputeParameter(
        content: text,
        fontSize: fontSize.toDouble(),
        width: maxWidth,
        maxLine: maxLine,
        lineHeight: lineHeight,
        chineseWidth: chineseCharSize.width,
        englishWidth: englishCharSize.width,
        symbolWidth: symbolCharSize.width,
        spaceWidth: spaceCharSize.width,
      ),
    );
    Log.d("耗時:${DateTime.now().millisecondsSinceEpoch - startTime}ms");
    Log.d("頁數:${pages.length}");
    widget.onPageChanged?.call(index, pages.length);
    setState(() {
      textPages = pages;
    });
  }

  /// 文字處理、分頁
  /// 由於TextPainter.layout無法在isolate中使用，且計算極其耗時，所以手動寫一個處理方法
  /// 處理一段12萬字的文字，TextPainter.layout需要耗時16000ms左右；此方法則可以到1600ms，且能用isolate
  /// 該方法還不是很完善，符號換行等還未實現，速度也可以再最佳化
  static List<List<String>> splitText(
    ComputeParameter parameter,
  ) {
    var str = parameter.content;

    Log.w("字數:${str.length}");

    // 定義正規表示式（匹配中文字元、英文單詞、符號、全形符號、數字串）
    //RegExp reg = RegExp(r"([\u4e00-\u9fa5]|\b\w+\b|\x20|　|\S|\p{Han}|\n)");
    RegExp reg = RegExp(r"([^\x00-\xff]|\b\w+\b|\p{P}|\x20|\S|\u3000|\n)");

    // 使用正規表示式分割字串
    List<String> resultList =
        reg.allMatches(str).map((match) => match.group(0) ?? "").toList();
    List<CharInfo> chars = [];
    final chineseExp = RegExp(r"[^\x00-\xff]");
    final wordExp = RegExp(r"\w+");

    final symbolExp = RegExp(r"\p{P}");

    final newLineExp = RegExp(r"\n");

    for (var item in resultList) {
      if (chineseExp.hasMatch(item)) {
        chars.add(
          CharInfo(
            text: item,
            width: parameter.chineseWidth,
            type: CharType.chinese,
          ),
        );
        continue;
      }
      if (wordExp.hasMatch(item)) {
        chars.add(
          CharInfo(
              text: item,
              width: parameter.englishWidth * item.length,
              type: CharType.word),
        );
        continue;
      }
      if (newLineExp.hasMatch(item)) {
        chars.add(
          CharInfo(text: "", width: 0, type: CharType.newline),
        );
        continue;
      }
      if (item == " ") {
        chars.add(
          CharInfo(
            text: item,
            width: parameter.spaceWidth,
            type: CharType.symbol,
          ),
        );
        continue;
      }
      if (symbolExp.hasMatch(item)) {
        chars.add(
          CharInfo(
              text: item, width: parameter.symbolWidth, type: CharType.symbol),
        );
        continue;
      }

      chars.add(
        CharInfo(
          text: item,
          width: parameter.symbolWidth,
          type: CharType.symbol,
        ),
      );
    }

    //開始分頁
    List<String> rows = [];
    List<List<String>> pages = [];
    String rowStr = "";
    double rowWidth = 0;
    for (var item in chars) {
      //是否超出了最大行數
      if (rows.length >= parameter.maxLine) {
        pages.add(rows);
        rows = [];
      }
      //新行
      if (item.type == CharType.newline) {
        rows.add(rowStr);
        rowStr = "";
        rowWidth = 0;
        //rowStr += item.text;
        continue;
      }
      //是否超出了最大寬度
      if ((rowWidth + item.width) > parameter.width) {
        rows.add(rowStr);
        rowStr = "";
        rowWidth = 0;
      }
      rowStr += item.text;
      rowWidth += item.width;
    }
    rows.add(rowStr);
    pages.add(rows);
    if (pages.length == 1 &&
        pages.first.length == 1 &&
        pages.first.first.isEmpty) {
      return [];
    }
    return pages;
  }

  /// 計算文字大小
  Size calcFontSize(
    String text, {
    required double fontSize,
    required double lineHeight,
  }) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          locale: PlatformDispatcher.instance.locale,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: 200);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    return textPages.isEmpty
        ? Center(
            child: Text(
              "載入中...",
              style: widget.style,
            ),
          )
        : PageView.builder(
            controller: widget.controller,
            reverse: widget.reverse,
            itemCount: textPages.length,
            onPageChanged: (e) {
              index = e;
              widget.onPageChanged?.call(e, textPages.length);
            },
            itemBuilder: (_, i) {
              return Container(
                padding: widget.padding ?? EdgeInsets.zero,
                child: CustomPaint(
                  painter: NovelTextPainter(
                    textPages[i],
                    style: widget.style,
                    fontHieght: fontHieght,
                  ),
                ),
              );
            },
          );
  }
}

class NovelTextPainter extends CustomPainter {
  final TextStyle style;
  final double fontHieght;
  final List<String> text;
  NovelTextPainter(
    this.text, {
    required this.style,
    required this.fontHieght,
  });
  @override
  void paint(Canvas canvas, Size size) {
    var startTime = DateTime.now().millisecondsSinceEpoch;

    var i = 0;
    for (var item in text) {
      TextSpan textSpan = TextSpan(
        text: item,
        style: style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        maxLines: 1,
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.width);

      final offset = Offset(0, i * fontHieght);
      textPainter.paint(canvas, offset);

      i++;
    }
    Log.d("繪製單頁耗時:${DateTime.now().millisecondsSinceEpoch - startTime}ms");
  }

  @override
  bool shouldRepaint(covariant NovelTextPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.text != text ||
        oldDelegate.fontHieght != fontHieght;
  }
}

enum CharType {
  //中文及全形符號
  chinese,
  //單詞
  word,
  //數字
  number,
  //符號
  symbol,
  //換行符
  newline
}

class CharInfo {
  CharType type;
  String text;
  double width;
  CharInfo({
    required this.text,
    required this.width,
    required this.type,
  });
  @override
  String toString() {
    return "($type,$width,$text)";
  }
}

class ComputeParameter {
  String content;
  double width;
  double fontSize;
  double lineHeight;
  int maxLine;
  double chineseWidth;
  double englishWidth;
  double symbolWidth;
  double spaceWidth;
  ComputeParameter({
    required this.content,
    required this.fontSize,
    required this.width,
    required this.maxLine,
    required this.lineHeight,
    required this.chineseWidth,
    required this.englishWidth,
    required this.symbolWidth,
    required this.spaceWidth,
  });
}
