import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';

abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object> get props => [];
}

class NotesInitial extends NoteState {}

class NotesLoading extends NoteState {}

class NotesLoaded extends NoteState {
  final List<Note> notes;

  const NotesLoaded(this.notes);

  @override
  List<Object> get props => [notes];
}

class NotesError extends NoteState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object> get props => [message];
}
