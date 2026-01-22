import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:mindful_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mindful_app/features/chat/domain/usecases/get_chats_usecase.dart';
import 'package:mindful_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:mindful_app/features/chat/presentation/bloc/chat_event.dart';
import 'package:mindful_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mindful_app/features/chat/domain/usecases/create_chat_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/delete_chat_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:mindful_app/features/chat/domain/usecases/send_message_usecase.dart';

class ChatHistoryList extends StatelessWidget {
  const ChatHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final chatRepository = ChatRepositoryImpl(ChatRemoteDataSourceImpl());
    return BlocProvider(
      create: (context) => ChatBloc(
        getChatsUseCase: GetChatsUseCase(chatRepository),
        sendMessageUseCase: SendMessageUseCase(chatRepository),
        getChatMessagesUseCase: GetChatMessagesUseCase(chatRepository),
        createChatUseCase: CreateChatUseCase(chatRepository),
        deleteChatUseCase: DeleteChatUseCase(chatRepository),
      )..add(GetChats()),
      child: const _ChatHistoryListView(),
    );
  }
}

class _ChatHistoryListView extends StatefulWidget {
  const _ChatHistoryListView();

  @override
  State<_ChatHistoryListView> createState() => _ChatHistoryListViewState();
}

class _ChatHistoryListViewState extends State<_ChatHistoryListView> {
  int maxItems = 5;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Text(
                "History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    maxItems = maxItems == 5 ? 20 : 5;
                  });
                },
                child: Text(
                  maxItems == 5 ? 'See All' : 'See Less',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.status == ChatStatus.loading ||
                state.status == ChatStatus.initial) {
              return const _ChatHistorySkeleton();
            } else if (state.status == ChatStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Failed to load chats',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ChatBloc>().add(GetChats());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state.status == ChatStatus.success) {
              if (state.chats.isEmpty) {
                return const Center(
                  child: Text(
                    'No chats yet. Start a new conversation!',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(maxItems, state.chats.length),
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset("assets/images/star.png"),
                      ),
                    ),
                    title: Text(
                      chat.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatDate(chat.createdAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 14,
                    ),
                    onTap: () {
                      context.push(
                        '/chat/${chat.id}',
                        extra: {'title': chat.title},
                      );
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ChatHistorySkeleton extends StatelessWidget {
  const _ChatHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}
