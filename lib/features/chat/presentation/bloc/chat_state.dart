import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatEntity> chats;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chats = const [],
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatEntity>? chats,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, chats, errorMessage];
}
