import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
