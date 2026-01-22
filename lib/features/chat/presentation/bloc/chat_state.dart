import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loading, success, failure, streaming }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatEntity> chats;
  final List<ChatMessage> messages;
  final String streamingMessage;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chats = const [],
    this.messages = const [],
    this.streamingMessage = '',
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatEntity>? chats,
    List<ChatMessage>? messages,
    String? streamingMessage,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      streamingMessage: streamingMessage ?? this.streamingMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    chats,
    messages,
    streamingMessage,
    errorMessage,
  ];
}
