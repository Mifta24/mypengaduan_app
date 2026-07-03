import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminInfoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  const AdminInfoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.borderWidth = 1.5, // Slightly thicker border for SaaS feel
    this.elevation = 0,
    this.borderRadius = 16,
    this.backgroundColor,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.primary.withValues(alpha: 0.08), 
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
