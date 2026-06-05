import 'dart:math';
import 'package:flutter/material.dart';

class VoiceWaveAnimation extends StatefulWidget {
  final bool isActive;

  const VoiceWaveAnimation({super.key, required this.isActive});

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  List<double> _heights = [6, 6, 6, 6, 6];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat();
      _controller.addListener(_updateHeights);
    }
  }

  @override
  void didUpdateWidget(VoiceWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
      _controller.addListener(_updateHeights);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.removeListener(_updateHeights);
      _controller.stop();
      setState(() => _heights = [6, 6, 6, 6, 6]);
    }
  }

  void _updateHeights() {
    if (!mounted) return;
    setState(() {
      _heights = List.generate(5, (_) => 6 + _random.nextDouble() * 18);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateHeights);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: widget.isActive ? _heights[i] : 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: widget.isActive
                  ? const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    )
                  : null,
              color: widget.isActive ? null : const Color(0xFF6B7280),
            ),
          );
        }),
      ),
    );
  }
}
