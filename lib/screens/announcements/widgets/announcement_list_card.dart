import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/announcement_model.dart' as models;
import '../../../theme/app_theme.dart';

class AnnouncementListCard extends StatelessWidget {
  final models.Announcement announcement;
  final VoidCallback onTap;

  const AnnouncementListCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  ({Color color, Color bg, String label}) get _priorityInfo {
    switch (announcement.priority.toLowerCase()) {
      case 'urgent':
        return (
          color: const Color(0xFFEF4444),
          bg: const Color(0xFFFEE2E2),
          label: 'Mendesak'
        );
      case 'high':
        return (
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFEF3C7),
          label: 'Tinggi'
        );
      case 'medium':
        return (
          color: const Color(0xFF3B82F6),
          bg: const Color(0xFFDBEAFE),
          label: 'Sedang'
        );
      case 'low':
        return (
          color: const Color(0xFF10B981),
          bg: const Color(0xFFD1FAE5),
          label: 'Rendah'
        );
      default:
        return (
          color: const Color(0xFF6B7280),
          bg: const Color(0xFFF3F4F6),
          label: 'Sedang'
        );
    }
  }

  String? get _coverImageUrl {
    final a = announcement;
    if (a.coverImage != null && a.coverImage!.isNotEmpty) return a.coverImage;
    if (a.attachmentItems != null && a.attachmentItems!.isNotEmpty) {
      final img = a.attachmentItems!.firstWhere(
        (att) =>
            att.url.toLowerCase().endsWith('.jpg') ||
            att.url.toLowerCase().endsWith('.png') ||
            att.url.toLowerCase().endsWith('.jpeg'),
        orElse: () => const models.AnnouncementAttachment(name: '', url: ''),
      );
      if (img.url.isNotEmpty) return img.url;
    }
    if (a.attachments != null && a.attachments!.isNotEmpty) {
      final img = a.attachments!.firstWhere(
        (att) =>
            att.toLowerCase().endsWith('.jpg') ||
            att.toLowerCase().endsWith('.png') ||
            att.toLowerCase().endsWith('.jpeg'),
        orElse: () => '',
      );
      if (img.isNotEmpty) return img;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final pi = _priorityInfo;
    final cover = _coverImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: a.isSticky
            ? Border.all(color: Colors.orange.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    if (cover != null)
                      Image.network(
                        cover,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _FallbackHeader(),
                      )
                    else
                      _FallbackHeader(),
                    if (a.isSticky)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Disematkan',
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pi.bg.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: pi.color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark, size: 14, color: pi.color),
                            const SizedBox(width: 4),
                            Text(pi.label,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: pi.color)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(
                              a.publishedAt ?? a.createdAt),
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.person_outline,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('Admin',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.title,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.summary?.isNotEmpty == true
                          ? a.summary!
                          : a.content,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Target: ',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                        Text(
                          a.targetAudience?.join(', ') ?? 'Semua Warga',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.8),
            AppTheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.campaign_outlined,
            size: 40, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
