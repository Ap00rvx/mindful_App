import 'package:flutter/material.dart';
import 'package:mindful_app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

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
