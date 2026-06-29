import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import 'user_detail_widgets.dart';

/// KTP preview block shown in the "Verifikasi Identitas" section, with a
/// tap-to-zoom full image dialog.
class UserKtpCard extends StatelessWidget {
  final String userName;
  final String ktpUrl;

  const UserKtpCard({super.key, required this.userName, required this.ktpUrl});

  @override
  Widget build(BuildContext context) {
    if (ktpUrl.isEmpty) {
      return const UserDetailEmptyTile(title: 'KTP Tidak Ada', subtitle: 'Foto KTP belum diunggah.');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              ktpUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey.shade100,
                child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey)),
              ),
            ),
          ),
          InkWell(
            onTap: () => _showKtpImage(context, ktpUrl, 'KTP $userName'),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text('Lihat Ukuran Penuh', style: GoogleFonts.nunito(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showKtpImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Gagal memuat gambar KTP'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
