import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String content;
  final String userId;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, content, userId, createdAt];
}
