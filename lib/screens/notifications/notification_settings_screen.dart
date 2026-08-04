import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationService _service;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Settings state
  bool _allNotifications = true;
  bool _complaintCreated = true;
  bool _statusChanged = true;
  bool _adminResponse = true;
  bool _complaintResolved = true;
  bool _announcementCreated = true;
  bool _commentAdded = true;

  @override
  void initState() {
    super.initState();
    _service = NotificationService(AuthService());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getNotificationSettings();
      if (data != null && mounted) {
        final settings = data['data'] ?? data;
        setState(() {
          _complaintCreated = _parseBool(settings['complaint_created'], true);
          _statusChanged =
              _parseBool(settings['complaint_status_changed'], true);
          _adminResponse = _parseBool(settings['admin_response'], true);
          _complaintResolved = _parseBool(settings['complaint_resolved'], true);
          _announcementCreated =
              _parseBool(settings['announcement_created'], true);
          _commentAdded = _parseBool(settings['comment_added'], true);
          _updateAllToggle();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal memuat pengaturan notifikasi.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateAllToggle() {
    _allNotifications = _complaintCreated &&
        _statusChanged &&
        _adminResponse &&
        _complaintResolved &&
        _announcementCreated &&
        _commentAdded;
  }

  void _toggleAll(bool value) {
    setState(() {
      _allNotifications = value;
      _complaintCreated = value;
      _statusChanged = value;
      _adminResponse = value;
      _complaintResolved = value;
      _announcementCreated = value;
      _commentAdded = value;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await _service.updateNotificationSettings({
      'complaint_created': _complaintCreated,
      'complaint_status_changed': _statusChanged,
      'admin_response': _adminResponse,
      'complaint_resolved': _complaintResolved,
      'announcement_created': _announcementCreated,
      'comment_added': _commentAdded,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pengaturan notifikasi berhasil disimpan'
              : 'Gagal menyimpan pengaturan',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: success ? AppTheme.primary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _parseBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pengaturan Notifikasi',
          style: GoogleFonts.nunito(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 15),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: GoogleFonts.nunito(
                    fontSize: 15, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Coba Lagi',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Atur jenis notifikasi yang ingin Anda terima. Perubahan berlaku setelah disimpan.',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Master toggle
          _buildSectionLabel('Umum'),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.notifications_active_rounded,
            iconColor: AppTheme.primary,
            title: 'Semua Notifikasi',
            subtitle: 'Aktifkan atau nonaktifkan semua notifikasi sekaligus',
            value: _allNotifications,
            onChanged: _toggleAll,
          ),
          const SizedBox(height: 24),

          // Complaint notifications
          _buildSectionLabel('Pengaduan'),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.add_circle_outline_rounded,
            iconColor: Colors.blue,
            title: 'Pengaduan Dibuat',
            subtitle: 'Notifikasi saat pengaduan baru berhasil dikirim',
            value: _complaintCreated,
            onChanged: (v) => setState(() {
              _complaintCreated = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.swap_horiz_rounded,
            iconColor: Colors.orange,
            title: 'Perubahan Status',
            subtitle: 'Notifikasi saat status pengaduan berubah',
            value: _statusChanged,
            onChanged: (v) => setState(() {
              _statusChanged = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Balasan Admin',
            subtitle: 'Notifikasi saat admin memberikan respons',
            value: _adminResponse,
            onChanged: (v) => setState(() {
              _adminResponse = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.task_alt_rounded,
            iconColor: Colors.green,
            title: 'Pengaduan Diselesaikan',
            subtitle: 'Notifikasi saat pengaduan Anda ditandai selesai',
            value: _complaintResolved,
            onChanged: (v) => setState(() {
              _complaintResolved = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 24),

          // Other notifications
          _buildSectionLabel('Lainnya'),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.campaign_rounded,
            iconColor: Colors.teal,
            title: 'Pengumuman Baru',
            subtitle: 'Notifikasi saat ada pengumuman dari admin',
            value: _announcementCreated,
            onChanged: (v) => setState(() {
              _announcementCreated = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            icon: Icons.comment_rounded,
            iconColor: Colors.blueGrey,
            title: 'Komentar Ditambahkan',
            subtitle: 'Notifikasi saat ada komentar pada pengaduan Anda',
            value: _commentAdded,
            onChanged: (v) => setState(() {
              _commentAdded = v;
              _updateAllToggle();
            }),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
