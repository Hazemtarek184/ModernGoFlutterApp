import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';

/// Green pulsing dot + "Live Scan . Updating automatically" — matches design exactly.
class LiveScanIndicator extends StatefulWidget {
  final bool isConnected;

  const LiveScanIndicator({super.key, required this.isConnected});

  @override
  State<LiveScanIndicator> createState() => _LiveScanIndicatorState();
}

class _LiveScanIndicatorState extends State<LiveScanIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LiveScanIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isConnected
                      ? AppColors.primary
                          .withValues(alpha: _pulseAnimation.value)
                      : Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Live Scan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: widget.isConnected ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            widget.isConnected
                ? ' . Updating automatically'
                : ' . Disconnected',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
