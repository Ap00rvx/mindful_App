import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_remote_data_source.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteRemoteDataSource remoteDataSource;

  NoteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Note>> getNotes() async {
    return await remoteDataSource.getNotes();
  }

  @override
  Future<Note> createNote(String content) async {
    return await remoteDataSource.createNote(content);
  }
}
