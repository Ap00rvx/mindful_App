import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class CreateChatUseCase {
  final ChatRepository repository;

  CreateChatUseCase(this.repository);

  Future<ChatEntity> call(String title) {
    return repository.createChat(title);
  }
}
