import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';

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

  static const _gradientStart = Color(0xFF1A237E);
  static const _gradientEnd = Color(0xFF3949AB);
  static const _accentColor = Color(0xFF5C6BC0);

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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        nik: _nikController.text.trim(),
        rt: _rtController.text.trim(),
        rw: _rwController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Gradient SliverAppBar ──────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: _gradientStart,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradientStart, _gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Mini avatar
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                _accentColor.withValues(alpha: 0.15),
                            child: Text(
                              widget.user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _gradientEnd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'Edit Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                titlePadding:
                    const EdgeInsets.only(left: 56, bottom: 16),
                collapseMode: CollapseMode.parallax,
              ),
            ),

            // ── Form body ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  children: [
                    // ── Informasi Akun ──────────────────────
                    _buildSectionCard(
                      title: 'Informasi Akun',
                      icon: Icons.manage_accounts_rounded,
                      children: [
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
                        // Email — read only
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
                              if (v.length < 10) {
                                return 'Minimal 10 digit';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Informasi Pribadi ───────────────────
                    _buildSectionCard(
                      title: 'Informasi Pribadi',
                      icon: Icons.person_rounded,
                      children: [
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
                        // RT & RW side by side
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
                                  if (v != null && v.isNotEmpty) {
                                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                      return 'Hanya angka';
                                    }
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
                                  if (v != null && v.isNotEmpty) {
                                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                      return 'Hanya angka';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Save button ─────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [_gradientStart, _gradientEnd],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _isLoading ? Colors.grey.shade300 : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color:
                                        _gradientEnd.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gradientEnd.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _gradientEnd, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _accentColor),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFF),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _gradientEnd, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
        counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
      ),
    );
  }

  Widget _buildReadonlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tidak dapat diubah',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}