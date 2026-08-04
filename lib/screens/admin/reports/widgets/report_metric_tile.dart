import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';

/// Small stat tile used in the complaint/user report list pages.
class ReportMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final bool fullWidth;

  const ReportMetricTile({
    super.key,
    required this.title,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style:
                GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );

    if (!fullWidth) return tile;
    return SizedBox(width: double.infinity, child: tile);
  }
}
