import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../theme/app_theme.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final User user;

  const EditAdminProfileScreen({super.key, required this.user});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _nikController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;

  bool _isLoading = false;
  File? _profileImage;
  bool _removeAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _nikController = TextEditingController(text: widget.user.nik ?? '');
    _rtController = TextEditingController(text: widget.user.rtNumber ?? '');
    _rwController = TextEditingController(text: widget.user.rwNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
          _removeAvatar = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            nik: _nikController.text.trim(),
            rt: _rtController.text.trim(),
            rw: _rwController.text.trim(),
            avatarPath: _profileImage?.path,
            removeAvatar: _removeAvatar,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar dark forest green ──────────────
            SliverAppBar(
              expandedHeight: 168,
              pinned: true,
              backgroundColor: AppTheme.bgDark,
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.bgDeep, AppTheme.bgDark],
                        ),
                      ),
                    ),
                    // Leaf decorations
                    Positioned(
                      top: 60, right: 20,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Icon(Icons.eco_rounded, size: 36,
                            color: AppTheme.primaryDark
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                    Positioned(
                      top: 80, left: 14,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Icon(Icons.eco_rounded, size: 24,
                            color: AppTheme.primaryDark
                                .withValues(alpha: 0.35)),
                      ),
                    ),
                    // Avatar + name
                    Positioned.fill(
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _profileImage != null
                                    ? Image.file(_profileImage!,
                                        width: 64, height: 64,
                                        fit: BoxFit.cover)
                                    : (!_removeAvatar &&
                                            widget.user.avatar != null
                                        ? Image.network(
                                            widget.user.avatar!,
                                            width: 64, height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                                  child: Text(
                                                    widget.user.name.isNotEmpty
                                                        ? widget.user.name[0]
                                                            .toUpperCase()
                                                        : 'A',
                                                    style: GoogleFonts.nunito(
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Text(
                                              widget.user.name.isNotEmpty
                                                  ? widget.user.name[0]
                                                      .toUpperCase()
                                                  : 'A',
                                              style: GoogleFonts.nunito(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white),
                                            ),
                                          )),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.user.name,
                                style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 2),
                            Text(widget.user.email,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.7)),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text('Edit Profil',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                titlePadding:
                    const EdgeInsets.only(left: 56, bottom: 16),
                collapseMode: CollapseMode.parallax,
              ),
            ),

            // ── Form body ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Foto Profil ─────────────────────────
                    _sectionLabel('Foto Profil'),
                    const SizedBox(height: 8),
                    _buildCard([
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.1),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider
                                : (!_removeAvatar && widget.user.avatar != null
                                    ? NetworkImage(widget.user.avatar!)
                                    : null),
                            child: (_profileImage == null &&
                                    (_removeAvatar ||
                                        widget.user.avatar == null))
                                ? Text(
                                    widget.user.name.isNotEmpty
                                        ? widget.user.name[0].toUpperCase()
                                        : 'A',
                                    style: GoogleFonts.nunito(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickProfileImage,
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: Text(
                                    _profileImage == null
                                        ? 'Pilih Foto'
                                        : 'Ganti Foto',
                                    style: GoogleFonts.nunito(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(
                                        color: AppTheme.primary),
                                  ),
                                ),
                                if (_profileImage != null ||
                                    (!_removeAvatar &&
                                        widget.user.avatar != null)) ...[
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    onPressed: () => setState(() {
                                      _profileImage = null;
                                      _removeAvatar = true;
                                    }),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: AppTheme.danger),
                                    label: Text(
                                      'Hapus Foto',
                                      style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: AppTheme.danger),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: AppTheme.danger),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'JPG, JPEG, PNG hingga 2MB',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Informasi Akun ──────────────────────
                    _sectionLabel('Informasi Akun'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_rounded,
                        hint: 'Masukkan nama lengkap',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama tidak boleh kosong'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      _buildReadonlyField(
                        value: widget.user.email,
                        label: 'Email',
                        icon: Icons.email_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _phoneController,
                        label: 'No. Telepon',
                        icon: Icons.phone_rounded,
                        hint: '08xxxxxxxxxx',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                              return 'Hanya boleh berisi angka';
                            }
                            if (v.length < 10) return 'Minimal 10 digit';
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Informasi Pribadi ───────────────────
                    _sectionLabel('Informasi Pribadi'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildField(
                        controller: _nikController,
                        label: 'NIK',
                        icon: Icons.badge_rounded,
                        hint: '16 digit NIK',
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (v.length != 16) return 'NIK harus 16 digit';
                            if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                              return 'Hanya boleh berisi angka';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _addressController,
                        label: 'Alamat',
                        icon: Icons.home_rounded,
                        hint: 'Alamat lengkap',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _rtController,
                              label: 'RT',
                              icon: Icons.location_city_rounded,
                              hint: '001',
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                  return 'Hanya angka';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _rwController,
                              label: 'RW',
                              icon: Icons.location_city_rounded,
                              hint: '001',
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                  return 'Hanya angka';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ── Save button ─────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      );

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.nunito(
            fontSize: 13, color: AppTheme.textSecondary),
        hintStyle: GoogleFonts.nunito(
            fontSize: 13, color: AppTheme.textSecondary),
        counterStyle: GoogleFonts.nunito(
            fontSize: 11, color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildReadonlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16,
                  color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Tidak dapat diubah',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
