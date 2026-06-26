import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _slugController = TextEditingController();

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
      _slugController.text = name
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'is_active': _isActive,
      };
      final desc = _descriptionController.text.trim();
      if (desc.isNotEmpty) data['description'] = desc;
      final slug = _slugController.text.trim();
      if (slug.isNotEmpty) data['slug'] = slug;

      await _adminService.createCategory(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil ditambahkan'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Tambah Kategori', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _submit,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Info banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kategori digunakan untuk mengelompokkan keluhan berdasarkan jenisnya.',
                      style: GoogleFonts.nunito(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Nama ─────────────────────────────────────────
            Text('Nama Kategori *', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: AppTheme.inputDecoration(
                hint: 'Contoh: Fasilitas Umum',
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kategori harus diisi' : null,
              onChanged: (_) {
                if (_slugController.text.isEmpty) _generateSlug();
              },
            ),
            const SizedBox(height: 16),

            // ── Slug ─────────────────────────────────────────
            Text('Slug (opsional)', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _slugController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: AppTheme.inputDecoration(
                hint: 'Otomatis dari nama',
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: _generateSlug,
                  tooltip: 'Generate dari nama',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Deskripsi ─────────────────────────────────────
            Text('Deskripsi (opsional)', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: AppTheme.inputDecoration(
                hint: 'Jelaskan kategori ini...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined, size: 20),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // ── Status toggle ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _isActive
                    ? AppTheme.primary.withValues(alpha: 0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isActive
                      ? AppTheme.primary.withValues(alpha: 0.3)
                      : AppTheme.border,
                ),
              ),
              child: SwitchListTile(
                title: Text('Status Kategori', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                subtitle: Text(
                  _isActive ? 'Aktif — muncul di form pengaduan' : 'Nonaktif — tidak muncul',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeTrackColor: AppTheme.primary,
                secondary: Icon(
                  _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _isActive ? AppTheme.primary : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit button ─────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isLoading ? 'Menyimpan...' : 'Simpan Kategori',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
