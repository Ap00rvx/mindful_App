import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/create_chat_usecase.dart';
import '../../domain/usecases/delete_chat_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/get_chats_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatPage extends StatelessWidget {
  final String? chatId;
  final String title;
  final String? initialMessage;

  const ChatPage({
    super.key,
    this.chatId,
    required this.title,
    this.initialMessage,
  });

  @override
  Widget build(BuildContext context) {
    final chatRepository = ChatRepositoryImpl(ChatRemoteDataSourceImpl());
    return BlocProvider(
      create: (context) {
        return ChatBloc(
          getChatsUseCase: GetChatsUseCase(chatRepository),
          sendMessageUseCase: SendMessageUseCase(chatRepository),
          getChatMessagesUseCase: GetChatMessagesUseCase(chatRepository),
          createChatUseCase: CreateChatUseCase(chatRepository),
          deleteChatUseCase: DeleteChatUseCase(chatRepository),
        )..add(InitializeChat(chatId: chatId, initialMessage: initialMessage));
      },
      child: _ChatView(
        chatId: chatId,
        initialMessage: initialMessage,
        title: title,
        user: Supabase.instance.client.auth.currentUser,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String? chatId;
  final User? user;
  final String title;
  final String? initialMessage;

  const _ChatView({
    this.chatId,
    this.user,
    required this.title,
    this.initialMessage,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String? _speakingMessageId; // To track which message is being spoken

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.initialMessage != null) {
      _sendInitialMessage();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _controller.text = result.recognizedWords;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _speak(String text, String messageId) async {
    if (_speakingMessageId == messageId) {
      await _stop();
    } else {
      await _stop(); // Stop any previous speech
      setState(() {
        _speakingMessageId = messageId;
      });
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _speakingMessageId = null;
          });
        }
      });
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _speakingMessageId = null;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendInitialMessage() {
    final text = widget.initialMessage?.trim() ?? '';
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(text, chatId: widget.chatId));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.chatId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<ChatBloc>().add(DeleteChat(widget.chatId!));
                context.pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state.status == ChatStatus.streaming ||
                    state.status == ChatStatus.success) {
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    _scrollToBottom,
                  );
                }
              },
              builder: (context, state) {
                if (state.status == ChatStatus.loading &&
                    state.messages.isEmpty) {
                  return const _ChatSkeleton();
                }
                if (state.status == ChatStatus.failure) {
                  return Center(child: Text('Error: ${state.errorMessage}'));
                }

                final messages = state.messages;

                if (messages.isEmpty && state.streamingMessage.isEmpty) {
                  return _EmptyChatView(
                    onSuggestionSelected: (suggestion) {
                      context.read<ChatBloc>().add(
                        SendMessage(suggestion, chatId: widget.chatId),
                      );
                    },
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      messages.length +
                      (state.streamingMessage.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      final message = messages[index];
                      return _MessageBubble(
                        content: message.content,
                        isUser: message.role == 'user',
                        user: widget.user,
                        onCopy: () => _copyToClipboard(message.content),
                        onSpeak: () => _speak(message.content, message.id),
                        isSpeaking: _speakingMessageId == message.id,
                      );
                    } else {
                      return _StreamingMessageBubble(
                        content: state.streamingMessage,
                        user: widget.user,
                      );
                    }
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.status == ChatStatus.streaming &&
                  state.streamingMessage.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: _TypingBubble(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: state.status != ChatStatus.streaming,
                        cursorColor: AppColors.secondary,
                        controller: _controller,
                        decoration: InputDecoration(
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _speechEnabled
                                    ? (_isListening
                                          ? _stopListening
                                          : _startListening)
                                    : null,
                                icon: Icon(
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  color: _isListening
                                      ? AppColors.secondary
                                      : Colors.white60,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  backgroundColor: AppColors.secondary,
                                ),
                                onPressed: _sendMessage,
                                icon: Image.asset(
                                  "assets/images/arrow.png",
                                  width: 50,
                                  height: 20,
                                  color: Colors.white60,
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                          hintText: 'Send Message...',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.secondary,
                              width: 0.4,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.white,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(text, chatId: widget.chatId));
      _controller.clear();
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final User? user;
  final VoidCallback? onCopy;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.user,
    this.onCopy,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0, bottom: 5),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.secondary,
                    child: Icon(
                      Icons.smart_toy,
                      color: AppColors.white,
                      size: 12,
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser
                        ? [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.secondary,
                          ].map((color) => color.withAlpha(130)).toList()
                        : [AppColors.surface, AppColors.surface],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isUser
                        ? const Radius.circular(12)
                        : const Radius.circular(0),
                    bottomRight: isUser
                        ? const Radius.circular(0)
                        : const Radius.circular(12),
                  ),
                ),
                child: MarkdownBody(
                  selectable: true,
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: AppColors.white, fontSize: 16),
                    code: TextStyle(
                      backgroundColor: isUser
                          ? AppColors.surface
                          : AppColors.background,
                      color: AppColors.white,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isUser ? AppColors.surface : AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 5),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.secondary,
                    backgroundImage:
                        user != null &&
                            user!.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata?['avatar_url'])
                        : null,
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 32,
              right: isUser ? 32 : 0,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCopy != null)
                  InkWell(
                    onTap: onCopy,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                if (onSpeak != null && !isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onSpeak,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isSpeaking ? Icons.stop : Icons.volume_up,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surface.withOpacity(0.5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          final isUser = index % 2 != 0;
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: MediaQuery.of(context).size.width * 0.6,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0, bottom: 5),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.secondary,
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.white,
                size: 12,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return FadeTransition(
                  opacity: _controller.drive(
                    CurveTween(
                      curve: Interval(
                        index * 0.2,
                        0.6 + index * 0.2,
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  final Function(String) onSuggestionSelected;

  const _EmptyChatView({required this.onSuggestionSelected});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Help me relax',
      'Plan my day',
      'Tell me a joke',
      'Mindfulness tips',
      'How to meditate?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start a Conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything or choose a topic below',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: suggestions.map((suggestion) {
                return ActionChip(
                  backgroundColor: AppColors.surface,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  avatar: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () => onSuggestionSelected(suggestion),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingMessageBubble extends StatefulWidget {
  final String content;
  final User? user;

  const _StreamingMessageBubble({required this.content, this.user});

  @override
  State<_StreamingMessageBubble> createState() =>
      _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<_StreamingMessageBubble> {
  String _displayedContent = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_StreamingMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_displayedContent.length < widget.content.length) {
      _startTyping();
    }
  }

  void _startTyping() {
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(const Duration(milliseconds: 4), (timer) {
      if (_displayedContent.length < widget.content.length) {
        setState(() {
          _displayedContent = widget.content.substring(
            0,
            _displayedContent.length + 1,
          );
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MessageBubble(
      content: _displayedContent,
      isUser: false,
      user: widget.user,
    );
  }
}
