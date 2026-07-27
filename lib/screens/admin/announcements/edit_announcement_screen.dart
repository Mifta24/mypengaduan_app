import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const EditAnnouncementScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _contentController;
  final AdminService _adminService = AdminService();

  late String _priority;
  late bool _isSticky;
  late bool _isActive;
  late bool _wasActive; // tracks original status to detect activation
  bool _isLoading = false;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _existingAttachments = [];
  final List<int> _removedAttachmentIndices = [];
  final List<PlatformFile> _newAttachments = [];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.announcement['title'] ?? '');
    _summaryController =
        TextEditingController(text: widget.announcement['summary'] ?? '');
    _contentController =
        TextEditingController(text: widget.announcement['content'] ?? '');
    _priority =
        widget.announcement['priority']?.toString().toLowerCase() ?? 'medium';
    _isSticky = widget.announcement['is_sticky'] == true ||
        widget.announcement['is_sticky'] == 1;
    _isActive = widget.announcement['is_active'] == true ||
        widget.announcement['is_active'] == 1;
    _wasActive = _isActive;

    final raw = widget.announcement['attachments'];
    if (raw is List) {
      _existingAttachments = raw.map((a) {
        if (a is Map<String, dynamic>) return a;
        return <String, dynamic>{
          'path': a.toString(),
          'original_name': a.toString().split('/').last
        };
      }).toList();
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
      );
      if (result != null) {
        setState(() => _newAttachments.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memilih file: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final activatingNow = _isActive && !_wasActive;

    try {
      await _adminService.updateAnnouncement(
        widget.announcement['id'],
        {
          'title': _titleController.text.trim(),
          'summary': _summaryController.text.trim(),
          'content': _contentController.text.trim(),
          'priority': _priority,
          'is_sticky': _isSticky ? 1 : 0,
          'is_active': _isActive ? 1 : 0,
        },
        imagePath: _imagePath,
        attachmentPaths: _newAttachments
            .where((f) => f.path != null)
            .map((f) => f.path!)
            .toList(),
        removeAttachmentIndices: _removedAttachmentIndices,
      );

      // Jika pengumuman baru saja diaktifkan (sebelumnya draft), panggil endpoint
      // publish agar backend mengirim notifikasi FCM ke semua user.
      if (activatingNow) {
        try {
          await _adminService.publishAnnouncement(widget.announcement['id']);
        } catch (_) {
          // Notifikasi gagal dikirim, tapi data sudah tersimpan — tidak perlu rollback.
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activatingNow
                ? 'Pengumuman dipublikasi & notifikasi dikirim'
                : 'Pengumuman berhasil diperbarui'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final data = e.response?.data;
        String message = 'Gagal memperbarui pengumuman';
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            message = firstError is List && (firstError).isNotEmpty
                ? firstError.first.toString()
                : firstError.toString();
          } else if (data['message'] != null) {
            message = data['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui pengumuman: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content:
            const Text('Apakah Anda yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.deleteAnnouncement(widget.announcement['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengumuman berhasil dihapus'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengumuman: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pengumuman'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _deleteAnnouncement,
            tooltip: 'Hapus',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Badge
            Container(
              decoration: BoxDecoration(
                color: _isActive ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _isActive
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? Icons.check_circle : Icons.info_outline,
                      color: _isActive ? AppTheme.success : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isActive ? 'Status: Aktif' : 'Status: Nonaktif',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: _isActive ? AppTheme.success : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive
                                ? 'Pengumuman ini sedang ditampilkan'
                                : 'Pengumuman ini tidak ditampilkan',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.title,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Informasi Utama',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Judul Pengumuman *',
                        hint: 'Masukkan judul pengumuman',
                        prefixIcon: const Icon(Icons.article),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _summaryController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Ringkasan',
                        hint: 'Ringkasan singkat pengumuman (opsional)',
                        prefixIcon: const Icon(Icons.short_text),
                      ),
                      maxLines: 2,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Konten Pengumuman',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Konten *',
                        hint: 'Tulis konten pengumuman lengkap di sini',
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Konten tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Gambar Pengumuman (Baru)',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_imagePath != null) ...[
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: AppTheme.danger,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _imagePath = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.purple.shade200,
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 32, color: Colors.purple.shade400),
                            const SizedBox(height: 8),
                            Text(
                              _imagePath == null
                                  ? 'Pilih Gambar'
                                  : 'Ganti Gambar',
                              style: GoogleFonts.nunito(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih gambar baru jika ingin mengganti gambar pengumuman saat ini.',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attachment Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.attach_file,
                              color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Lampiran',
                            style: GoogleFonts.nunito(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Existing attachments
                    if (_existingAttachments.isNotEmpty) ...[
                      Text('Lampiran Saat Ini',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Column(
                        children:
                            _existingAttachments.asMap().entries.map((entry) {
                          final i = entry.key;
                          final att = entry.value;
                          final name = att['original_name']?.toString() ??
                              att['path']?.toString().split('/').last ??
                              'File';
                          final ext =
                              name.contains('.') ? name.split('.').last : '';
                          final isRemoved =
                              _removedAttachmentIndices.contains(i);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_fileIcon(ext),
                                color: isRemoved ? Colors.grey : Colors.teal),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                decoration: isRemoved
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isRemoved ? Colors.grey : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isRemoved
                                    ? Icons.undo
                                    : Icons.remove_circle_outline,
                                color:
                                    isRemoved ? Colors.teal : AppTheme.danger,
                              ),
                              onPressed: () => setState(() {
                                if (isRemoved) {
                                  _removedAttachmentIndices.remove(i);
                                } else {
                                  _removedAttachmentIndices.add(i);
                                }
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(),
                    ],

                    // New attachments
                    if (_newAttachments.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lampiran Baru',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          ..._newAttachments.asMap().entries.map((entry) {
                            final file = entry.value;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(_fileIcon(file.extension ?? ''),
                                  color: Colors.teal),
                              title: Text(file.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(_formatFileSize(file.size)),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: AppTheme.danger),
                                onPressed: () => setState(
                                    () => _newAttachments.removeAt(entry.key)),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),

                    InkWell(
                      onTap: _pickAttachments,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Colors.teal.shade400),
                            const SizedBox(width: 8),
                            Text('Tambah Lampiran',
                                style: GoogleFonts.nunito(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Format: JPG, PNG, PDF, DOC, XLS (maks. 10 MB/file)',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pengaturan',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: AppTheme.inputDecoration(
                        label: 'Prioritas',
                        prefixIcon: const Icon(Icons.priority_high),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Rendah')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Sedang')),
                        DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                        DropdownMenuItem(
                            value: 'urgent', child: Text('Mendesak')),
                      ],
                      onChanged: (value) {
                        setState(() => _priority = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sticky Switch
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text('Pin di Atas'),
                        subtitle:
                            const Text('Pengumuman akan selalu muncul di atas'),
                        value: _isSticky,
                        onChanged: (value) {
                          setState(() => _isSticky = value);
                        },
                        secondary: Icon(
                          Icons.push_pin,
                          color: _isSticky ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAnnouncement,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Perbarui'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
