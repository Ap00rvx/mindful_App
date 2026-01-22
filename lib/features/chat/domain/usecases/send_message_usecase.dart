import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Stream<String> call(
    String message, {
    String? chatId,
    bool isTemporary = false,
    List<ChatMessage> history = const [],
  }) {
    return repository.sendMessage(
      message,
      chatId: chatId,
      isTemporary: isTemporary,
      history: history,
    );
  }
}
