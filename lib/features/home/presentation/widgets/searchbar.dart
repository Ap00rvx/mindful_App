import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mindful_app/theme/app_colors.dart';

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
            decoration: InputDecoration(
              hintText: 'Remind me of anything...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
