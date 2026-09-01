import 'package:flutter/material.dart';
import 'package:zai_x/app/app_color.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:get/get.dart';

import 'package:webview_flutter/webview_flutter.dart';

class WebViewPageController extends BaseController {
  final String url;
  WebViewPageController(this.url);
  final WebViewController webViewController = WebViewController();
  var title = "載入中".obs;
  @override
  void onInit() {
    initWebView();
    super.onInit();
  }

  void initWebView() async {
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

    webViewController.setBackgroundColor(
        Get.isDarkMode ? Colors.black : AppColor.backgroundColor);
    webViewController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          pageLoadding.value = true;
        },
        onPageFinished: (String url) async {
          pageLoadding.value = false;
          title.value = (await webViewController.getTitle()) ?? "";
        },
        onNavigationRequest: (NavigationRequest request) {
          var uri = Uri.parse(request.url);
          Log.d(request.url);
          if (uri.scheme == "https" || uri.scheme == "http") {
            return NavigationDecision.navigate;
          }

          return NavigationDecision.prevent;
        },
      ),
    );
    webViewController.loadRequest(Uri.parse(url), headers: {
      "Cookie": UserService.instance.userProfile.value?.cookieVal ?? "",
    });

    /// TODO 無法載入Mixed Content
    /// 19年的問題了，Flutter還沒解決...
    /// https://github.com/flutter/flutter/issues/43595
  }

  void refreshWeb() {
    webViewController.reload();
  }
}
