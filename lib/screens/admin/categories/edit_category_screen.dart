import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';

class EditCategoryScreen extends StatefulWidget {
  final dynamic category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _slugController;

  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category['name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.category['description'] ?? '');
    _slugController =
        TextEditingController(text: widget.category['slug'] ?? '');
    _isActive = _toBool(widget.category['is_active']);
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

      await _adminService.updateCategory(widget.category['id'], data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kategori berhasil diperbarui'),
              backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memperbarui: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus kategori ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
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
              backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsCount = widget.category['complaints_count'] ?? 0;
    final createdAt = _parseDate(widget.category['created_at']);
    final creatorUser = widget.category['user'];
    final creatorName =
        (creatorUser is Map) ? creatorUser['name']?.toString() : null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Edit Kategori',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
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
            // ── Stats card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.category['icon']?.toString() ?? '📝',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category['name']?.toString() ?? '-',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$complaintsCount keluhan',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (createdAt != null) ...[
                        Text('Dibuat',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          DateFormat('d MMM y').format(createdAt),
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                      if (creatorName != null) ...[
                        const SizedBox(height: 4),
                        Text('Oleh',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          creatorName,
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Nama ─────────────────────────────────────────
            Text('Nama Kategori *',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: AppTheme.inputDecoration(
                hint: 'Contoh: Fasilitas Umum',
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama kategori harus diisi'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Slug ─────────────────────────────────────────
            Text('Slug (opsional)',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _slugController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: AppTheme.inputDecoration(
                hint: 'URL-friendly identifier',
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
            Text('Deskripsi (opsional)',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
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
                title: Text('Status Kategori',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                subtitle: Text(
                  _isActive
                      ? 'Aktif — muncul di form pengaduan'
                      : 'Nonaktif — tidak muncul',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppTheme.textSecondary),
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

            // ── Save button ───────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isLoading ? 'Menyimpan...' : 'Perbarui Kategori',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // ── Delete button ─────────────────────────────────
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteCategory,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Hapus Kategori',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            // ── Warning if has complaints ─────────────────────
            if (complaintsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kategori ini memiliki $complaintsCount keluhan. Pastikan memindahkan keluhan sebelum menghapus.',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppTheme.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
    }
    return false;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
