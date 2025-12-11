import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mindful_app/theme/app_colors.dart';

class DynoBg extends StatefulWidget {
  const DynoBg({super.key,  this.left = 0,  this.right = 0});
  final double left ; 
  final double right; 
  @override
  _DynoBgState createState() => _DynoBgState();
}

class _DynoBgState extends State<DynoBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // 6s loop for a slow, calming movement — tweak duration as you like.
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Helper to convert value in [-1,1] into an Alignment on the X axis and keep Y fixed
  Alignment _animatedAlignment(double x, double y) => Alignment(x, y);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value; // 0..1
          // Create smooth oscillation using sine
          final double offset1 = sin(2 * pi * t) * 0.36; // amplitude ~0.36 (tweak)
          final double offset2 = sin(2 * pi * t + pi / 2) * 0.26; // phase-shifted

          // For each gradient we animate the horizontal alignments (keep vertical mostly same)
          final begin1 = _animatedAlignment(-0.6 + offset1, -1.0);
          final end1 = _animatedAlignment(0.4 + offset1, 1.0);

          final begin2 = _animatedAlignment(-0.8 + offset2, -1.0);
          final end2 = _animatedAlignment(0.2 + offset2, 1.0);

          return Stack(
            children: [
              Positioned(
                top: -50,
                right: -100,
                child: Container(
                  width: 400,
                  height: widget.right > 0 ?  widget.right : 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: begin1,
                      end: end1,
                      stops: const [0.0, 0.98],
                      colors: [
                        AppColors.primary.withAlpha(153),
                        AppColors.secondary.withAlpha(153),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 500,
                  height: widget.left > 0 ? widget.left : 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: begin2,
                      end: end2,
                      stops: const [0.0, 0.8],
                      colors: [
                        AppColors.primary.withAlpha(153),
                        AppColors.secondary.withAlpha(200),
                      ],
                    ),
                  ),
                ),
              ),
              // Blur everything to blend
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                child: Container(color: Colors.transparent),
              ),
            ],
          );
        },
      ),
    );
  }
}
