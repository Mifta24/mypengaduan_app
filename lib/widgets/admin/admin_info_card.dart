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
    this.borderWidth = 1,
    this.elevation = 0,
    this.borderRadius = 12,
    this.backgroundColor,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      color: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: borderColor ?? AppTheme.border,
          width: borderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}
