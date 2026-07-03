import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import '../announcement_priority_utils.dart';

class AnnouncementHeaderCard extends StatelessWidget {
  final Announcement announcement;
  const AnnouncementHeaderCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: announcementPriorityGradient(a.priority),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: announcementPriorityColor(a.priority).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.priority_high, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      announcementPriorityText(a.priority),
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${a.viewsCount} kali dilihat',
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            a.title,
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MetadataItem(Icons.person, 'Admin', Colors.white70),
              _MetadataItem(
                Icons.calendar_today,
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(a.publishedAt ?? a.createdAt),
                Colors.white70,
              ),
              if (a.updatedAt != a.createdAt)
                _MetadataItem(
                  Icons.update,
                  'Diperbarui ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(a.updatedAt)}',
                  Colors.white70,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('Ditujukan untuk:',
                    style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
                const SizedBox(width: 4),
                Text(
                  a.targetAudience?.join(', ') ?? 'Semua Warga',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementContentCard extends StatelessWidget {
  final Announcement announcement;
  final void Function(String url) onShowFullImage;
  final void Function(String url, String fileName) onDownloadAttachment;

  const AnnouncementContentCard({
    super.key,
    required this.announcement,
    required this.onShowFullImage,
    required this.onDownloadAttachment,
  });

  List<AnnouncementAttachment> get _attachments {
    final structured = announcement.attachmentItems;
    if (structured != null && structured.isNotEmpty) return structured;
    return (announcement.attachments ?? [])
        .map((url) => AnnouncementAttachment.fromJson(url))
        .where((item) => item.url.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.summary != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(a.summary!,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF6B7280),
                      height: 1.5)),
            ),
            const SizedBox(height: 16),
          ],
          Text(a.content,
              style: GoogleFonts.nunito(
                  fontSize: 15, color: const Color(0xFF374151), height: 1.7)),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text('Lampiran:',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937))),
            const SizedBox(height: 8),
            ..._attachments.map((attachment) {
              final url = attachment.url;
              final isImage = isAnnouncementImageUrl(url);
              final fileName = attachment.name;
              if (isImage) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () => onShowFullImage(url),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.broken_image,
                                    color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.image, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(fileName,
                                  style: GoogleFonts.nunito(
                                      fontSize: 13, color: const Color(0xFF374151))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return InkWell(
                onTap: () => onDownloadAttachment(url, fileName),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(fileName,
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: const Color(0xFF374151))),
                      ),
                      const Icon(Icons.download, size: 20, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class AnnouncementActionButtons extends StatelessWidget {
  final bool isBookmarked;
  final bool isBookmarkLoading;
  final VoidCallback onShare;
  final VoidCallback onToggleBookmark;

  const AnnouncementActionButtons({
    super.key,
    required this.isBookmarked,
    required this.isBookmarkLoading,
    required this.onShare,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 20),
              label: Text('Bagikan Pengumuman',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isBookmarkLoading ? null : onToggleBookmark,
              icon: isBookmarkLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 18),
              label: Text('Simpan',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isBookmarked ? AppTheme.primary : const Color(0xFFF3F4F6),
                foregroundColor:
                    isBookmarked ? Colors.white : const Color(0xFF374151),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetadataItem(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.nunito(fontSize: 12, color: color)),
      ],
    );
  }
}
