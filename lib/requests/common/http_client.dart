import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:zai_x/app/app_error.dart';
import 'package:zai_x/requests/common/api.dart';
import 'package:zai_x/requests/common/custom_interceptor.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/app/i18n.dart';

class HttpClient {
  static HttpClient? _httpUtil;

  static HttpClient get instance {
    _httpUtil ??= HttpClient();
    return _httpUtil!;
  }

  late Dio dio;
  HttpClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(CustomInterceptor());
  }

  /// 检查接口返回码
  /// 登录失效(errno==99)时自动清除登录状态并弹出重新登录
  static void checkErrno(Map data) {
    var errno = int.tryParse(data['errno'].toString()) ?? 0;
    if (errno == 99) {
      unawaited(UserService.instance.onLoginRequired());
    }
    if (errno != 0) {
      throw AppError(data['errmsg'].toString(), code: errno);
    }
  }

  /// Get请求
  /// * [path] 请求链接
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  /// * [needLogin] 是否需要登录
  /// * [withDefaultParameter] 是否需要带上一些默认参数
  /// * [responseType] 返回的类型
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool withDefaultParameter = true,
    bool needLogin = false,
    ResponseType responseType = ResponseType.json,
    bool checkCode = false,
  }) async {
    Map<String, dynamic> header = {};
    queryParameters ??= <String, dynamic>{};
    var query = Api.getDefaultParameter(withUid: needLogin);
    if (withDefaultParameter) {
      queryParameters.addAll(query);
    }
    if (needLogin) {
      if (UserService.instance.logined.value) {
        header['Authorization'] = 'Bearer ${UserService.instance.dmzjToken}';
      }
    }

    try {
      var result = await dio.get(
        baseUrl + path,
        queryParameters: queryParameters,
        options: Options(
          responseType: responseType,
          headers: header,
        ),
        cancelToken: cancel,
      );
      if (checkCode && result.data is Map) {
        var data = result.data as Map;
        checkErrno(data);
        return result.data['data'];
      }
      return result.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      if (e.type == DioExceptionType.badResponse) {
        return throw AppError("请求失败：${e.response?.statusCode ?? -1}".i18n);
      }
      throw AppError("请求失败,请检查网络".i18n);
    }
  }

  /// Get 请求,返回JSON
  /// * [path] 请求链接
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  /// * [needLogin] 是否需要登录
  /// * [withDefaultParameter] 是否需要带上一些默认参数
  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool withDefaultParameter = true,
    bool needLogin = false,
    bool checkCode = false,
  }) async {
    var result = await get(
      path,
      queryParameters: queryParameters,
      baseUrl: baseUrl,
      cancel: cancel,
      withDefaultParameter: withDefaultParameter,
      needLogin: needLogin,
      responseType: ResponseType.json,
      checkCode: checkCode,
    );
    if (result is Map || result is List) {
      return result;
    } else if (result is String) {
      return jsonDecode(result);
    }
    return result;
  }

  /// Get 请求,返回Text
  /// * [path] 请求链接
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  /// * [needLogin] 是否需要登录
  /// * [withDefaultParameter] 是否需要带上一些默认参数
  Future<dynamic> getText(
    String path, {
    Map<String, dynamic>? queryParameters,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool withDefaultParameter = true,
    bool needLogin = false,
  }) async {
    return await get(
      path,
      queryParameters: queryParameters,
      baseUrl: baseUrl,
      cancel: cancel,
      withDefaultParameter: withDefaultParameter,
      needLogin: needLogin,
      responseType: ResponseType.plain,
    );
  }

  /// Get 请求,返回解密后Bytes
  /// * [path] 请求链接
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  /// * [needLogin] 是否需要登录
  /// * [withDefaultParameter] 是否需要带上一些默认参数
  Future<Uint8List> getEncryptV4(
    String path, {
    Map<String, dynamic>? queryParameters,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool withDefaultParameter = true,
    bool needLogin = false,
  }) async {
    var result = await get(
      path,
      queryParameters: queryParameters,
      baseUrl: baseUrl,
      cancel: cancel,
      withDefaultParameter: withDefaultParameter,
      needLogin: needLogin,
      responseType: ResponseType.plain,
    );
    var resultBytes = Api.decryptV4(result);
    return resultBytes;
  }

  /// Get 请求,返回byte
  /// * [path] 请求链接
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  /// * [needLogin] 是否需要登录
  /// * [withDefaultParameter] 是否需要带上一些默认参数
  Future<dynamic> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool withDefaultParameter = true,
    bool needLogin = false,
  }) async {
    return await get(
      path,
      queryParameters: queryParameters,
      baseUrl: baseUrl,
      cancel: cancel,
      withDefaultParameter: withDefaultParameter,
      needLogin: needLogin,
      responseType: ResponseType.bytes,
    );
  }

  /// Post请求，返回Map
  /// * [path] 请求链接
  /// * [data] 发送数据
  /// * [queryParameters] 请求参数
  /// * [cancel] 任务取消Token
  Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    String baseUrl = Api.BASE_URL,
    CancelToken? cancel,
    bool formUrlEncoded = false,
    bool checkCode = false,
    bool needLogin = false,
  }) async {
    Map<String, dynamic> header = {};
    queryParameters ??= {};
    if (needLogin) {
      if (UserService.instance.logined.value) {
        header['Authorization'] = 'Bearer ${UserService.instance.dmzjToken}';
      }
    }
    try {
      var result = await dio.post(
        baseUrl + path,
        queryParameters: queryParameters,
        data: data,
        options: Options(
          responseType: ResponseType.json,
          headers: header,
          contentType:
              formUrlEncoded ? Headers.formUrlEncodedContentType : null,
        ),
        cancelToken: cancel,
      );
      var jsonMap = result.data;
      if (jsonMap is String) {
        jsonMap = jsonDecode(jsonMap);
      }
      if (checkCode) {
        var data = result.data as Map;
        checkErrno(data);
        return result.data['data'];
      }
      return result.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        return throw AppError("请求失败:状态码：${e.response?.statusCode ?? -1}".i18n);
      }
      throw AppError("请求失败,请检查网络".i18n);
    }
  }
}
