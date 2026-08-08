import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';

enum AxisState { idle, listening, processing, speaking }

class AxisAvatar extends StatefulWidget {
  final AxisState state;

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

  Color _getStateColor() {
    switch (widget.state) {
      case AxisState.idle:
        return Colors.blue;
      case AxisState.listening:
        return Colors.green;
      case AxisState.processing:
        return Colors.orange;
      case AxisState.speaking:
        return Colors.purple;
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
                color: stateColor.withOpacity(_glowAnimation.value * 0.6),
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
                    stateColor.withOpacity(0.8),
                    stateColor.withOpacity(0.4),
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
    switch (widget.state) {
      case AxisState.idle:
        return const Icon(
          Icons.smart_toy,
          size: 60,
          color: Colors.white,
        );
      case AxisState.listening:
        return const Icon(
          Icons.mic,
          size: 60,
          color: Colors.white,
        );
      case AxisState.processing:
        return const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case AxisState.speaking:
        return const Icon(
          Icons.volume_up,
          size: 60,
          color: Colors.white,
        );
    }
  }
}
