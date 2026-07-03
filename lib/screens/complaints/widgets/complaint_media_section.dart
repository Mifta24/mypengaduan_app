import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';
import '../complaint_detail_utils.dart';

class ComplaintPhotosSection extends StatelessWidget {
  final Complaint complaint;
  const ComplaintPhotosSection({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final urls = <String>[];
    if (c.photoUrl?.isNotEmpty == true) {
      final u = normalizeComplaintImageUrl(c.photoUrl!);
      if (u.isNotEmpty) urls.add(u);
    }
    if (c.attachments != null) {
      urls.addAll(c.attachments!
          .where((a) => !a.isVideo)
          .map((a) => normalizeComplaintImageUrl(a.fileUrl))
          .where((u) => u.isNotEmpty));
    }
    if (urls.isEmpty) return const SizedBox.shrink();

    const maxShow = 3;
    final shown = urls.take(maxShow).toList();
    final extra = urls.length - maxShow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Lampiran',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(shown.length, (i) {
              final isLast = i == shown.length - 1;
              final showOverlay = isLast && extra > 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < shown.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => showComplaintFullImage(context, shown[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: shown[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey.shade400),
                              ),
                            ),
                            if (showOverlay)
                              Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Center(
                                  child: Text('+$extra',
                                      style: GoogleFonts.nunito(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class ComplaintVideosSection extends StatelessWidget {
  final List<Attachment> videos;
  const ComplaintVideosSection({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Video Lampiran',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final video = videos[i];
              final name = video.fileName.isNotEmpty
                  ? video.fileName
                  : video.fileUrl.split('/').last.split('?').first;
              return InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(video.fileUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_outline_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text('Ketuk untuk membuka',
                                style: GoogleFonts.nunito(
                                    fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ComplaintResolutionPhotos extends StatelessWidget {
  final List<String> photoUrls;
  const ComplaintResolutionPhotos({super.key, required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Dokumentasi Penyelesaian',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => showComplaintFullImage(context, photoUrls[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: photoUrls[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
