import 'package:flutter/material.dart';

enum AxisState { idle, listening, processing, speaking }

class AxisAvatar extends StatefulWidget {
  final dynamic state; // Accepts String or AxisState enum

  const AxisAvatar({
    super.key,
    required this.state,
  });

  @override
  State<AxisAvatar> createState() => _AxisAvatarState();
}

class _AxisAvatarState extends State<AxisAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStateString() {
    if (widget.state is AxisState) {
      return (widget.state as AxisState).name;
    }
    return widget.state.toString();
  }

  Color _getStateColor() {
    final s = _getStateString();
    switch (s) {
      case 'listening':
        return const Color(0xFF00C896); // green
      case 'processing':
        return Colors.orange;
      case 'speaking':
        return Colors.purple;
      case 'idle':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stateColor,
            boxShadow: [
              BoxShadow(
                color: stateColor.withValues(alpha: _glowAnimation.value * 0.6),
                blurRadius: 30 * _glowAnimation.value,
                spreadRadius: 10 * _glowAnimation.value,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    stateColor.withValues(alpha: 0.8),
                    stateColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Center(
                child: _buildStateIcon(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateIcon() {
    final s = _getStateString();
    switch (s) {
      case 'listening':
        return const Icon(
          Icons.mic,
          size: 60,
          color: Colors.white,
        );
      case 'processing':
        return const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case 'speaking':
        return const Icon(
          Icons.volume_up,
          size: 60,
          color: Colors.white,
        );
      case 'idle':
      default:
        return const Icon(
          Icons.smart_toy,
          size: 60,
          color: Colors.white,
        );
    }
  }
}
