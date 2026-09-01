import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:zai_x/app/app_error.dart';
import 'package:zai_x/requests/common/api.dart';
import 'package:zai_x/requests/common/custom_interceptor.dart';
import 'package:zai_x/services/user_service.dart';

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

  /// 檢查介面返回碼
  /// 登入失效(errno==99)時自動清除登入狀態並彈出重新登入
  static void checkErrno(Map data) {
    var errno = int.tryParse(data['errno'].toString()) ?? 0;
    if (errno == 99) {
      unawaited(UserService.instance.onLoginRequired());
    }
    if (errno != 0) {
      throw AppError(data['errmsg'].toString(), code: errno);
    }
  }

  /// Get請求
  /// * [path] 請求連結
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
  /// * [needLogin] 是否需要登入
  /// * [withDefaultParameter] 是否需要帶上一些預設引數
  /// * [responseType] 返回的型別
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
        return throw AppError("請求失敗：${e.response?.statusCode ?? -1}");
      }
      throw AppError("請求失敗,請檢查網路");
    }
  }

  /// Get 請求,返回JSON
  /// * [path] 請求連結
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
  /// * [needLogin] 是否需要登入
  /// * [withDefaultParameter] 是否需要帶上一些預設引數
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

  /// Get 請求,返回Text
  /// * [path] 請求連結
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
  /// * [needLogin] 是否需要登入
  /// * [withDefaultParameter] 是否需要帶上一些預設引數
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

  /// Get 請求,返回解密後Bytes
  /// * [path] 請求連結
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
  /// * [needLogin] 是否需要登入
  /// * [withDefaultParameter] 是否需要帶上一些預設引數
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

  /// Get 請求,返回byte
  /// * [path] 請求連結
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
  /// * [needLogin] 是否需要登入
  /// * [withDefaultParameter] 是否需要帶上一些預設引數
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

  /// Post請求，返回Map
  /// * [path] 請求連結
  /// * [data] 傳送資料
  /// * [queryParameters] 請求引數
  /// * [cancel] 任務取消Token
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
        return throw AppError("請求失敗:狀態碼：${e.response?.statusCode ?? -1}");
      }
      throw AppError("請求失敗,請檢查網路");
    }
  }
}
