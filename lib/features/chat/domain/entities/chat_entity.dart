import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;

  const ChatEntity({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, createdAt];
}
