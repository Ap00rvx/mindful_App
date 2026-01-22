import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ChatEntity>> getChats() async {
    return await remoteDataSource.getChats();
  }

  @override
  Stream<String> sendMessage(
    String message, {
    String? chatId,
    bool isTemporary = false,
    List<ChatMessage> history = const [],
  }) {
    final historyMaps = history
        .map((msg) => {'role': msg.role, 'content': msg.content})
        .toList();
    return remoteDataSource.sendMessage(
      message,
      chatId: chatId,
      isTemporary: isTemporary,
      history: historyMaps,
    );
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    return await remoteDataSource.getChatMessages(chatId);
  }

  @override
  Future<ChatEntity> createChat(String title) async {
    return await remoteDataSource.createChat(title);
  }

  @override
  Future<void> deleteChat(String chatId) async {
    return await remoteDataSource.deleteChat(chatId);
  }
}
