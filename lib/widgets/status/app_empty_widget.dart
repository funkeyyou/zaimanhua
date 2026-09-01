import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:lottie/lottie.dart';
import 'package:zai_x/app/i18n.dart';

class AppEmptyWidget extends StatelessWidget {
  final Function()? onRefresh;
  const AppEmptyWidget({this.onRefresh, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          onRefresh?.call();
        },
        child: Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LottieBuilder.asset(
                'assets/lotties/empty.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              Text(
                "这里什么都没有".i18n,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
