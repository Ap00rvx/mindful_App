import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> createNote(String content);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final Dio dio;
  final SupabaseClient supabaseClient;

  NoteRemoteDataSourceImpl({required this.dio, required this.supabaseClient});

  @override
  Future<List<NoteModel>> getNotes() async {
    final token = supabaseClient.auth.currentSession?.accessToken;
    if (token == null) throw Exception('User not authenticated');

    final response = await dio.get(
      'notes',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notesJson = response.data['notes'];
      return notesJson.map((json) => NoteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  @override
  Future<NoteModel> createNote(String content) async {
    final token = supabaseClient.auth.currentSession?.accessToken;
    if (token == null) throw Exception('User not authenticated');

    final response = await dio.post(
      'notes',
      data: {'content': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return NoteModel.fromJson(response.data['note']);
    } else {
      throw Exception('Failed to create note');
    }
  }
}
