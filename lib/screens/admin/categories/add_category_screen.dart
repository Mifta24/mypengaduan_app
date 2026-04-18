import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;

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
      final description = _descriptionController.text.trim();
      if (description.isNotEmpty) {
        data['description'] = description;
      }

      print('DEBUG: Sending category data: $data');
      final response = await _adminService.createCategory(data);
      print('DEBUG: Response: $response');

        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      print('DEBUG: Exception caught: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');
      
      setState(() => _isLoading = false);
      
      String errorMessage = 'Gagal menambahkan kategori';
      
      // Extract more detailed error message
      final errorStr = e.toString();
      if (errorStr.contains('DioException')) {
        if (errorStr.contains('400')) {
          errorMessage = 'Data tidak valid. Periksa input Anda.';
        } else if (errorStr.contains('422')) {
          errorMessage = 'Validasi gagal. Nama atau slug mungkin sudah digunakan.';
        } else if (errorStr.contains('500')) {
          errorMessage = 'Server error. Coba lagi nanti.';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\nDetail: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kategori'),
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
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kategori digunakan untuk mengelompokkan keluhan berdasarkan jenisnya.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
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
              onChanged: (value) {
                if (_slugController.text.isEmpty) {
                  _generateSlug();
                }
              },
            ),
            const SizedBox(height: 16),

            // Slug Field
            TextFormField(
              controller: _slugController,
              decoration: InputDecoration(
                labelText: 'Slug (opsional)',
                hintText: 'Akan digenerate otomatis dari nama',
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
                subtitle: Text(_isActive ? 'Aktif' : 'Nonaktif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Help text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Kategori yang aktif akan muncul di form pengaduan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
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
              label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Kategori'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
