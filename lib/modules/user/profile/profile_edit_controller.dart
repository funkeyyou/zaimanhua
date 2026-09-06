import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/user_service.dart';

/// 个人资料编辑
///
/// 官方接口：GET /u_center/personal/info/get 取资料，
/// POST /u_center/personal/info/edit 编辑（栏位名与 get 相同），
/// 昵称另走 setting/check_can_modify_name + user/checkNickName + setting/modify_name。
class ProfileEditController extends BaseController {
  final UserRequest request = UserRequest();

  final nickname = ''.obs;
  final description = ''.obs;
  final sex = 0.obs;
  final birthday = ''.obs;
  final address = ''.obs;
  final photo = ''.obs;

  /// 昵称还能不能改（官方有次数限制）
  final canModifyName = false.obs;

  @override
  void onInit() {
    load();
    super.onInit();
  }

  Future<void> load() async {
    if (!UserService.instance.logined.value) {
      pageError.value = true;
      errorMsg.value = "请先登录".i18n;
      pageLoadding.value = false;
      return;
    }
    try {
      pageLoadding.value = true;
      pageError.value = false;
      var info = await request.personalInfo();
      nickname.value = info['nickname']?.toString() ?? '';
      description.value = info['description']?.toString() ?? '';
      sex.value = int.tryParse(info['sex']?.toString() ?? '') ?? 0;
      birthday.value = info['birthday']?.toString() ?? '';
      address.value = info['address']?.toString() ?? '';
      photo.value = info['photo']?.toString() ?? '';
      canModifyName.value = await request.canModifyNickName();
    } catch (e) {
      Log.logPrint(e);
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }

  /// 编辑单一栏位后送出
  Future<void> _save(String field, dynamic value) async {
    try {
      SmartDialog.showLoading();
      await request.editPersonalInfo({field: value});
      SmartDialog.showToast("已保存".i18n);
      await load();
      UserService.instance.refreshProfile();
    } catch (e) {
      SmartDialog.showToast(e.toString().i18n);
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<void> editDescription() async {
    var text = await _inputDialog(
      title: "个性签名".i18n,
      initial: description.value,
      maxLength: 50,
    );
    if (text == null) return;
    await _save('description', text);
  }

  Future<void> editAddress() async {
    var text = await _inputDialog(
      title: "所在地".i18n,
      initial: address.value,
      maxLength: 30,
    );
    if (text == null) return;
    await _save('address', text);
  }

  Future<void> editSex() async {
    var value = await Get.dialog<int>(
      SimpleDialog(
        title: Text("性别".i18n),
        children: [
          for (var item in const [[0, '保密'], [1, '男'], [2, '女']])
            SimpleDialogOption(
              onPressed: () => Get.back(result: item[0] as int),
              child: Text((item[1] as String).i18n),
            ),
        ],
      ),
    );
    if (value == null) return;
    await _save('sex', value);
  }

  Future<void> editBirthday() async {
    var now = DateTime.now();
    var current = DateTime.tryParse(birthday.value) ?? DateTime(2000, 1, 1);
    var picked = await showDatePicker(
      context: Get.context!,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    var month = picked.month.toString().padLeft(2, '0');
    var day = picked.day.toString().padLeft(2, '0');
    await _save('birthday', '${picked.year}-$month-$day');
  }

  /// 昵称：先问官方能不能改，再检查有没有被占用
  Future<void> editNickname() async {
    if (!canModifyName.value) {
      SmartDialog.showToast("官方目前不允许修改昵称".i18n);
      return;
    }
    var text = await _inputDialog(
      title: "昵称".i18n,
      initial: nickname.value,
      maxLength: 20,
    );
    if (text == null || text.isEmpty || text == nickname.value) return;
    try {
      SmartDialog.showLoading();
      if (!await request.checkNickName(text)) {
        SmartDialog.showToast("这个昵称不能用".i18n);
        return;
      }
      await request.modifyNickName(text);
      SmartDialog.showToast("已保存".i18n);
      await load();
      UserService.instance.refreshProfile();
    } catch (e) {
      SmartDialog.showToast(e.toString().i18n);
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 换头像：选图 → 上传 → 需要的话再设定回资料
  Future<void> editAvatar() async {
    try {
      var file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'image',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
          ),
        ],
      );
      if (file == null) return;
      SmartDialog.showLoading();
      var bytes = await file.readAsBytes();
      var url = await request.uploadAvatar(bytes, file.name);
      if (url.isNotEmpty && url != photo.value) {
        try {
          await request.editPersonalInfo({'photo': url});
        } catch (e) {
          Log.logPrint(e);
        }
      }
      await load();
      UserService.instance.refreshProfile();
      SmartDialog.showToast(
        photo.value == url ? "头像已更新".i18n : "已上传，官方没有套用这张图".i18n,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString().i18n);
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<String?> _inputDialog({
    required String title,
    required String initial,
    required int maxLength,
  }) {
    var controller = TextEditingController(text: initial);
    return Get.dialog<String>(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: maxLength,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("取消".i18n),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: Text("保存".i18n),
          ),
        ],
      ),
    );
  }
}
