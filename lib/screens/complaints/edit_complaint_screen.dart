import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_form_widgets.dart';

class EditComplaintScreen extends StatefulWidget {
  final Complaint complaint;
  final bool allowEditAnyStatus;

  const EditComplaintScreen({
    super.key,
    required this.complaint,
    this.allowEditAnyStatus = false,
  });

  @override
  State<EditComplaintScreen> createState() => _EditComplaintScreenState();
}

class _EditComplaintScreenState extends State<EditComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  String _visibility = 'public';
  final List<File> _newImages = [];
  final List<File> _newVideos = [];
  final List<String> _existingPhotoUrls = [];
  final List<String> _existingVideoUrls = [];
  bool _isLoading = false;
  int _descLength = 0;

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.complaint.title;
    _descriptionController.text = widget.complaint.description;
    _locationController.text = widget.complaint.location;
    _selectedDate = widget.complaint.reportDate;
    _selectedCategoryId =
        widget.complaint.categoryId ?? widget.complaint.category?.id;
    _visibility = widget.complaint.visibility;
    _descLength = widget.complaint.description.length;

    _descriptionController.addListener(
        () => setState(() => _descLength = _descriptionController.text.length));

    // Kumpulkan URL foto & video existing — pisahkan agar video tidak masuk CachedNetworkImage
    final c = widget.complaint;
    if (c.photoUrl?.isNotEmpty == true) {
      _existingPhotoUrls.add(_normalizeUrl(c.photoUrl!));
    }
    if (c.attachments != null) {
      for (final a in c.attachments!) {
        final url = _normalizeUrl(a.fileUrl);
        if (url.isEmpty) continue;
        if (a.isVideo) {
          if (!_existingVideoUrls.contains(url)) _existingVideoUrls.add(url);
        } else {
          if (!_existingPhotoUrls.contains(url)) _existingPhotoUrls.add(url);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ComplaintProvider>();
      setState(() => _categories = provider.categories);
      if (_categories.isEmpty) {
        provider.loadCategories().then((_) {
          if (!mounted) return;
          setState(() => _categories = provider.categories);
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_newImages.length >= 5) {
      _showSnack('Maksimal 5 foto', isError: true);
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _newImages.add(File(picked.path)));
    } catch (e) {
      _showSnack('Gagal mengambil gambar: $e', isError: true);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceSheet(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
      ),
    );
  }

  Future<void> _pickVideo() async {
    if (_newVideos.length >= 3) {
      _showSnack('Maksimal 3 video', isError: true);
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.first.path;
      if (path == null) return;

      final file = File(path);
      final size = await file.length();
      if (size > 100 * 1024 * 1024) {
        _showSnack('Video terlalu besar (maks. 100MB)', isError: true);
        return;
      }
      setState(() => _newVideos.add(file));
    } catch (e) {
      _showSnack('Gagal memilih video: $e', isError: true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppTheme.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnack('Pilih kategori terlebih dahulu', isError: true);
      return;
    }
    if (_selectedDate == null) {
      _showSnack('Pilih tanggal kejadian terlebih dahulu', isError: true);
      return;
    }
    if (!widget.allowEditAnyStatus && widget.complaint.status != 'pending') {
      _showSnack('Pengaduan tidak dapat diedit karena sudah diproses',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await context.read<ComplaintProvider>().updateComplaint(
            id: widget.complaint.id,
            categoryId: _selectedCategoryId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            reportDate: _selectedDate!,
            visibility: _visibility,
            attachments: _newImages.map((f) => f.path).toList(),
            videos: _newVideos.map((f) => f.path).toList(),
          );
      if (!mounted) return;
      if (success) {
        _showSnack('Pengaduan berhasil diperbarui');
        Navigator.pop(context, true);
      } else {
        final err = context.read<ComplaintProvider>().errorMessage;
        _showSnack(err ?? 'Gagal memperbarui pengaduan', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal memperbarui pengaduan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _normalizeUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base =
        AppConfig.baseUrl.replaceAll('/api', '').replaceAll('/api/', '');
    return t.startsWith('/') ? '$base$t' : '$base/$t';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
      backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Keluhan',
            style: GoogleFonts.nunito(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildGroupLabel('Informasi Keluhan'),
                  const SizedBox(height: 16),

                  // Kategori
                  _buildFieldLabel('Kategori Keluhan'),
                  const SizedBox(height: 6),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Lokasi
                  _buildFieldLabel('Lokasi Kejadian'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _locationController,
                    hint: 'Masukkan lokasi kejadian',
                    suffix: const Icon(Icons.location_on_outlined,
                        color: AppTheme.textSecondary, size: 20),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lokasi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Judul
                  _buildFieldLabel('Judul Keluhan'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Tuliskan ringkasan keluhan Anda',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      if (v.trim().length < 10)
                        return 'Judul minimal 10 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  _buildFieldLabel('Deskripsi Keluhan'),
                  const SizedBox(height: 6),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),

                  // Tanggal
                  _buildFieldLabel('Tanggal Kejadian'),
                  const SizedBox(height: 6),
                  _buildDateField(),
                  const SizedBox(height: 20),

                  _buildFieldLabel('Visibilitas Pengaduan'),
                  const SizedBox(height: 4),
                  Text(
                    'Perubahan hanya dapat dilakukan selama pengaduan belum diproses.',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ComplaintVisibilitySelector(
                    value: _visibility,
                    onChanged: (value) => setState(() => _visibility = value),
                  ),
                  const SizedBox(height: 20),

                  // Foto
                  _buildFieldLabel('Unggah Foto Tambahan'),
                  Text('Lampirkan foto baru untuk memperbarui keluhan Anda.',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  _buildPhotoSection(),
                  const SizedBox(height: 20),

                  // Video
                  _buildFieldLabel('Unggah Video Baru'),
                  Text(
                      'Lampirkan video pendukung (maks. 3 video, 100MB per file).',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  _buildVideoSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────

  Widget _buildGroupLabel(String label) => Text(label,
      style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary));

  Widget _buildFieldLabel(String label) => Text(label,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));

  InputDecoration _inputDecoration({String hint = '', Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? suffix,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
        decoration: _inputDecoration(hint: hint, suffix: suffix),
        validator: validator,
      );

  Widget _buildCategoryDropdown() => DropdownButtonFormField<int>(
        initialValue: _selectedCategoryId,
        style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
        decoration: _inputDecoration(
            hint: _categories.isEmpty
                ? 'Tidak ada kategori'
                : 'Pilih kategori keluhan'),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondary),
        items: _categories
            .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, style: GoogleFonts.nunito(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => _selectedCategoryId = v),
        validator: (v) => v == null ? 'Pilih kategori' : null,
      );

  Widget _buildDescriptionField() => Stack(
        children: [
          TextFormField(
            controller: _descriptionController,
            maxLines: 6,
            maxLength: 500,
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            style:
                GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
            decoration: _inputDecoration(
                    hint: 'Jelaskan keluhan Anda secara detail')
                .copyWith(
                    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 32)),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Deskripsi tidak boleh kosong';
              if (v.trim().length < 20) return 'Deskripsi minimal 20 karakter';
              return null;
            },
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: Text('$_descLength/500',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: Colors.grey.shade400)),
          ),
        ],
      );

  Widget _buildDateField() => GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? 'Pilih tanggal kejadian'
                      : DateFormat('dd MMMM yyyy', 'id_ID')
                          .format(_selectedDate!),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _selectedDate == null
                        ? Colors.grey.shade400
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      );

  Widget _buildPhotoSection() => Column(
        children: [
          // ── Foto existing (dari server) ─────────────────────
          if (_existingPhotoUrls.isNotEmpty) ...[
            Text('Foto Saat Ini',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _existingPhotoUrls.length,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _existingPhotoUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child:
                        Icon(Icons.broken_image, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Tambah Foto Baru',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
          ],

          // ── Foto baru (file lokal) ──────────────────────────
          if (_newImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _newImages.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_newImages[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _newImages.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_newImages.length < 5)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: CustomPaint(
                painter: DashedBorderPainter(color: AppTheme.border),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Seret & lepas foto di sini',
                          style: GoogleFonts.nunito(
                              fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('atau',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      Text('Pilih Foto dari Galeri',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text('Maks. 5 foto (5MB per foto)',
              style: GoogleFonts.nunito(
                  fontSize: 11, color: Colors.grey.shade400)),
        ],
      );

  Widget _buildVideoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing videos from server
          if (_existingVideoUrls.isNotEmpty) ...[
            Text('Video Saat Ini',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _existingVideoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final name =
                    _existingVideoUrls[i].split('/').last.split('?').first;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.videocam_rounded,
                            color: Colors.grey.shade600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text('Tambah Video Baru',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
          ],
          if (_newVideos.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _newVideos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final name = _newVideos[i].path.split('/').last;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.videocam_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: AppTheme.textPrimary)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _newVideos.removeAt(i)),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          if (_newVideos.length < 3)
            GestureDetector(
              onTap: _pickVideo,
              child: CustomPaint(
                painter: DashedBorderPainter(color: AppTheme.border),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_outlined,
                          size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Pilih Video dari Galeri',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary)),
                      const SizedBox(height: 4),
                      Text('MP4, MOV, WEBM, AVI — maks. 100MB',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text('${_newVideos.length}/3 video dipilih',
              style: GoogleFonts.nunito(
                  fontSize: 11, color: Colors.grey.shade400)),
        ],
      );

  Widget _buildBottomButton() => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Simpan Perubahan',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
