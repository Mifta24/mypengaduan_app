import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';

/// Generic "filter by status" dropdown used in the admin complaints list.
class ComplaintStatusDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final Map<String, String> items;
  final void Function(String?) onChanged;

  const ComplaintStatusDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade500)),
          style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: [
            DropdownMenuItem(value: null, child: Text(hint, style: GoogleFonts.nunito(fontSize: 13))),
            ...items.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.nunito(fontSize: 13))),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
