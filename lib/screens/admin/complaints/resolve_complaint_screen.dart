import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/admin_service.dart';

class ResolveComplaintScreen extends StatefulWidget {
  final dynamic complaint;

  const ResolveComplaintScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<ResolveComplaintScreen> createState() => _ResolveComplaintScreenState();
}

class _ResolveComplaintScreenState extends State<ResolveComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _resolutionController = TextEditingController();
  final List<XFile> _selectedImages = [];
  
  bool _isLoading = false;
  final int _maxImages = 3;
  static const int _maxFileSizeBytes = 2 * 1024 * 1024;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimal $_maxImages foto')),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (images.isNotEmpty) {
        final remainingSlots = _maxImages - _selectedImages.length;

        final accepted = <XFile>[];
        int skippedLargeFiles = 0;
        for (final image in images.take(remainingSlots)) {
          final size = await File(image.path).length();
          if (size > _maxFileSizeBytes) {
            skippedLargeFiles++;
            continue;
          }
          accepted.add(image);
        }

        if (accepted.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(accepted);
          });
        }

        if (skippedLargeFiles > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$skippedLargeFiles foto dilewati karena ukuran > 2MB'),
            ),
          );
        }
        
        if (images.length > remainingSlots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hanya $_maxImages foto yang dapat dipilih')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimal $_maxImages foto')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        final size = await File(image.path).length();
        if (size > _maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ukuran foto terlalu besar. Maksimal 2MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitResolution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final photos = _selectedImages.map((img) => img.path).toList();
      debugPrint('📎 [ResolveComplaintScreen] Selected photos: ${photos.length}');
      
      await _adminService.markComplaintAsResolved(
        widget.complaint['id'],
        resolution: _resolutionController.text.trim(),
        photos: photos.isEmpty ? null : photos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keluhan berhasil diselesaikan'),
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
            content: Text('Gagal menyelesaikan keluhan: $e'),
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
        title: const Text('Selesaikan Keluhan'),
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
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Complaint Info Card
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
                          'Informasi Keluhan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.complaint['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.complaint['description'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Resolution Response Field
            Text(
              'Respon Penyelesaian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _resolutionController,
              decoration: InputDecoration(
                hintText: 'Jelaskan bagaimana keluhan ini diselesaikan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Respon penyelesaian harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Documentation Photos Section
            Text(
              'Foto Dokumentasi Penyelesaian (Opsional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            
            // Upload Area
            GestureDetector(
              onTap: _isLoading ? null : _showImageSourceDialog,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload foto dokumentasi atau drag & drop di sini',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG, JPG, JPEG hingga 2MB (Maksimal $_maxImages foto)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Images Preview
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitResolution,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Selesaikan Keluhan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}
