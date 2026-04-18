import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _emailController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  File? _ktpImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickKtpImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();
        
        // Check file size (max 2MB)
        if (fileSize > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ukuran file maksimal 2MB'),
                backgroundColor: AppTheme.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          return;
        }
        
        setState(() {
          _ktpImage = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan upload foto KTP Anda'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda harus menyetujui syarat & ketentuan'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      nik: _nikController.text.trim(),
      ktpPhotoPath: _ktpImage!.path,
      email: _emailController.text.trim(),
      rt: _rtController.text.trim(),
      rw: _rwController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (mounted) {
      if (success) {
        // Show success message for pending verification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pendaftaran berhasil! Menunggu verifikasi admin.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Redirect to login page
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go(AppRouter.login);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          // ── Left Side – Branding (Tablet only) ──────────────────────────
          if (isTablet)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF15803D), // Hijau tua
                      AppTheme.primary,
                      AppTheme.secondary,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Bergabunglah dengan\nMyPengaduan',
                        style: GoogleFonts.nunito(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Daftarkan diri Anda dan mulai laporkan keluhan\ndi lingkungan Anda dengan mudah.',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildBenefit(Icons.flash_on_rounded, 'Proses Cepat', 'Pendaftaran hanya memerlukan beberapa langkah sederhana'),
                      const SizedBox(height: 20),
                      _buildBenefit(Icons.verified_user_rounded, 'Aman & Terpercaya', 'Data Anda dijaga dengan enkripsi tingkat tinggi'),
                      const SizedBox(height: 20),
                      _buildBenefit(Icons.support_agent_rounded, 'Dukungan RT/RW', 'Langsung terhubung dengan pengurus wilayah Anda'),
                    ],
                  ),
                ),
              ),
            ),

          // ── Right Side – Register Form ────────────────────────────────────
          Expanded(
            child: Container(
              color: AppTheme.surface,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 48.0 : 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Mobile Header (gradient card) ──────────────
                          if (!isTablet) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF15803D),
                                    AppTheme.primary,
                                    AppTheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.group_add_rounded,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Daftar Akun Baru',
                                    style: GoogleFonts.nunito(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── Form Card ──────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Lengkapi Data Diri 📋',
                                    style: GoogleFonts.nunito(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Silakan isi form di bawah sesuai dengan identitas asli.',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Name field
                                  _buildLabel('Nama Lengkap *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _nameController,
                                    hintText: 'Sesuai KTP',
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // NIK field
                                  _buildLabel('NIK (Nomor Induk Kependudukan) *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _nikController,
                                    hintText: '16 digit angka',
                                    icon: Icons.badge_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'NIK tidak boleh kosong';
                                      if (v.length != 16) return 'NIK harus 16 digit angka';
                                      if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'NIK hanya boleh berisi angka';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Upload KTP
                                  _buildLabel('Upload Foto KTP *'),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _pickKtpImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        border: Border.all(
                                          color: _ktpImage == null ? AppTheme.border : AppTheme.primary,
                                          width: _ktpImage == null ? 1 : 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _ktpImage == null
                                          ? Column(
                                              children: [
                                                const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.textSecondary),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Klik untuk upload foto',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'JPG/PNG, Max. 2MB',
                                                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                                                ),
                                              ],
                                            )
                                          : Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(_ktpImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: GestureDetector(
                                                    onTap: () => setState(() => _ktpImage = null),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Email field
                                  _buildLabel('Alamat Email *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: 'nama@email.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                                      if (!v.contains('@')) return 'Email tidak valid';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // RT/RW row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel('RT *'),
                                            const SizedBox(height: 8),
                                            _buildTextField(
                                              controller: _rtController,
                                              hintText: 'Contoh: 01',
                                              icon: Icons.home_work_outlined,
                                              keyboardType: TextInputType.number,
                                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel('RW *'),
                                            const SizedBox(height: 8),
                                            _buildTextField(
                                              controller: _rwController,
                                              hintText: 'Contoh: 05',
                                              icon: Icons.location_city_outlined,
                                              keyboardType: TextInputType.number,
                                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Phone field
                                  _buildLabel('Nomor Telepon (Opsional)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _phoneController,
                                    hintText: '08xxxxxxxxxx',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),

                                  // Address field
                                  _buildLabel('Alamat Lengkap *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _addressController,
                                    hintText: 'Sesuai KTP',
                                    icon: Icons.home_outlined,
                                    maxLines: 3,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Alamat tidak boleh kosong' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  _buildLabel('Password *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: 'Minimal 8 karakter',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                                      if (v.length < 8) return 'Password minimal 8 karakter';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password
                                  _buildLabel('Konfirmasi Password *'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    hintText: 'Ketik ulang password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                                      if (v != _passwordController.text) return 'Password tidak cocok';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Terms Checkbox
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                                          activeColor: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Wrap(
                                          children: [
                                            Text('Saya setuju dengan ', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary)),
                                            Text('Syarat & Ketentuan', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                            Text(' serta ', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary)),
                                            Text('Kebijakan Privasi', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Register Button
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, _) {
                                      return SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: authProvider.isLoading ? null : _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
                                          ),
                                          child: authProvider.isLoading
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                              : Text('Daftar Sekarang', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sudah punya akun? ', style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textSecondary)),
                              TextButton(
                                onPressed: () => context.go(AppRouter.login),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppTheme.primary,
                                ),
                                child: Text(
                                  'Masuk di sini',
                                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Footer
                          Text(
                            '© 2026 MyPengaduan · Gang Annur 2 RT 05',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: GoogleFonts.nunito(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(icon, color: AppTheme.textSecondary, size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.8),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
