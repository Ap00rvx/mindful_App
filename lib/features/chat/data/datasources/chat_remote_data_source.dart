import 'package:dio/dio.dart';
import 'package:mindful_app/core/network/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatModel>> getChats();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? AppClient.dio;

  @override
  Future<List<ChatModel>> getChats() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await dio.get(
      'chats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> chatsJson = response.data['chats'];
      return chatsJson.map((json) => ChatModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chats');
    }
  }
}
