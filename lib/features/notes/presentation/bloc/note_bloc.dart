import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/create_note.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetNotes getNotes;
  final CreateNote createNote;

  NoteBloc({required this.getNotes, required this.createNote})
    : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NoteState> emit) async {
    emit(NotesLoading());
    try {
      final notes = await getNotes();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onAddNote(AddNote event, Emitter<NoteState> emit) async {
    final currentState = state;
    if (currentState is NotesLoaded) {
      final tempNote = Note(
        id: 'temp',
        content: event.content,
        userId: 'me',
        createdAt: DateTime.now(),
      );
      emit(NotesLoaded(List.from(currentState.notes)..add(tempNote)));

      try {
        final newNote = await createNote(event.content);
        emit(NotesLoaded(List.from(currentState.notes)..add(newNote)));
      } catch (e) {
        emit(NotesError(e.toString()));
      }
    } else {
      emit(NotesLoading());
      try {
        await createNote(event.content);
        final notes = await getNotes();
        emit(NotesLoaded(notes));
      } catch (e) {
        emit(NotesError(e.toString()));
      }
    }
  }
}
