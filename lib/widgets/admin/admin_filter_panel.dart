import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminFilterPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AdminFilterPanel({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
