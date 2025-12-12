import 'package:dio/dio.dart';

class AppClient {
  static final baseUrl = "https://mind.apurvabraj.space/api/";
  static final dio = Dio(
    BaseOptions(   
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
}
