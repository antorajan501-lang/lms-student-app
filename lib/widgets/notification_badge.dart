import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showWhenZero;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showWhenZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showWhenZero && count == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
