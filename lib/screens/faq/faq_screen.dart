import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _openIndex;

  static const _faqs = [
    (
      q: 'Apa itu MyPengaduan?',
      a: 'MyPengaduan adalah aplikasi sistem pengaduan masyarakat yang memudahkan warga untuk menyampaikan keluhan, saran, dan aspirasi kepada pengurus RT setempat secara digital, cepat, dan transparan.',
    ),
    (
      q: 'Bagaimana cara membuat pengaduan?',
      a: 'Tekan tombol "+" di bagian bawah layar atau pilih "Lapor Keluhan" pada menu Aksi Cepat. Isi formulir dengan kategori, lokasi, judul, deskripsi, dan foto (opsional), lalu tekan "Lanjutkan" untuk mengirim pengaduan.',
    ),
    (
      q: 'Apakah akun harus diverifikasi sebelum membuat pengaduan?',
      a: 'Ya. Akun Anda perlu diverifikasi oleh admin terlebih dahulu sebelum dapat membuat pengaduan. Verifikasi dilakukan berdasarkan data KTP yang Anda daftarkan saat registrasi.',
    ),
    (
      q: 'Bagaimana cara memantau status pengaduan saya?',
      a: 'Buka menu "Riwayat" di bagian bawah layar, lalu pilih pengaduan yang ingin Anda pantau. Status pengaduan ditampilkan dalam alur: Diterima → Diverifikasi → Dalam Proses → Selesai.',
    ),
    (
      q: 'Berapa lama pengaduan akan ditangani?',
      a: 'Proses penanganan pengaduan bergantung pada jenis dan kompleksitas masalah. Umumnya verifikasi dilakukan dalam 1×24 jam, dan tindak lanjut dilakukan dalam 3–7 hari kerja.',
    ),
    (
      q: 'Apakah saya bisa mengedit pengaduan setelah dikirim?',
      a: 'Pengaduan hanya dapat diedit selama masih berstatus "Menunggu Verifikasi". Setelah diverifikasi atau diproses oleh admin, pengaduan tidak dapat diubah.',
    ),
    (
      q: 'Bagaimana cara mendapatkan notifikasi update pengaduan?',
      a: 'Notifikasi akan dikirim secara otomatis melalui push notification ke perangkat Anda setiap kali ada perubahan status pada pengaduan yang Anda buat.',
    ),
    (
      q: 'Apakah data pengaduan saya bersifat rahasia?',
      a: 'Data pribadi Anda dijaga kerahasiaannya. Namun, konten pengaduan dapat dilihat oleh admin untuk keperluan tindak lanjut. Kami berkomitmen menjaga privasi pengguna sesuai ketentuan yang berlaku.',
    ),
    (
      q: 'Bagaimana jika pengaduan saya ditolak?',
      a: 'Jika pengaduan ditolak, Anda akan menerima notifikasi beserta alasan penolakan dari admin. Anda dapat mengajukan pengaduan baru dengan melengkapi informasi yang kurang.',
    ),
    (
      q: 'Bagaimana cara menghubungi tim admin?',
      a: 'Anda dapat menghubungi kami melalui menu "Hubungi Kami" yang tersedia di halaman Aksi Cepat, atau melalui kontak yang tertera di halaman profil aplikasi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.bgDeep, AppTheme.bgDark, AppTheme.bgMid],
              ),
            ),
          ),
          // ── Leaf decorations ────────────────────────────────
          _leaf(top: 80, right: 16, size: 52, rot: 0.3),
          _leaf(top: 140, left: 8, size: 34, rot: -0.5),
          _leaf(bottom: 120, left: 16, size: 44, rot: -0.3),
          _leaf(bottom: 80, right: 12, size: 30, rot: 0.6),

          // ── Content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _faqs.length,
                    itemBuilder: (_, i) => _buildFaqItem(i),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FAQ',
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Pertanyaan yang Sering Diajukan',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    final isOpen = _openIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _openIndex = isOpen ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isOpen
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? AppTheme.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(faq.q,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3)),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ],
              ),
            ),
            if (isOpen) ...[
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 12, 16, 16),
                child: Text(faq.a,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.6)),
              ),
            ],
          ],
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
