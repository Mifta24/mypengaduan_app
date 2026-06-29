import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen viewer for a single announcement image/attachment thumbnail.
class AnnouncementImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const AnnouncementImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat gambar', style: GoogleFonts.nunito(color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}
