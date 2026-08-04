import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../services/file_download_service.dart';
import '../../../theme/app_theme.dart';
import 'announcement_detail_utils.dart';
import 'widgets/announcement_detail_widgets.dart';
import 'widgets/announcement_media_section.dart';

class AdminAnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const AdminAnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AdminAnnouncementDetailScreen> createState() =>
      _AdminAnnouncementDetailScreenState();
}

class _AdminAnnouncementDetailScreenState
    extends State<AdminAnnouncementDetailScreen> {
  final AdminService _adminService = AdminService();
  final FileDownloadService _fileDownloadService = FileDownloadService();

  late Map<String, dynamic> _detail;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _detail = Map<String, dynamic>.from(widget.announcement);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = announcementToInt(_detail['id']);
    if (id == 0) return;

    setState(() => _isLoading = true);

    try {
      final response = await _adminService.getAnnouncement(id);
      final data = response['data'] ?? response['announcement'] ?? response;
      if (data is Map) {
        setState(() {
          _detail = Map<String, dynamic>.from(data);
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editAnnouncement() async {
    final result = await context.push(
      AppRouter.adminAnnouncementsEdit,
      extra: _detail,
    );

    if (result == true) {
      _hasChanges = true;
      await _loadDetail();
    }
  }

  Future<void> _deleteAnnouncement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Pengumuman',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus pengumuman ini?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.nunito())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus',
                style: GoogleFonts.nunito(
                    color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteAnnouncement(announcementToInt(_detail['id']));
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Pengumuman berhasil dihapus',
                  style: GoogleFonts.nunito()),
              backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus pengumuman: $e',
                  style: GoogleFonts.nunito()),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _openImageViewer(String url, String name) {
    context.push(
      AppRouter.adminAnnouncementImage,
      extra: {'imageUrl': url, 'title': name},
    );
  }

  Future<void> _downloadAttachment(String url, String fileName) async {
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL lampiran tidak tersedia')),
      );
      return;
    }

    try {
      await _fileDownloadService.downloadToDownloads(
          url: url, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File tersimpan di Downloads: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh lampiran: $e')),
      );
    }
  }

  String? _extractUpdaterName() {
    final updatedBy = _detail['updated_by'];
    if (updatedBy is Map) return updatedBy['name']?.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = announcementToBool(_detail['is_active']);
    final priority = (_detail['priority']?.toString() ?? 'low').toLowerCase();
    final viewsCount =
        announcementToInt(_detail['views_count'] ?? _detail['views']);
    final author = firstAnnouncementString(_detail,
        ['author_name', 'author', 'created_by_name', 'created_by', 'user_name'],
        fallback: 'Admin');
    final publishDate = formatAnnouncementDateTime(_detail['published_at'] ??
        _detail['publish_date'] ??
        _detail['created_at']);

    final photos = extractAnnouncementMediaItems(
        _detail, ['photos', 'images', 'media', 'photo_urls']);
    final attachments = extractAnnouncementMediaItems(
        _detail, ['attachments', 'files', 'documents']);
    final coverImage = firstAnnouncementString(
        _detail, ['cover_image', 'cover', 'thumbnail', 'image_url', 'image'],
        fallback: '');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Detail Pengumuman',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          image: coverImage.isNotEmpty &&
                                  isAnnouncementImageFile(coverImage)
                              ? DecorationImage(
                                  image: NetworkImage(coverImage),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.4),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: -35,
                        left: 20,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]),
                          alignment: Alignment.center,
                          child: Icon(
                            priority == 'urgent'
                                ? Icons.priority_high_rounded
                                : Icons.campaign_rounded,
                            color: announcementPriorityColor(priority),
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_rounded,
                                  size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '$viewsCount Views',
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detail['title']?.toString() ?? '-',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AnnouncementDetailBadge(
                              label: isActive ? 'Aktif' : 'Nonaktif',
                              color: isActive ? AppTheme.primary : Colors.grey,
                              icon: isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                            ),
                            AnnouncementDetailBadge(
                              label: capitalizeAnnouncement(priority),
                              color: announcementPriorityColor(priority),
                              icon: Icons.flag_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.border.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline_rounded,
                                    color: AppTheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Penulis',
                                        style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                    Text(
                                      author,
                                      style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Diterbitkan',
                                      style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                  Text(publishDate,
                                      style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AnnouncementSectionTitle('Ringkasan'),
                        const SizedBox(height: 8),
                        AnnouncementContentBlock(
                          content: firstAnnouncementString(
                              _detail, ['summary', 'excerpt'],
                              fallback: '-'),
                          isItalic: true,
                        ),
                        const SizedBox(height: 18),
                        const AnnouncementSectionTitle('Konten'),
                        const SizedBox(height: 8),
                        AnnouncementContentBlock(
                            content: _detail['content']?.toString() ?? '-'),
                        const SizedBox(height: 24),
                        if (photos.isNotEmpty || attachments.isNotEmpty) ...[
                          const AnnouncementSectionTitle('Lampiran & Media'),
                          const SizedBox(height: 12),
                          if (photos.isNotEmpty)
                            AnnouncementMediaSection(
                              title: 'Foto',
                              items: photos,
                              isImageSection: true,
                              onImageTap: _openImageViewer,
                              onDownloadAttachment: _downloadAttachment,
                            ),
                          if (photos.isNotEmpty && attachments.isNotEmpty)
                            const SizedBox(height: 12),
                          if (attachments.isNotEmpty)
                            AnnouncementMediaSection(
                              title: 'Dokumen',
                              items: attachments,
                              isImageSection: false,
                              onImageTap: _openImageViewer,
                              onDownloadAttachment: _downloadAttachment,
                            ),
                          const SizedBox(height: 24),
                        ],
                        const AnnouncementSectionTitle('Informasi Tambahan'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              AnnouncementDetailRow(
                                label: 'Target Audience',
                                value: firstAnnouncementString(_detail,
                                    ['target_audience', 'audience', 'target'],
                                    fallback: 'Semua Warga'),
                              ),
                              const Divider(height: 20),
                              AnnouncementDetailRow(
                                label: 'Komentar',
                                value: announcementToBool(
                                        _detail['allow_comments'] ??
                                            _detail['comments_enabled'])
                                    ? 'Diizinkan'
                                    : 'Ditutup',
                              ),
                              const Divider(height: 20),
                              AnnouncementDetailRow(
                                  label: 'Dibuat',
                                  value: formatAnnouncementDateTime(
                                      _detail['created_at'])),
                              const Divider(height: 20),
                              AnnouncementDetailRow(
                                  label: 'Terakhir Update',
                                  value: formatAnnouncementDateTime(
                                      _detail['updated_at'])),
                              if (_extractUpdaterName() != null) ...[
                                const Divider(height: 20),
                                AnnouncementDetailRow(
                                    label: 'Diperbarui oleh',
                                    value: _extractUpdaterName()!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _deleteAnnouncement,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text('Hapus',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _editAnnouncement,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text('Edit Pengumuman',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
