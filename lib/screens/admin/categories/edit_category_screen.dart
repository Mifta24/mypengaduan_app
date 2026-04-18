import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final dynamic category;
  
  const EditCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _slugController;
  
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.category['description'] ?? '');
    _slugController = TextEditingController(text: widget.category['slug'] ?? '');
    _isActive = widget.category['is_active'] == true || widget.category['is_active'] == 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _generateSlug() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final slug = name
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      _slugController.text = slug;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'is_active': _isActive,
      };
      
      // Only add optional fields if they have values
      if (_descriptionController.text.trim().isNotEmpty) {
        data['description'] = _descriptionController.text.trim();
      }

      await _adminService.updateCategory(widget.category['id'], data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil diperbarui'),
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
            content: Text('Gagal memperbarui kategori: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus kategori ini? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
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
      await _adminService.deleteCategory(widget.category['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
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
            content: Text('Gagal menghapus kategori: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsCount = widget.category['complaints_count'] ?? 0;
    final createdAt = widget.category['created_at'] != null 
        ? DateTime.tryParse(widget.category['created_at'].toString()) 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Kategori'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitForm,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Stats Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Keluhan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$complaintsCount',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        if (createdAt != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Dibuat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Kategori *',
                hintText: 'Contoh: Fasilitas Umum',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Slug Field
            TextFormField(
              controller: _slugController,
              decoration: InputDecoration(
                labelText: 'Slug (opsional)',
                hintText: 'URL-friendly identifier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateSlug,
                  tooltip: 'Generate dari nama',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'Jelaskan kategori ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Status Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Status Kategori'),
                subtitle: Text(_isActive ? 'Aktif - Muncul di form pengaduan' : 'Nonaktif - Tidak muncul'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Update Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Menyimpan...' : 'Perbarui Kategori'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteCategory,
              icon: const Icon(Icons.delete),
              label: const Text('Hapus Kategori'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),

            // Warning text
            if (complaintsCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perhatian: Kategori ini memiliki $complaintsCount keluhan. '
                        'Pastikan untuk memindahkan keluhan ke kategori lain sebelum menghapus.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
