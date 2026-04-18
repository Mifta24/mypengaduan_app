import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final AdminService _adminService = AdminService();
  
  String _priority = 'medium';
  bool _isSticky = false;
  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.createAnnouncement({
        'title': _titleController.text.trim(),
        'excerpt': _summaryController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _priority,
        'is_sticky': _isSticky ? 1 : 0,
        'is_active': _isPublished ? 1 : 0,
      });

      if (_isPublished && mounted) {
        // If user wants to publish immediately, we need to get the ID and publish
        // For now, just save and let them publish from list
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman berhasil dibuat'),
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
            content: Text('Gagal membuat pengumuman: ${e.toString()}'),
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
        title: const Text('Tambah Pengumuman'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    const SizedBox(height: 12),

                    // Publish Switch
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text('Publikasikan Sekarang'),
                        subtitle: const Text('Pengumuman langsung ditampilkan ke user'),
                        value: _isPublished,
                        onChanged: (value) {
                          setState(() => _isPublished = value);
                        },
                        secondary: Icon(
                          Icons.publish,
                          color: _isPublished ? Colors.green : Colors.grey,
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
                    onPressed: _isLoading ? null : _saveAnnouncement,
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
                        : const Text('Simpan'),
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
