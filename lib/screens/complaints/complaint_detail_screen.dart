import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'complaint_detail_utils.dart';
import 'widgets/complaint_detail_cards.dart';
import 'widgets/complaint_status_tracker.dart';
import 'widgets/complaint_media_section.dart';
import 'widgets/complaint_thread_section.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint? complaint;
  final int? complaintId;

  const ComplaintDetailScreen({
    super.key,
    this.complaint,
    this.complaintId,
  }) : assert(complaint != null || complaintId != null,
            'Either complaint or complaintId must be provided');

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final AdminService _adminService = AdminService();
  final ComplaintService _complaintService = ComplaintService(AuthService());
  final TextEditingController _responseController = TextEditingController();

  Complaint? _complaint;
  bool _isLoading = false;
  Map<String, dynamic>? _reporter;
  List<String> _resolutionPhotoUrls = [];
  bool _isAdminSession = false;
  bool _isSubmittingResponse = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _complaint = widget.complaint;
    }
    _loadComplaint();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaint() async {
    final id = widget.complaintId ?? widget.complaint?.id;
    if (id == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authUser = context.read<AuthProvider>().user;
      _isAdminSession =
          authUser?.isAdmin == true || authUser?.role.toLowerCase() == 'admin';

      if (_isAdminSession) {
        final response = await _adminService.getComplaint(id);
        if (!mounted) return;
        final complaintData = response['data'] ?? response;
        _complaint = Complaint.fromJson(complaintData);
        _resolutionPhotoUrls = extractResolutionPhotoUrls(complaintData);
        _reporter = complaintData['user'] is Map<String, dynamic>
            ? complaintData['user'] as Map<String, dynamic>
            : null;
      } else {
        final rawResponse = await _complaintService.getComplaintDetailRaw(id);
        final complaintData = rawResponse?['data'] ?? rawResponse;
        final complaint = complaintData is Map<String, dynamic>
            ? Complaint.fromJson(complaintData)
            : complaintData is Map
                ? Complaint.fromJson(Map<String, dynamic>.from(complaintData))
                : await _complaintService.getComplaintDetail(id);

        if (!mounted) return;
        if (complaint == null) throw Exception('Detail pengaduan tidak ditemukan');

        _complaint = complaint;
        if (complaintData is Map) {
          final mapped = complaintData is Map<String, dynamic>
              ? complaintData
              : Map<String, dynamic>.from(complaintData);
          _resolutionPhotoUrls = extractResolutionPhotoUrls(mapped);
          _reporter = mapped['user'] is Map
              ? Map<String, dynamic>.from(mapped['user'] as Map)
              : null;
        } else {
          _resolutionPhotoUrls = [];
          _reporter = null;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
      context.pop();
    }
  }

  Future<void> _handleResolve() async {
    if (_complaint == null) return;
    final result = await context.push<bool>(
      AppRouter.adminComplaintsResolve,
      extra: {
        'id': _complaint!.id,
        'title': _complaint!.title,
        'description': _complaint!.description,
      },
    );
    if (result == true) await _loadComplaint();
  }

  Future<void> _confirmResolution() async {
    if (_complaint == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
            'Apakah masalah pada pengaduan ini sudah benar-benar selesai?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Belum')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Sudah Selesai')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await _complaintService.confirmResolution(_complaint!.id);
      if (!mounted) return;
      if (response.success) {
        await _loadComplaint();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Terima kasih. Pengaduan telah dikonfirmasi selesai.'),
          backgroundColor: AppTheme.success,
        ));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.message.isEmpty
              ? 'Gagal konfirmasi penyelesaian'
              : response.message),
          backgroundColor: AppTheme.danger,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal konfirmasi penyelesaian: $e'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  Future<void> _handleEditComplaint() async {
    if (_complaint == null) return;
    final result = await context.push<bool>(
      AppRouter.editComplaint,
      extra: {'complaint': _complaint!, 'allowEditAnyStatus': true},
    );
    if (result == true) await _loadComplaint();
  }

  Future<void> _handleDeleteComplaint() async {
    if (_complaint == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengaduan'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus pengaduan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.deleteComplaint(_complaint!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pengaduan berhasil dihapus'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghapus pengaduan: $e'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pesan tidak boleh kosong')));
      return;
    }
    setState(() => _isSubmittingResponse = true);
    try {
      final message = _responseController.text.trim();
      final apiResponse = _isAdminSession
          ? await _adminService.addComplaintResponse(_complaint!.id, message)
          : await _complaintService.addResponse(_complaint!.id, message);

      if (!mounted) return;
      if (!apiResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiResponse.message.isEmpty
              ? 'Gagal mengirim pesan'
              : apiResponse.message),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
      await _loadComplaint();
      if (!mounted) return;
      _responseController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pesan berhasil ditambahkan'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menambahkan pesan: $e'),
        backgroundColor: AppTheme.danger,
      ));
    } finally {
      if (mounted) setState(() => _isSubmittingResponse = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _complaint == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('Detail Keluhan',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppTheme.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
        ),
      );
    }

    if (_complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Keluhan')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final c = _complaint!;
    final si = complaintStatusInfo(c.status);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Keluhan',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
        actions: [
          if (!_isAdminSession && c.status == 'waiting_user_confirmation')
            TextButton.icon(
              onPressed: _confirmResolution,
              icon: const Icon(Icons.verified, size: 17, color: AppTheme.primary),
              label: Text('Konfirmasi',
                  style: GoogleFonts.nunito(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          if (_isAdminSession &&
              c.status != 'resolved' &&
              c.status != 'rejected' &&
              c.status != 'waiting_user_confirmation')
            TextButton(
              onPressed: _handleResolve,
              child: Text('Selesaikan',
                  style: GoogleFonts.nunito(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          if (!_isAdminSession)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppTheme.textSecondary),
              tooltip: 'Export PDF',
              onPressed: _isLoading ? null : () => exportComplaintPdf(c),
            ),
          if (_isAdminSession)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _handleEditComplaint();
                if (v == 'delete') _handleDeleteComplaint();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit')
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Text('Hapus',
                          style: TextStyle(color: AppTheme.danger))
                    ])),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadComplaint,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          children: [
            ComplaintIdCard(complaint: c, statusInfo: si),
            const SizedBox(height: 16),
            ComplaintMainCard(complaint: c),
            const SizedBox(height: 16),
            ComplaintStatusTracker(complaint: c),
            const SizedBox(height: 16),
            ComplaintLocationCard(location: c.location),
            const SizedBox(height: 16),
            if (c.photoUrl != null ||
                c.attachments?.any((a) => !a.isVideo) == true) ...[
              ComplaintPhotosSection(complaint: c),
              const SizedBox(height: 16),
            ],
            if (c.attachments?.any((a) => a.isVideo) == true) ...[
              ComplaintVideosSection(
                  videos: c.attachments!.where((a) => a.isVideo).toList()),
              const SizedBox(height: 16),
            ],
            if (c.responses.isNotEmpty) ...[
              ComplaintResponseThread(complaint: c),
              const SizedBox(height: 16),
            ],
            if (c.responses.isEmpty && c.adminResponse?.isNotEmpty == true) ...[
              ComplaintLegacyResponse(response: c.adminResponse!),
              const SizedBox(height: 16),
            ],
            if (_resolutionPhotoUrls.isNotEmpty) ...[
              ComplaintResolutionPhotos(photoUrls: _resolutionPhotoUrls),
              const SizedBox(height: 16),
            ],
            if (_isAdminSession && _reporter != null) ...[
              ComplaintReporterCard(
                  reporter: _reporter!, userId: _complaint?.userId),
              const SizedBox(height: 16),
            ],
            if (c.status != 'resolved' && c.status != 'rejected') ...[
              ComplaintResponseForm(
                controller: _responseController,
                isAdmin: _isAdminSession,
                isSubmitting: _isSubmittingResponse,
                onSubmit: _submitResponse,
              ),
              const SizedBox(height: 16),
            ],
            if (!_isAdminSession && c.status == 'waiting_user_confirmation')
              ComplaintConfirmationCard(onConfirm: _confirmResolution),
          ],
        ),
      ),
    );
  }
}
