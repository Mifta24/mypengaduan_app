import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import 'user_form_utils.dart';

/// "Edit Pengguna" screen. A dedicated route (rather than a dialog) so its
/// form is consistent with the other admin add/edit screens (categories,
/// announcements, ...). Pops with the selected role (String) on save, or
/// null on cancel/back.
class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> detail;

  const EditUserScreen({super.key, required this.detail});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final AdminService _adminService = AdminService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _nikController;
  late final TextEditingController _rtController;
  late final TextEditingController _rwController;

  late String _selectedRole;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _nameController = TextEditingController(text: _pick(d, ['name']));
    _emailController = TextEditingController(text: _pick(d, ['email']));
    _phoneController =
        TextEditingController(text: _pick(d, ['phone', 'phone_number']));
    _addressController =
        TextEditingController(text: _pick(d, ['address', 'alamat']));
    _nikController = TextEditingController(text: _pick(d, ['nik']));
    _rtController = TextEditingController(text: _pick(d, ['rt_number', 'rt']));
    _rwController = TextEditingController(text: _pick(d, ['rw_number', 'rw']));
    _selectedRole = d['role']?.toString() ?? 'user';
    _isActive = parseUserBool(d['is_active'], defaultValue: true);
  }

  static String _pick(Map<String, dynamic> d, List<String> keys) {
    for (final key in keys) {
      final v = d[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Edit Pengguna',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _handleSave,
                tooltip: 'Simpan'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          TextField(
              controller: _nameController,
              decoration: userFormFieldDecoration(label: 'Nama Lengkap')),
          const SizedBox(height: 10),
          TextField(
              controller: _emailController,
              decoration: userFormFieldDecoration(label: 'Email')),
          const SizedBox(height: 10),
          TextField(
              controller: _phoneController,
              decoration: userFormFieldDecoration(label: 'Nomor Telepon')),
          const SizedBox(height: 10),
          TextField(
              controller: _addressController,
              decoration: userFormFieldDecoration(label: 'Alamat')),
          const SizedBox(height: 10),
          TextField(
              controller: _nikController,
              decoration: userFormFieldDecoration(label: 'NIK')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _rtController,
                      decoration: userFormFieldDecoration(label: 'RT'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _rwController,
                      decoration: userFormFieldDecoration(label: 'RW'))),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: userFormFieldDecoration(label: 'Peran'),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedRole = value);
            },
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _isActive
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _isActive
                      ? AppTheme.primary.withValues(alpha: 0.3)
                      : AppTheme.border),
            ),
            child: SwitchListTile(
              title: Text('Status Aktif',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeTrackColor: AppTheme.primary,
              secondary: Icon(
                _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: _isActive ? AppTheme.primary : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSave,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final id = parseUserId(widget.detail['id']);
    setState(() => _isLoading = true);
    try {
      await _adminService.updateUser(id, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        ...buildUserProfilePayload(
          phone: _phoneController.text,
          address: _addressController.text,
          nik: _nikController.text,
          rtNumber: _rtController.text,
          rwNumber: _rwController.text,
        ),
        'role': _selectedRole,
        'is_active': _isActive,
      });
      if (mounted) Navigator.pop(context, _selectedRole);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update pengguna: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }
}
