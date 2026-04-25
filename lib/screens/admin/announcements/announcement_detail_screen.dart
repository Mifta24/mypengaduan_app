import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_service.dart';
import 'edit_announcement_screen.dart';

class AdminAnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const AdminAnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AdminAnnouncementDetailScreen> createState() => _AdminAnnouncementDetailScreenState();
}

class _AdminAnnouncementDetailScreenState extends State<AdminAnnouncementDetailScreen> {
  final AdminService _adminService = AdminService();

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
        title: const Text('Hapus Pengumuman'),
        content: const Text('Yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
          const SnackBar(content: Text('Pengumuman berhasil dihapus'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus pengumuman: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _toBool(_detail['is_active']);
    final priority = (_detail['priority']?.toString() ?? 'low').toLowerCase();
    final viewsCount = _toInt(_detail['views_count'] ?? _detail['views']);
    final author = _firstString(_detail, ['author_name', 'author', 'created_by_name', 'created_by', 'user_name'], fallback: 'Ketua RT');
    final publishDate = _formatDateTime(_detail['published_at'] ?? _detail['publish_date'] ?? _detail['created_at']);

    final photos = _extractMediaItems(['photos', 'images', 'media', 'photo_urls']);
    final attachments = _extractMediaItems(['attachments', 'files', 'documents']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: priority == 'urgent' 
                                ? [Colors.red.shade400, Colors.red.shade800]
                                : priority == 'high'
                                    ? [Colors.orange.shade400, Colors.orange.shade800]
                                    : priority == 'medium'
                                        ? [Colors.blue.shade400, Colors.blue.shade800]
                                        : [Colors.green.shade400, Colors.green.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: 20,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ]
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            priority == 'urgent' ? Icons.priority_high : Icons.announcement,
                            color: _priorityColor(priority),
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 20,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
                            foregroundColor: _priorityColor(priority),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                          onPressed: _editAnnouncement,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _detail['title']?.toString() ?? '-',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(isActive ? 'Aktif' : 'Nonaktif', isActive ? Colors.green : Colors.grey, isActive ? Icons.check_circle : Icons.cancel),
                            _chip(_capitalize(priority), _priorityColor(priority), Icons.low_priority),
                            _chip('$viewsCount views', Colors.blueGrey, Icons.visibility),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('Oleh $author', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Tanggal Publish', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    publishDate,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 640 ? 1 : 3;
                            final itemWidth = (width - (10 * (crossAxisCount - 1))) / crossAxisCount;

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: itemWidth,
                                  child: _statCard('Total Views', '$viewsCount', Icons.visibility),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _statCard('Status', isActive ? 'Aktif' : 'Nonaktif', Icons.toggle_on),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _statCard('Prioritas', _capitalize(priority), Icons.flag),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Konten Pengumuman'),
                        const SizedBox(height: 8),
                        _contentBlock(
                          title: 'Ringkasan',
                          content: _firstString(_detail, ['summary', 'excerpt'], fallback: '-'),
                        ),
                        const SizedBox(height: 8),
                        _contentBlock(
                          title: '',
                          content: _detail['content']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('Lampiran & Foto'),
                        const SizedBox(height: 8),
                        _mediaSection('Foto (${photos.length})', photos, isImageSection: true),
                        const SizedBox(height: 8),
                        _mediaSection('Lampiran (${attachments.length})', attachments, isImageSection: false),
                        const SizedBox(height: 18),
                        _sectionTitle('Detail Pengumuman'),
                        const SizedBox(height: 8),
                        _detailRow('Slug', _detail['slug']?.toString() ?? '-'),
                        _detailRow('Penulis', author),
                        _detailRow('Tanggal Publish', _formatDateTime(_detail['published_at'] ?? _detail['publish_date'])),
                        _detailRow('Prioritas', _capitalize(priority)),
                        _detailRow('Target Audience', _firstString(_detail, ['target_audience', 'audience', 'target'], fallback: 'All')),
                        _detailRow('Komentar', _toBool(_detail['allow_comments'] ?? _detail['comments_enabled']) ? 'Diizinkan' : 'Tidak Diizinkan'),
                        _detailRow('Dibuat', _formatDateTime(_detail['created_at'])),
                        _detailRow('Terakhir Update', _formatDateTime(_detail['updated_at'])),
                        const SizedBox(height: 18),
                        _sectionTitle('Aksi'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _editAnnouncement,
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Pengumuman'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _deleteAnnouncement,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Hapus Pengumuman', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _contentBlock({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
          ],
          Text(content),
        ],
      ),
    );
  }

  Widget _mediaSection(String title, List<Map<String, String>> items, {required bool isImageSection}) {
    final displayItems = isImageSection
        ? items.where((item) => _isImageFile(item['url'] ?? item['name'] ?? '')).toList()
        : items;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (displayItems.isEmpty)
            Text('Tidak ada data', style: TextStyle(color: Colors.grey.shade600))
          else if (isImageSection)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.4,
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
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: url.isEmpty
                                ? Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                                  )
                                : Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(child: Icon(Icons.broken_image_outlined)),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            ...displayItems.map((item) {
              final name = item['name'] ?? '-';
              final url = item['url'] ?? '';
              final isImageAttachment = _isImageFile(url.isNotEmpty ? url : name);

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: url.isNotEmpty ? Text(url, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                trailing: isImageAttachment && url.isNotEmpty
                    ? TextButton(
                        onPressed: () {
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
                        child: const Text('Lihat ukuran penuh'),
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: Colors.blueGrey, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
            final name =
                map['filename']?.toString() ?? map['name']?.toString() ?? map['title']?.toString() ?? 'File';
            final url = map['url']?.toString() ?? map['path']?.toString() ?? map['file_url']?.toString() ?? '';
            items.add({'name': name, 'url': url});
          }
        }
      }
    }

    return items;
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

  String _firstString(Map<String, dynamic> source, List<String> keys, {String fallback = '-'}) {
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
      return normalized == '1' || normalized == 'true' || normalized == 'yes' || normalized == 'aktif';
    }
    return false;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
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
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Gagal memuat gambar'),
              );
            },
          ),
        ),
      ),
    );
  }
}
