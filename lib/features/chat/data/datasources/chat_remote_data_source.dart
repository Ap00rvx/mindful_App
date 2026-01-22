import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:mindful_app/core/network/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatModel>> getChats();
  Stream<String> sendMessage(
    String message, {
    String? chatId,
    bool isTemporary = false,
    List<Map<String, dynamic>> history = const [],
  });
  Future<List<ChatMessageModel>> getChatMessages(String chatId);
  Future<ChatModel> createChat(String title);
  Future<void> deleteChat(String chatId);
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

  @override
  Stream<String> sendMessage(
    String message, {
    String? chatId,
    bool isTemporary = false,
    List<Map<String, dynamic>> history = const [],
  }) async* {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final request = http.Request('POST', Uri.parse('${AppClient.baseUrl}chat'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';

    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];

    request.body = jsonEncode({
      'messages': messages,
      if (chatId != null) 'chatId': chatId,
      'isTemporary': isTemporary,
    });

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }

    yield* response.stream.transform(utf8.decoder);
  }

  @override
  Future<List<ChatMessageModel>> getChatMessages(String chatId) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await dio.get(
      'chats/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = response.data['messages'];
      return messagesJson
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  @override
  Future<ChatModel> createChat(String title) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await dio.post(
      'chats',
      data: {'title': title},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChatModel.fromJson(response.data['chat']);
    } else {
      throw Exception('Failed to create chat');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await dio.delete(
      'chats/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat');
    }
  }
}
