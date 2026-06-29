import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

InputDecoration userFormFieldDecoration({
  required String label,
  String? hint,
  String? errorText,
}) {
  return AppTheme.inputDecoration(label: label, hint: hint, errorText: errorText);
}

Map<String, dynamic> buildUserProfilePayload({
  required String phone,
  required String address,
  required String nik,
  required String rtNumber,
  required String rwNumber,
}) {
  return {
    'phone': phone.trim(),
    'address': address.trim(),
    'nik': nik.trim(),
    'rt_number': rtNumber.trim(),
    'rw_number': rwNumber.trim(),
    'rt': rtNumber.trim(),
    'rw': rwNumber.trim(),
  };
}

int parseUserId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool parseUserBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final s = value.toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
  }
  return defaultValue;
}
