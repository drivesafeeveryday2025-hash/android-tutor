import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated soundwave visualizer that expands and contracts based on active speech state.
class SoundwaveVisualizer extends StatefulWidget {
  final bool isRecording;
  final bool isPlayingTts;

  const SoundwaveVisualizer({
    super.key,
    required this.isRecording,
    required this.isPlayingTts,
  });

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isRecording || widget.isPlayingTts) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.isRecording || oldWidget.isPlayingTts;
    final isActive = widget.isRecording || widget.isPlayingTts;

    if (isActive && !wasActive) {
      _controller.repeat();
    } else if (!isActive && wasActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double visualizerHeight = 36.0;
    final isActive = widget.isRecording || widget.isPlayingTts;

    return SizedBox(
      height: visualizerHeight,
      child: Center(
        child: RepaintBoundary(
          child: !isActive
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(7, (index) {
                    final color = AppColors.primaryIndigo.withValues(alpha: 0.3);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 4,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(7, (index) {
                        final waveHeight =
                            sin((_controller.value * 2 * pi) + (index * 0.6)).abs() *
                                24 +
                            8;
                        final color = widget.isRecording
                            ? AppColors.roseError
                            : AppColors.emeraldSuccess;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 4,
                          height: waveHeight,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
