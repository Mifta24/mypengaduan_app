import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement['title'] ?? '');
    _summaryController = TextEditingController(text: widget.announcement['summary'] ?? '');
    _contentController = TextEditingController(text: widget.announcement['content'] ?? '');
    _priority = widget.announcement['priority']?.toString().toLowerCase() ?? 'medium';
    _isSticky = widget.announcement['is_sticky'] == true || widget.announcement['is_sticky'] == 1;
    _isActive = widget.announcement['is_active'] == true || widget.announcement['is_active'] == 1;
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

    try {
      await _adminService.updateAnnouncement(
        widget.announcement['id'],
        {
          'title': _titleController.text.trim(),
          'excerpt': _summaryController.text.trim(),
          'content': _contentController.text.trim(),
          'priority': _priority,
          'is_sticky': _isSticky ? 1 : 0,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui pengumuman: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        content: const Text('Apakah Anda yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          const SnackBar(
            content: Text('Pengumuman berhasil dihapus'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
            Card(
              elevation: 2,
              color: _isActive ? Colors.green.shade50 : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? Icons.check_circle : Icons.info_outline,
                      color: _isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isActive ? 'Status: Aktif' : 'Status: Nonaktif',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive
                                ? 'Pengumuman ini sedang ditampilkan'
                                : 'Pengumuman ini tidak ditampilkan',
                            style: TextStyle(
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.title,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Informasi Utama',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Pengumuman *',
                        hintText: 'Masukkan judul pengumuman',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                      decoration: InputDecoration(
                        labelText: 'Ringkasan',
                        hintText: 'Ringkasan singkat pengumuman (opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Konten Pengumuman',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Konten *',
                        hintText: 'Tulis konten pengumuman lengkap di sini',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignLabelWithHint: true,
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

            // Settings Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: 'Prioritas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.priority_high),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Rendah')),
                        DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                        DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                        DropdownMenuItem(value: 'urgent', child: Text('Mendesak')),
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
                        subtitle: const Text('Pengumuman akan selalu muncul di atas'),
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
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
