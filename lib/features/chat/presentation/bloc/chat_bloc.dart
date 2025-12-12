import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_chats_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;

  ChatBloc(this.getChatsUseCase) : super(const ChatState()) {
    on<GetChats>(_onGetChats);
  }

  Future<void> _onGetChats(GetChats event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final chats = await getChatsUseCase();
      emit(state.copyWith(status: ChatStatus.success, chats: chats));
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
