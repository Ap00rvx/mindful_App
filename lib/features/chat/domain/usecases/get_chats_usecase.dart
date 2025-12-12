import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatsUseCase {
  final ChatRepository repository;

  GetChatsUseCase(this.repository);

  Future<List<ChatEntity>> call() {
    return repository.getChats();
  }
}
