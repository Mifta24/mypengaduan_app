import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

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
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda harus menyetujui syarat & ketentuan'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      body: Row(
        children: [
          // Left Side - Branding (only show on tablet/desktop)
          if (isTablet)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
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
                          Icons.report_problem_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text(
                        'Bergabunglah dengan\nMyPengaduan',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Daftarkan diri Anda dan mulai laporkan keluhan di lingkungan Anda dengan mudah.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      _buildBenefit(
                        Icons.flash_on,
                        'Proses Cepat',
                        'Pendaftaran hanya memerlukan beberapa langkah sederhana',
                      ),
                      const SizedBox(height: 20),
                      _buildBenefit(
                        Icons.verified_user,
                        'Aman & Terpercaya',
                        'Data Anda dijaga dengan enkripsi tingkat tinggi',
                      ),
                      const SizedBox(height: 20),
                      _buildBenefit(
                        Icons.support_agent,
                        'Dukungan 24/7',
                        'Tim kami siap membantu kapan saja Anda membutuhkan',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Side - Register Form
          Expanded(
            child: Container(
              color: Colors.white,
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
                          // Mobile Logo
                          if (!isTablet) ...[
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1),
                                      const Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.report_problem_outlined,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Title
                          Text(
                            'Buat akun baru',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Daftar untuk mulai melaporkan keluhan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Name field
                                _buildLabel('Nama Lengkap *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _nameController,
                                  hintText: 'Masukkan nama lengkap Anda',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nama tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // NIK field
                                _buildLabel('NIK (Nomor Induk Kependudukan) *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _nikController,
                                  hintText: 'Masukkan 16 digit NIK',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'NIK tidak boleh kosong';
                                    }
                                    if (value.length != 16) {
                                      return 'NIK harus 16 digit angka sesuai KTP';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'NIK hanya boleh berisi angka';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'NIK harus 16 digit angka sesuai KTP',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
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
                                      color: const Color(0xFFF9FAFB),
                                      border: Border.all(
                                        color: _ktpImage == null
                                            ? const Color(0xFFE5E7EB)
                                            : const Color(0xFF6366F1),
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _ktpImage == null
                                        ? Column(
                                            children: [
                                              Icon(
                                                Icons.cloud_upload_outlined,
                                                size: 48,
                                                color: const Color(0xFF6B7280),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Klik untuk upload atau drag & drop',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF374151),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'JPG, JPEG atau PNG (MAX. 2MB)',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  _ktpImage!,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _ktpImage = null;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload foto KTP untuk verifikasi oleh admin',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // RT field
                                _buildLabel('Lurah (Rukun Tetangga) *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _rtController,
                                  hintText: '001',
                                  icon: Icons.home_work_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'RT tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // RW field
                                _buildLabel('RW (Rukun Warga) *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _rwController,
                                  hintText: '001',
                                  icon: Icons.location_city_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'RW tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Phone field
                                _buildLabel('Nomor Telepon'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _phoneController,
                                  hintText: '08xxxxxxxxxx',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Opsional, untuk mempermudah komunikasi',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Address field
                                _buildLabel('Alamat Lengkap *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _addressController,
                                  hintText: 'Masukkan alamat lengkap sesuai KTP',
                                  icon: Icons.home_outlined,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Alamat tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Alamat harus sesuai dengan yang tertera di KTP',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                _buildLabel('Password *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _passwordController,
                                  hintText: 'Minimal 8 karakter',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password tidak boleh kosong';
                                    }
                                    if (value.length < 8) {
                                      return 'Password minimal 8 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password field
                                _buildLabel('Konfirmasi Password *'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  hintText: 'Ulangi password Anda',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Konfirmasi password tidak boleh kosong';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Terms checkbox
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreeToTerms = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF6366F1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Wrap(
                                        children: [
                                          Text(
                                            'Saya setuju dengan ',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFF374151),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              // TODO: Show terms
                                            },
                                            child: Text(
                                              'Syarat & Ketentuan',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6366F1),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' dan ',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFF374151),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              // TODO: Show privacy policy
                                            },
                                            child: Text(
                                              'Kebijakan Privasi',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6366F1),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    return SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : _handleRegister,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6366F1),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          disabledBackgroundColor:
                                              const Color(0xFFD1D5DB),
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                'Daftar Sekarang',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun? ',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go(AppRouter.login),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Masuk di sini',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Text(
                            '© 2026 MyPengaduan. Dikembangkan untuk RT/RW Indonesia.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
