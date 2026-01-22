import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class GetChats extends ChatEvent {}

class LoadChatMessages extends ChatEvent {
  final String chatId;

  const LoadChatMessages(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final String message;
  final String? chatId;
  final bool isTemporary;

  const SendMessage(this.message, {this.chatId, this.isTemporary = false});

  @override
  List<Object> get props => [message, chatId ?? '', isTemporary];
}

class ReceiveMessageChunk extends ChatEvent {
  final String chunk;

  const ReceiveMessageChunk(this.chunk);

  @override
  List<Object> get props => [chunk];
}

class StreamComplete extends ChatEvent {}

class CreateChat extends ChatEvent {
  final String title;

  const CreateChat(this.title);

  @override
  List<Object> get props => [title];
}

class InitializeChat extends ChatEvent {
  final String? chatId;
  final String? initialMessage;

  const InitializeChat({this.chatId, this.initialMessage});

  @override
  List<Object> get props => [chatId ?? '', initialMessage ?? ''];
}

class DeleteChat extends ChatEvent {
  final String chatId;

  const DeleteChat(this.chatId);

  @override
  List<Object> get props => [chatId];
}
