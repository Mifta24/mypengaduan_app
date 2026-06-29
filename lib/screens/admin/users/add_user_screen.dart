import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import 'user_form_utils.dart';

/// "Tambah Pengguna" screen. A dedicated route (rather than a dialog) so its
/// form is consistent with the other admin add/edit screens (categories,
/// announcements, ...).
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final AdminService _adminService = AdminService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _nikController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  final _fieldErrors = <String, String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _calcPasswordStrength(_passwordController.text);
    final strengthLabel = _passwordStrengthLabel(passwordStrength);
    final strengthColor = _passwordStrengthColor(passwordStrength);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Tambah Pengguna', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(icon: const Icon(Icons.check_rounded), onPressed: _handleSubmit, tooltip: 'Simpan'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          TextField(
            controller: _nameController,
            decoration: userFormFieldDecoration(label: 'Nama Lengkap*', errorText: _fieldErrors['name']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: userFormFieldDecoration(label: 'Email*', errorText: _fieldErrors['email']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: userFormFieldDecoration(label: 'Password*', errorText: _fieldErrors['password']),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Kekuatan password: $strengthLabel', style: TextStyle(fontSize: 12, color: strengthColor)),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: passwordStrength,
              color: strengthColor,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: userFormFieldDecoration(
                label: 'Konfirmasi Password*', errorText: _fieldErrors['password_confirmation']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: userFormFieldDecoration(label: 'Nomor Telepon', errorText: _fieldErrors['phone']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration: userFormFieldDecoration(label: 'Alamat', errorText: _fieldErrors['address']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nikController,
            decoration: userFormFieldDecoration(label: 'NIK', errorText: _fieldErrors['nik']),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rtController,
                  decoration: userFormFieldDecoration(label: 'RT', errorText: _fieldErrors['rt_number'] ?? _fieldErrors['rt']),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rwController,
                  decoration: userFormFieldDecoration(label: 'RW', errorText: _fieldErrors['rw_number'] ?? _fieldErrors['rw']),
                ),
              ),
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
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSubmit,
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Pengguna', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _fieldErrors.clear());

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirmation = _confirmPasswordController.text.trim();

    final localErrors = <String, String>{};

    if (name.isEmpty) localErrors['name'] = 'Nama wajib diisi';

    if (email.isEmpty) {
      localErrors['email'] = 'Email wajib diisi';
    } else if (!_isValidEmail(email)) {
      localErrors['email'] = 'Format email tidak valid';
    }

    if (password.isEmpty) {
      localErrors['password'] = 'Password wajib diisi';
    } else if (!_isStrongPassword(password)) {
      localErrors['password'] = 'Minimal 8 karakter, kombinasi huruf dan angka';
    }

    if (passwordConfirmation.isEmpty) {
      localErrors['password_confirmation'] = 'Konfirmasi password wajib diisi';
    } else if (passwordConfirmation != password) {
      localErrors['password_confirmation'] = 'Konfirmasi password tidak sama';
    }

    if (localErrors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(localErrors);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali input form'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _adminService.createUser({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        ...buildUserProfilePayload(
          phone: _phoneController.text,
          address: _addressController.text,
          nik: _nikController.text,
          rtNumber: _rtController.text,
          rwNumber: _rwController.text,
        ),
        'role': _selectedRole,
        'is_active': true,
      });

      if (!response.success) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isEmpty ? 'Gagal membuat pengguna' : response.message),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Server may create user as 'user' regardless of role param.
      // Explicitly change role if admin was requested.
      if (_selectedRole == 'admin') {
        final rawData = response.data;
        if (rawData is Map) {
          final rawId = rawData['id'];
          final numId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          if (numId != null && numId > 0) {
            try {
              await _adminService.changeUserRole(numId, 'admin');
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User dibuat tapi gagal set role admin: $e'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            }
          }
        }
      }

      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      final parsed = _extractCreateFieldErrors(e.response?.data);
      if (parsed.isNotEmpty) {
        setState(() {
          _fieldErrors
            ..clear()
            ..addAll(parsed);
        });
      }
      final fallbackMessage = _extractCreateGeneralMessage(e.response?.data) ?? 'Gagal buat pengguna';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMessage), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal buat pengguna: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  bool _isValidEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    return RegExp(r'[A-Za-z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password);
  }

  double _calcPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0.0;
    if (password.length >= 8) score += 0.35;
    if (password.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String _passwordStrengthLabel(double score) {
    if (score >= 0.85) return 'Sangat Kuat';
    if (score >= 0.65) return 'Kuat';
    if (score >= 0.4) return 'Sedang';
    if (score > 0) return 'Lemah';
    return '-';
  }

  Color _passwordStrengthColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.65) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Map<String, String> _extractCreateFieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final errorsRaw = Map<String, dynamic>.from(data)['errors'];
    if (errorsRaw is! Map) return const {};
    final result = <String, String>{};
    for (final entry in Map<String, dynamic>.from(errorsRaw).entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty) {
        result[entry.key] = v.first.toString();
      } else if (v != null) {
        result[entry.key] = v.toString();
      }
    }
    return result;
  }

  String? _extractCreateGeneralMessage(dynamic data) {
    if (data is! Map) return null;
    final message = Map<String, dynamic>.from(data)['message'];
    return message?.toString();
  }
}
