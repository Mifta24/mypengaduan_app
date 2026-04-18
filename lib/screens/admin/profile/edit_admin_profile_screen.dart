import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final User user;

  const EditAdminProfileScreen({super.key, required this.user});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _nikController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _nikController = TextEditingController(text: widget.user.nik ?? '');
    _rtController = TextEditingController(text: widget.user.rtNumber ?? '');
    _rwController = TextEditingController(text: widget.user.rwNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        nik: _nikController.text.trim(),
        rt: _rtController.text.trim(),
        rw: _rwController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field (Read Only)
            TextFormField(
              initialValue: widget.user.email,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'No. Telepon',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '08xxxxxxxxxx',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Nomor telepon hanya boleh berisi angka';
                  }
                  if (value.length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // NIK Field
            TextFormField(
              controller: _nikController,
              decoration: InputDecoration(
                labelText: 'NIK (Nomor Induk Kependudukan)',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '16 digit NIK',
              ),
              keyboardType: TextInputType.number,
              maxLength: 16,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length != 16) {
                    return 'NIK harus 16 digit';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'NIK hanya boleh berisi angka';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Field
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Alamat',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Alamat lengkap',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // RT/RW Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rtController,
                    decoration: InputDecoration(
                      labelText: 'RT',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '001',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'RT hanya boleh berisi angka';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rwController,
                    decoration: InputDecoration(
                      labelText: 'RW',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '001',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'RW hanya boleh berisi angka';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
