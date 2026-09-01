import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/user/comment/user_comment_view.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class UserCommentPage extends StatelessWidget {
  final int userId;
  UserCommentPage(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(right: 56),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: AppStyle.edgeInsetsH24,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Get.isDarkMode ? Colors.white70 : Colors.black87,
              tabs: [
                Tab(text: "漫画".i18n),
                Tab(text: "小说".i18n),
                Tab(text: "新闻".i18n),
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
