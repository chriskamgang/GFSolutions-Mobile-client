import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await StorageService.deleteToken();
        }
        return handler.next(error);
      },
    ));
  }

  // GET
  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return dio.get(path, queryParameters: params);
  }

  // POST
  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  // PATCH
  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }

  // PUT
  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  // DELETE
  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  // Upload file
  Future<Response> upload(String path, String filePath, {String fieldName = 'file', Map<String, dynamic>? data}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?data,
    });
    return dio.post(path, data: formData);
  }
}
