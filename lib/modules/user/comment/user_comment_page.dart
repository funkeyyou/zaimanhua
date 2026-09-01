import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/user/comment/user_comment_view.dart';
import 'package:get/get.dart';

class UserCommentPage extends StatelessWidget {
  final int userId;
  const UserCommentPage(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 56),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: AppStyle.edgeInsetsH24,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Get.isDarkMode ? Colors.white70 : Colors.black87,
              tabs: const [
                Tab(text: "漫畫"),
                Tab(text: "小說"),
                Tab(text: "新聞"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            UserCommentView(type: 0, userId: userId),
            UserCommentView(type: 1, userId: userId),
            UserCommentView(type: 2, userId: userId),
          ],
        ),
      ),
    );
  }
}
