import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mindful_app/core/network/dio.dart';
import 'package:mindful_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mindful_app/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:mindful_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:mindful_app/features/notes/data/repositories/note_repository_impl.dart';
import 'package:mindful_app/features/notes/domain/usecases/create_note.dart';
import 'package:mindful_app/features/notes/domain/usecases/get_notes.dart';
import 'package:mindful_app/features/notes/presentation/bloc/note_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'features/notes/data/datasources/note_remote_data_source.dart';
import 'theme/app_theme.dart';
import 'package:mindful_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:mindful_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mindful_app/features/chat/domain/usecases/create_chat_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/delete_chat_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/get_chats_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/send_message_usecase.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env").then((_) {
    debugPrint("Environment variables loaded");
  });

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
                    create: (context) {
                      final dataSource = NoteRemoteDataSourceImpl(
                        dio: AppClient.dio,
                        supabaseClient: Supabase.instance.client,
                      );
                      final repository = NoteRepositoryImpl(
                        remoteDataSource: dataSource,
                      );
                      return NoteBloc(
                        getNotes: GetNotes(repository),
                        createNote: CreateNote(repository),
                      );
                    },
                  ),
                   BlocProvider(create: (context) => ChatBloc(
                    getChatsUseCase: GetChatsUseCase(
                      ChatRepositoryImpl(ChatRemoteDataSourceImpl()),
                    ),
                    sendMessageUseCase: SendMessageUseCase(
                      ChatRepositoryImpl(ChatRemoteDataSourceImpl()),
                    ),
                    getChatMessagesUseCase: GetChatMessagesUseCase(
                      ChatRepositoryImpl(ChatRemoteDataSourceImpl()),
                    ),
                    createChatUseCase: CreateChatUseCase(
                      ChatRepositoryImpl(ChatRemoteDataSourceImpl()),
                    ),
                    deleteChatUseCase: DeleteChatUseCase(
                      ChatRepositoryImpl(ChatRemoteDataSourceImpl()),
                    ),
                  )),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Mindful App',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
