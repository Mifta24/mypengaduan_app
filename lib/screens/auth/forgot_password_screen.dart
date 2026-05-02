import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();

  // Step 1 — Email
  final _emailCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // Step 2 — OTP
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // Step 3 — New password
  final _passCtrl    = TextEditingController();
  final _passConfCtrl = TextEditingController();
  final _passFormKey = GlobalKey<FormState>();
  bool _obscurePass  = true;
  bool _obscureConf  = true;

  int  _step      = 1;
  bool _loading   = false;
  String _resetToken = '';

  // Countdown resend
  int  _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _passCtrl.dispose();
    _passConfCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step 1: kirim OTP ─────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await _authService.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      _startCountdown();
      setState(() => _step = 2);
    } else {
      _showSnack(res['message'] ?? 'Gagal mengirim OTP', error: true);
    }
  }

  // ── Step 2: verifikasi OTP ────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      _showSnack('Masukkan 6 digit kode OTP', error: true);
      return;
    }
    setState(() => _loading = true);
    final res = await _authService.verifyOtp(
      email: _emailCtrl.text.trim(),
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      _resetToken = res['reset_token'] ?? '';
      setState(() => _step = 3);
    } else {
      _showSnack(res['message'] ?? 'OTP tidak valid', error: true);
    }
  }

  // ── Step 3: reset password ────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await _authService.resetPassword(
      resetToken: _resetToken,
      password: _passCtrl.text,
      passwordConfirmation: _passConfCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      _showSnack('Password berhasil direset! Silakan login.');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(res['message'] ?? 'Gagal mereset password', error: true);
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    setState(() => _loading = true);
    final res = await _authService.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      _startCountdown();
      for (final c in _otpCtrls) c.clear();
      _otpFocus.first.requestFocus();
      _showSnack('Kode OTP baru telah dikirim');
    } else {
      _showSnack(res['message'] ?? 'Gagal mengirim ulang OTP', error: true);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) _countdown--;
        else t.cancel();
      });
    });
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
      backgroundColor: error ? Colors.red.shade700 : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background dark green
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.bgDeep, AppTheme.bgDark, AppTheme.bgMid],
              ),
            ),
          ),
          // Leaf decorations
          _leaf(top: 70,  right: 16, size: 50, rot: 0.3),
          _leaf(top: 130, left: 8,   size: 34, rot: -0.5),
          _leaf(bottom: 160, left: 14,  size: 42, rot: -0.3),
          _leaf(bottom: 100, right: 10, size: 28, rot: 0.6),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: Column(
                      children: [
                        _buildStepIndicator(),
                        const SizedBox(height: 28),
                        _buildStepCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    final titles = ['Lupa Password', 'Verifikasi OTP', 'Password Baru'];
    final subs   = [
      'Masukkan email terdaftar Anda',
      'Masukkan kode yang dikirim ke email',
      'Buat password baru yang kuat',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (_step > 1) {
                setState(() => _step--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titles[_step - 1],
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(subs[_step - 1],
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppTheme.accent, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: (i ~/ 2) < _step - 1
                  ? AppTheme.accent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          );
        }
        final step = i ~/ 2 + 1;
        final done   = step < _step;
        final active = step == _step;
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: done
                ? AppTheme.accent
                : active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: AppTheme.bgDark)
                : Text('$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? AppTheme.bgDark : Colors.white.withValues(alpha: 0.5),
                    )),
          ),
        );
      }),
    );
  }

  // ── Card konten per step ──────────────────────────────────────
  Widget _buildStepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _step == 1
              ? _buildStep1()
              : _step == 2
                  ? _buildStep2()
                  : _buildStep3(),
        ),
      ),
    );
  }

  // ── Step 1: Email ─────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.email_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Verifikasi Email',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Masukkan alamat email yang terdaftar. Kami akan mengirimkan kode OTP untuk verifikasi.',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          _inputField(
            controller: _emailCtrl,
            label: 'Alamat Email',
            hint: 'contoh@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
              if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _primaryButton(
            label: 'Kirim Kode OTP',
            icon: Icons.send_rounded,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pin_rounded, color: Color(0xFF0891B2), size: 22),
            ),
            const SizedBox(width: 12),
            Text('Kode Verifikasi',
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Kode dikirim ke '),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6 kotak OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 20),

        // Countdown + resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tidak menerima kode? ',
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary)),
            GestureDetector(
              onTap: _countdown > 0 ? null : _resendOtp,
              child: Text(
                _countdown > 0 ? 'Kirim ulang (${_countdown}s)' : 'Kirim Ulang',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _countdown > 0 ? Colors.grey : AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Verifikasi',
          icon: Icons.verified_rounded,
          onPressed: _verifyOtp,
          color: const Color(0xFF0891B2),
        ),
      ],
    );
  }

  Widget _otpBox(int i) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextFormField(
        controller: _otpCtrls[i],
        focusNode: _otpFocus[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.nunito(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            _otpFocus[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _otpFocus[i - 1].requestFocus();
          }
        },
      ),
    );
  }

  // ── Step 3: Password Baru ─────────────────────────────────────
  Widget _buildStep3() {
    return Form(
      key: _passFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Buat Password Baru',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Password minimal 8 karakter, kombinasi huruf dan angka.',
              style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          _inputField(
            controller: _passCtrl,
            label: 'Password Baru',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
              if (v.length < 8) return 'Minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _passConfCtrl,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password baru',
            icon: Icons.lock_reset_rounded,
            obscure: _obscureConf,
            suffixIcon: IconButton(
              icon: Icon(_obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _obscureConf = !_obscureConf),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
              if (v != _passCtrl.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _primaryButton(label: 'Reset Password', icon: Icons.check_circle_rounded, onPressed: _resetPassword),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade400)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = AppTheme.primary,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: _loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(_loading ? 'Memproses...' : label,
            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _leaf({double? top, double? bottom, double? left, double? right,
      required double size, required double rot}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: rot,
        child: Icon(Icons.eco_rounded, size: size,
            color: AppTheme.primaryDark.withValues(alpha: 0.4)),
      ),
    );
  }
}