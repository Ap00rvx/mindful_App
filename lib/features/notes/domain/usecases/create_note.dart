import '../entities/note.dart';
import '../repositories/note_repository.dart';

class CreateNote {
  final NoteRepository repository;

  CreateNote(this.repository);

  Future<Note> call(String content) async {
    return await repository.createNote(content);
  }
}
