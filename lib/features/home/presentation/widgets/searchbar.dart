import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:mindful_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mindful_app/features/chat/domain/usecases/create_chat_usecase.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: SweepGradient(
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.primary,
            ],
            stops: const [0.0, 0.5, 1.0],
            transform: GradientRotation(_controller.value * 2 * 3.14159),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0.45),
          child: TextField(
            controller: _searchController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: _isLoading
                  ? 'Creating chat...'
                  : 'Remind me of anything...',
              prefixIcon: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Shimmer.fromColors(
                          baseColor: AppColors.secondary,
                          highlightColor: AppColors.white,
                          child: const Icon(
                            Icons.smart_toy,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                  : const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (value) async {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _isLoading = true;
                });
                try {
                  final chatRepository = ChatRepositoryImpl(
                    ChatRemoteDataSourceImpl(),
                  );
                  final createChatUseCase = CreateChatUseCase(chatRepository);
                  final chat = await createChatUseCase(value.trim());

                  if (mounted) {
                    debugPrint('Created chat with ID: ${chat.id}');
                    debugPrint(
                      'Navigating to chat page with initial message.${value.trim()}',
                    );
                    context.push(
                      '/chat/${chat.id}',
                      extra: {
                        'initialMessage': value.trim(),
                        'title': chat.title,
                      },
                    );
                    _searchController.clear();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create chat: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
