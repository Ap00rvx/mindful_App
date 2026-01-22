import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_chats_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/create_chat_usecase.dart';
import '../../domain/usecases/delete_chat_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final CreateChatUseCase createChatUseCase;
  final DeleteChatUseCase deleteChatUseCase;

  ChatBloc({
    required this.getChatsUseCase,
    required this.sendMessageUseCase,
    required this.getChatMessagesUseCase,
    required this.createChatUseCase,
    required this.deleteChatUseCase,
  }) : super(const ChatState()) {
    on<GetChats>(_onGetChats);
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessageChunk>(_onReceiveMessageChunk);
    on<StreamComplete>(_onStreamComplete);
    on<CreateChat>(_onCreateChat);
    on<InitializeChat>(_onInitializeChat);
    on<DeleteChat>(_onDeleteChat);
  }

  Future<void> _onInitializeChat(
    InitializeChat event,
    Emitter<ChatState> emit,
  ) async {
    if (event.chatId != null) {
      emit(state.copyWith(status: ChatStatus.loading));
      try {
        final messages = await getChatMessagesUseCase(event.chatId!);
        if (event.initialMessage != null) {
          add(SendMessage(event.initialMessage!, chatId: event.chatId));
        }
        emit(state.copyWith(status: ChatStatus.success, messages: messages));
      } catch (e) {
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    } else {
      add(GetChats());
    }

   
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

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final messages = await getChatMessagesUseCase(event.chatId);
      emit(state.copyWith(status: ChatStatus.success, messages: messages));
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final history = state.messages;
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: event.message,
      createdAt: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: List.from(state.messages)..add(userMessage),
        status: ChatStatus.streaming,
        streamingMessage: '',
      ),
    );

    await emit.forEach(
      sendMessageUseCase(
        event.message,
        chatId: event.chatId,
        isTemporary: event.isTemporary,
        history: history,
      ),
      onData: (chunk) => state.copyWith(
        streamingMessage: state.streamingMessage + chunk,
        status: ChatStatus.streaming,
      ),
      onError: (error, stackTrace) {
        return state.copyWith(
          status: ChatStatus.failure,
          errorMessage: error.toString(),
        );
      },
    );

    add(StreamComplete());
  }

  Future<void> _onReceiveMessageChunk(
    ReceiveMessageChunk event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        streamingMessage: state.streamingMessage + event.chunk,
        status: ChatStatus.streaming,
      ),
    );
  }

  Future<void> _onStreamComplete(
    StreamComplete event,
    Emitter<ChatState> emit,
  ) async {
    if (state.streamingMessage.isNotEmpty) {
      final assistantMessage = ChatMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: state.streamingMessage,
        createdAt: DateTime.now(),
      );
      emit(
        state.copyWith(
          messages: List.from(state.messages)..add(assistantMessage),
          streamingMessage: '',
          status: ChatStatus.success,
        ),
      );
    } else {
      emit(state.copyWith(status: ChatStatus.success));
    }
  }

  Future<void> _onCreateChat(CreateChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final chat = await createChatUseCase(event.title);
      // Optionally, you might want to navigate to the new chat or add it to the list
      // For now, let's just refresh the list and maybe set it as current?
      // But navigation is usually handled in the UI listener.
      // Let's just add it to the list of chats in the state.
      final updatedChats = List.of(state.chats)..insert(0, chat);
      emit(state.copyWith(status: ChatStatus.success, chats: updatedChats));
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onDeleteChat(DeleteChat event, Emitter<ChatState> emit) async {
    try {
      await deleteChatUseCase(event.chatId);
      add(GetChats()); // Refresh chat list
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
