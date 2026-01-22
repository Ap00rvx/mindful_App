import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(
                curve: Curves.easeInOutCirc,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(
                curve: Curves.easeInOutCirc,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialMessage = extra?['initialMessage'] as String?;
          return ChatPage(title: 'Chat', initialMessage: initialMessage);
        },
        routes: [
          GoRoute(
            path: ':chatId',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId'];
              final extra = state.extra as Map<String, dynamic>?;
              final initialMessage = extra?['initialMessage'] as String?;
              final title = extra?['title'] as String? ?? 'Chat';
              return ChatPage(
                chatId: chatId,
                title: title,
                initialMessage: initialMessage,
              );
            },
          ),
        ],
      ),
    ],
  );
}
