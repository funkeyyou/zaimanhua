import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/user/profile/profile_edit_controller.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';

/// 个人资料编辑
class ProfileEditPage extends StatelessWidget {
  ProfileEditPage({super.key})
      : controller = Get.put(
          ProfileEditController(),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  final ProfileEditController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("个人资料".i18n)),
      body: Obx(() {
        if (controller.pageLoadding.value) {
          return const AppLoaddingWidget();
        }
        if (controller.pageError.value) {
          return AppErrorWidget(
            errorMsg: controller.errorMsg.value,
            onRefresh: controller.load,
          );
        }
        return ListView(
          children: [
            ListTile(
              title: Text("头像".i18n),
              subtitle: Text("官方接口不开放换头像，请在官方 App 更换".i18n),
              trailing: controller.photo.value.isEmpty
                  ? null
                  : NetImage(
                      controller.photo.value,
                      width: 44,
                      height: 44,
                      borderRadius: 22,
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text("昵称".i18n),
              subtitle: Text(
                controller.canModifyName.value
                    ? controller.nickname.value
                    : '${controller.nickname.value}  ${"（官方暂不开放修改）".i18n}',
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: controller.editNickname,
            ),
            ListTile(
              title: Text("个性签名".i18n),
              subtitle: Text(
                controller.description.value.isEmpty
                    ? "还没有填写".i18n
                    : controller.description.value.i18n,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: controller.editDescription,
            ),
            ListTile(
              title: Text("性别".i18n),
              subtitle: Text(_sexText(controller.sex.value)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: controller.editSex,
            ),
            ListTile(
              title: Text("生日".i18n),
              subtitle: Text(
                controller.birthday.value.isEmpty
                    ? "还没有填写".i18n
                    : controller.birthday.value,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: controller.editBirthday,
            ),
            ListTile(
              title: Text("所在地".i18n),
              subtitle: Text(
                controller.address.value.isEmpty
                    ? "还没有填写".i18n
                    : controller.address.value.i18n,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: controller.editAddress,
            ),
          ],
        );
      }),
    );
  }

  String _sexText(int sex) {
    switch (sex) {
      case 1:
        return "男".i18n;
      case 2:
        return "女".i18n;
      default:
        return "保密".i18n;
    }
  }
}
