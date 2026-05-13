import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_service.dart';
import '../../../services/file_download_service.dart';
import '../../../theme/app_theme.dart';
import 'edit_announcement_screen.dart';

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
    final id = _toInt(_detail['id']);
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnnouncementScreen(announcement: _detail),
      ),
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
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteAnnouncement(_toInt(_detail['id']));
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Pengumuman berhasil dihapus',
                  style: GoogleFonts.nunito()),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus pengumuman: $e',
                  style: GoogleFonts.nunito()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _toBool(_detail['is_active']);
    final priority = (_detail['priority']?.toString() ?? 'low').toLowerCase();
    final viewsCount = _toInt(_detail['views_count'] ?? _detail['views']);
    final author = _firstString(_detail,
        ['author_name', 'author', 'created_by_name', 'created_by', 'user_name'],
        fallback: 'Admin');
    final publishDate = _formatDateTime(_detail['published_at'] ??
        _detail['publish_date'] ??
        _detail['created_at']);

    final photos =
        _extractMediaItems(['photos', 'images', 'media', 'photo_urls']);
    final attachments =
        _extractMediaItems(['attachments', 'files', 'documents']);
    final coverImage = _firstString(
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
                          image:
                              coverImage.isNotEmpty && _isImageFile(coverImage)
                                  ? DecorationImage(
                                      image: NetworkImage(coverImage),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.4),
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
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]),
                          alignment: Alignment.center,
                          child: Icon(
                            priority == 'urgent'
                                ? Icons.priority_high_rounded
                                : Icons.campaign_rounded,
                            color: _priorityColor(priority),
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
                            color: Colors.white.withOpacity(0.9),
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
                                  color: AppTheme.textSecondary,
                                ),
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
                            _buildBadge(
                              isActive ? 'Aktif' : 'Nonaktif',
                              isActive ? AppTheme.primary : Colors.grey,
                              isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                            ),
                            _buildBadge(
                              _capitalize(priority),
                              _priorityColor(priority),
                              Icons.flag_rounded,
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
                                color: AppTheme.border.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
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
                                    Text(
                                      'Penulis',
                                      style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
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
                                  Text(
                                    'Diterbitkan',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                  Text(
                                    publishDate,
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary),
                                  ),
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
                        _sectionTitle('Ringkasan'),
                        const SizedBox(height: 8),
                        _contentBlock(
                          content: _firstString(_detail, ['summary', 'excerpt'],
                              fallback: '-'),
                          isItalic: true,
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Konten'),
                        const SizedBox(height: 8),
                        _contentBlock(
                          content: _detail['content']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 24),
                        if (photos.isNotEmpty || attachments.isNotEmpty) ...[
                          _sectionTitle('Lampiran & Media'),
                          const SizedBox(height: 12),
                          if (photos.isNotEmpty)
                            _mediaSection('Foto', photos, isImageSection: true),
                          if (photos.isNotEmpty && attachments.isNotEmpty)
                            const SizedBox(height: 12),
                          if (attachments.isNotEmpty)
                            _mediaSection('Dokumen', attachments,
                                isImageSection: false),
                          const SizedBox(height: 24),
                        ],
                        _sectionTitle('Informasi Tambahan'),
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
                              _detailRow(
                                  'Target Audience',
                                  _firstString(_detail,
                                      ['target_audience', 'audience', 'target'],
                                      fallback: 'Semua Warga')),
                              const Divider(height: 20),
                              _detailRow(
                                  'Komentar',
                                  _toBool(_detail['allow_comments'] ??
                                          _detail['comments_enabled'])
                                      ? 'Diizinkan'
                                      : 'Ditutup'),
                              const Divider(height: 20),
                              _detailRow('Dibuat',
                                  _formatDateTime(_detail['created_at'])),
                              const Divider(height: 20),
                              _detailRow('Terakhir Update',
                                  _formatDateTime(_detail['updated_at'])),
                              if (_extractUpdaterName() != null) ...[
                                const Divider(height: 20),
                                _detailRow('Diperbarui oleh', _extractUpdaterName()!),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
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
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
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

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _contentBlock({required String content, bool isItalic = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        content,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: AppTheme.textPrimary.withOpacity(0.8),
          height: 1.6,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _mediaSection(String title, List<Map<String, String>> items,
      {required bool isImageSection}) {
    final displayItems = isImageSection
        ? items
            .where((item) => _isImageFile(item['url'] ?? item['name'] ?? ''))
            .toList()
        : items;

    if (displayItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (isImageSection)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                final name = item['name'] ?? '-';
                final url = item['url'] ?? '';

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: url.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _AnnouncementImageViewerScreen(
                                imageUrl: url,
                                title: name,
                              ),
                            ),
                          );
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.border.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          url.isEmpty
                              ? Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                      child: Icon(
                                          Icons.image_not_supported_outlined)),
                                )
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                        child:
                                            Icon(Icons.broken_image_outlined)),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            ...displayItems.map((item) {
              final name = item['name'] ?? '-';
              final url = item['url'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined,
                      color: AppTheme.primary),
                  title: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.download_rounded,
                      size: 20, color: AppTheme.textSecondary),
                  onTap: () => _downloadAttachment(url, name),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: GoogleFonts.nunito(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _extractMediaItems(List<String> keys) {
    final List<Map<String, String>> items = [];

    for (final key in keys) {
      final raw = _detail[key];
      if (raw is List) {
        for (final item in raw) {
          if (item is String) {
            items.add({'name': item.split('/').last, 'url': item});
          } else if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final name = map['original_name']?.toString() ??
                map['file_name']?.toString() ??
                map['filename']?.toString() ??
                map['name']?.toString() ??
                map['title']?.toString() ??
                'Lampiran';
            final url = map['file_url']?.toString() ??
                map['secure_url']?.toString() ??
                map['download_url']?.toString() ??
                map['url']?.toString() ??
                map['file_path']?.toString() ??
                map['path']?.toString() ??
                '';
            items.add({'name': name, 'url': url});
          }
        }
      }
    }

    return items;
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
        url: url,
        fileName: fileName,
      );
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

  bool _isImageFile(String value) {
    final normalized = value.toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.webp') ||
        normalized.endsWith('.gif') ||
        normalized.contains('image');
  }

  String _firstString(Map<String, dynamic> source, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'aktif';
    }
    return false;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String? _extractUpdaterName() {
    final updatedBy = _detail['updated_by'];
    if (updatedBy is Map) return updatedBy['name']?.toString();
    return null;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade600;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.blue.shade600;
      case 'low':
        return AppTheme.primary;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return value.toString();
    return DateFormat('d MMMM y, HH:mm').format(date);
  }
}

class _AnnouncementImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _AnnouncementImageViewerScreen({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(color: Colors.white)),
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
                child: Text('Gagal memuat gambar',
                    style: GoogleFonts.nunito(color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}
