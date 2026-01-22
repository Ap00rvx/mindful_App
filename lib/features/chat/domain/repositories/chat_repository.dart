import '../entities/chat_entity.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatEntity>> getChats();
  Stream<String> sendMessage(
    String message, {
    String? chatId,
    bool isTemporary = false,
    List<ChatMessage> history = const [],
  });
  Future<List<ChatMessage>> getChatMessages(String chatId);
  Future<ChatEntity> createChat(String title);
  Future<void> deleteChat(String chatId);
}
