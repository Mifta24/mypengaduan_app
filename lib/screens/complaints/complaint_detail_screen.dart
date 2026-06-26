import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/complaint_model.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../admin/complaints/resolve_complaint_screen.dart';
import 'edit_complaint_screen.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Complaint? _complaint;
  bool _isLoading = false;
  Map<String, dynamic>? _reporter;
  List<String> _resolutionPhotoUrls = [];
  bool _isAdminSession = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _complaint = widget.complaint;
      _loadComplaint();
    } else if (widget.complaintId != null) {
      _loadComplaint();
    }
  }

  final AdminService _adminService = AdminService();
  final ComplaintService _complaintService = ComplaintService(AuthService());
  final TextEditingController _responseController = TextEditingController();
  bool _isSubmittingResponse = false;

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
        _resolutionPhotoUrls = _extractResolutionPhotoUrls(complaintData);

        if (complaintData['user'] is Map<String, dynamic>) {
          _reporter = complaintData['user'] as Map<String, dynamic>;
        } else {
          _reporter = null;
        }
      } else {
        final rawResponse = await _complaintService.getComplaintDetailRaw(id);
        final complaintData = rawResponse?['data'] ?? rawResponse;

        final complaint = complaintData is Map<String, dynamic>
            ? Complaint.fromJson(complaintData)
            : complaintData is Map
                ? Complaint.fromJson(Map<String, dynamic>.from(complaintData))
                : await _complaintService.getComplaintDetail(id);

        if (!mounted) return;

        if (complaint == null) {
          throw Exception('Detail pengaduan tidak ditemukan');
        }

        _complaint = complaint;

        if (complaintData is Map || complaintData is Map<String, dynamic>) {
          final mapped = complaintData is Map<String, dynamic>
              ? complaintData
              : Map<String, dynamic>.from(complaintData as Map);
          _resolutionPhotoUrls = _extractResolutionPhotoUrls(mapped);
          if (mapped['user'] is Map<String, dynamic>) {
            _reporter = mapped['user'] as Map<String, dynamic>;
          } else if (mapped['user'] is Map) {
            _reporter = Map<String, dynamic>.from(mapped['user'] as Map);
          } else {
            _reporter = null;
          }
        } else {
          _resolutionPhotoUrls = [];
          _reporter = null;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleResolve() async {
    if (_complaint == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResolveComplaintScreen(
          complaint: {
            'id': _complaint!.id,
            'title': _complaint!.title,
            'description': _complaint!.description,
          },
        ),
      ),
    );

    if (result == true) {
      await _loadComplaint();
    }
  }

  Future<void> _confirmResolution() async {
    if (_complaint == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
          'Apakah masalah pada pengaduan ini sudah benar-benar selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Belum'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Sudah Selesai'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final response =
          await _complaintService.confirmResolution(_complaint!.id);
      if (!mounted) return;

      if (response.success) {
        await _loadComplaint();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Terima kasih. Pengaduan telah dikonfirmasi selesai.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isEmpty
                ? 'Gagal konfirmasi penyelesaian'
                : response.message),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal konfirmasi penyelesaian: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _handleEditComplaint() async {
    if (_complaint == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditComplaintScreen(
          complaint: _complaint!,
          allowEditAnyStatus: true,
        ),
      ),
    );

    if (result == true) {
      await _loadComplaint();
    }
  }

  Future<void> _handleDeleteComplaint() async {
    if (_complaint == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengaduan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus pengaduan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.deleteComplaint(_complaint!.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaduan berhasil dihapus'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pengaduan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan tidak boleh kosong')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiResponse.message.isEmpty
                ? 'Gagal mengirim pesan'
                : apiResponse.message),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      // Reload complaint to show new thread response
      await _loadComplaint();
      _responseController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan berhasil ditambahkan'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan pesan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingResponse = false);
      }
    }
  }

  Future<void> _exportComplaintPdf() async {
    if (_complaint == null) return;

    final pdf = pw.Document();
    final generatedAt = DateTime.now();

    String statusText;
    switch (_complaint!.status) {
      case 'pending': statusText = 'Menunggu'; break;
      case 'in_progress': statusText = 'Dalam Proses'; break;
      case 'waiting_user_confirmation': statusText = 'Menunggu Konfirmasi'; break;
      case 'resolved': statusText = 'Selesai'; break;
      case 'rejected': statusText = 'Ditolak'; break;
      default: statusText = _complaint!.status;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Laporan Pengaduan',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dibuat: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(height: 24),
          pw.TableHelper.fromTextArray(
            headers: ['Field', 'Detail'],
            data: [
              ['Judul', _complaint!.title],
              ['Status', statusText],
              ['Kategori', _complaint!.category?.name ?? '-'],
              ['Lokasi', _complaint!.location],
              ['Tanggal Kejadian', DateFormat('dd/MM/yyyy').format(_complaint!.reportDate)],
              ['Tanggal Dibuat', DateFormat('dd/MM/yyyy HH:mm').format(_complaint!.createdAt)],
              ['Deskripsi', _complaint!.description],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.topLeft,
            columnWidths: {0: const pw.FixedColumnWidth(110)},
          ),
        ],
      ),
    );

    final bytes = Uint8List.fromList(await pdf.save());
    final fileName =
        'pengaduan_${_complaint!.id}_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.pdf';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/pdf',
        ),
      ],
      text: 'Laporan Pengaduan: ${_complaint!.title}',
      subject: fileName,
    );
  }

  // ── Status helper ─────────────────────────────────────────────
  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo('Menunggu', const Color(0xFFD97706), const Color(0xFFFEF3C7));
      case 'in_progress':
        return _StatusInfo('Diproses', const Color(0xFF0891B2), const Color(0xFFDBEAFE));
      case 'waiting_user_confirmation':
        return _StatusInfo('Menunggu Konfirmasi', const Color(0xFFEA580C), const Color(0xFFFFF7ED));
      case 'resolved':
        return _StatusInfo('Selesai', AppTheme.primary, const Color(0xFFD1FAE5));
      case 'rejected':
        return _StatusInfo('Ditolak', const Color(0xFFDC2626), const Color(0xFFFEE2E2));
      default:
        return _StatusInfo(status, Colors.grey, Colors.grey.shade100);
    }
  }

  // step 0=pending,1=done,2=active
  int _stepState(int step, String status) {
    final order = {'pending': 0, 'in_progress': 2, 'waiting_user_confirmation': 3, 'resolved': 4, 'rejected': -1};
    final idx = order[status] ?? 0;
    if (status == 'rejected') return step == 0 ? 1 : -1;
    if (idx >= step + 1) return 1;   // done
    if (idx == step) return 2;        // active
    return 0;                          // pending
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
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppTheme.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
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
    final si = _statusInfo(c.status);

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
                fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
        actions: [
          // Konfirmasi penyelesaian (user)
          if (!_isAdminSession && c.status == 'waiting_user_confirmation')
            TextButton.icon(
              onPressed: _confirmResolution,
              icon: const Icon(Icons.verified, size: 17, color: AppTheme.primary),
              label: Text('Konfirmasi',
                  style: GoogleFonts.nunito(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          // Selesaikan (admin)
          if (_isAdminSession &&
              c.status != 'resolved' &&
              c.status != 'rejected' &&
              c.status != 'waiting_user_confirmation')
            TextButton(
              onPressed: _handleResolve,
              child: Text('Selesaikan',
                  style: GoogleFonts.nunito(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          // PDF export (user)
          if (!_isAdminSession)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.textSecondary),
              tooltip: 'Export PDF',
              onPressed: _isLoading ? null : _exportComplaintPdf,
            ),
          // Admin menu
          if (_isAdminSession)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _handleEditComplaint();
                if (v == 'delete') _handleDeleteComplaint();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.danger))])),
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
            // ── 1. ID + Status badge ─────────────────────────
            _buildIdCard(c, si),
            const SizedBox(height: 16),

            // ── 2. Judul + Kategori + Deskripsi ─────────────
            _buildMainCard(c),
            const SizedBox(height: 16),

            // ── 3. Status tracking timeline ──────────────────
            _buildStatusTracking(c),
            const SizedBox(height: 16),

            // ── 4. Lokasi ─────────────────────────────────────
            _buildLocationCard(c),
            const SizedBox(height: 16),

            // ── 5. Foto lampiran ──────────────────────────────
            if (c.photoUrl != null || (c.attachments?.any((a) => !a.isVideo) == true)) ...[
              _buildPhotosSection(c),
              const SizedBox(height: 16),
            ],

            // ── 5b. Video lampiran ────────────────────────────
            if (c.attachments?.any((a) => a.isVideo) == true) ...[
              _buildVideosSection(c),
              const SizedBox(height: 16),
            ],

            // ── 6. Riwayat tanggapan ──────────────────────────
            if (c.responses.isNotEmpty) ...[
              _buildResponseThread(c),
              const SizedBox(height: 16),
            ],

            // ── 7. Legacy admin response ──────────────────────
            if (c.responses.isEmpty && c.adminResponse?.isNotEmpty == true) ...[
              _buildLegacyAdminResponse(c),
              const SizedBox(height: 16),
            ],

            // ── 8. Foto dokumentasi penyelesaian ─────────────
            if (_resolutionPhotoUrls.isNotEmpty) ...[
              _buildResolutionPhotosSection(),
              const SizedBox(height: 16),
            ],

            // ── 9. Info pelapor (admin) ───────────────────────
            if (_isAdminSession && _reporter != null) ...[
              _buildReporterInfoCard(),
              const SizedBox(height: 16),
            ],

            // ── 10. Form kirim pesan ──────────────────────────
            if (c.status != 'resolved' && c.status != 'rejected') ...[
              _buildResponseForm(),
              const SizedBox(height: 16),
            ],

            // ── 11. Konfirmasi penyelesaian card ──────────────
            if (!_isAdminSession && c.status == 'waiting_user_confirmation')
              _buildUserConfirmationActionCard(),
          ],
        ),
      ),
    );
  }

  // ── UI Widgets ───────────────────────────────────────────────

  Widget _buildIdCard(Complaint c, _StatusInfo si) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Keluhan #${c.id.toString().padLeft(4, '0')}',
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: si.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(si.label,
                    style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w700, color: si.color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuat pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(c.createdAt)} WIB',
            style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          if (c.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 5),
                  Text(c.category!.name,
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(c.title,
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3)),
          const SizedBox(height: 12),
          Divider(color: AppTheme.border),
          const SizedBox(height: 8),
          Text('Deskripsi',
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(c.description,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppTheme.textPrimary, height: 1.6)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 5),
              Text('Tanggal kejadian: ${DateFormat('dd MMM yyyy', 'id_ID').format(c.reportDate)}',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracking(Complaint c) {
    final steps = [
      ('Diterima',       'Keluhan Anda telah diterima.'),
      ('Diverifikasi',   'Keluhan Anda sedang diverifikasi.'),
      ('Dalam Proses',   'Keluhan Anda sedang dalam proses penanganan.'),
      ('Selesai',        'Keluhan Anda telah selesai ditangani.'),
    ];

    // map each step's approximate timestamp
    final times = [
      c.createdAt,
      c.updatedAt,
      c.updatedAt,
      c.updatedAt,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Penanganan',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final state = _stepState(i, c.status); // 0=pending,1=done,2=active,-1=rejected
            final isLast = i == steps.length - 1;
            return _buildTrackingStep(
              title: steps[i].$1,
              desc: steps[i].$2,
              time: state >= 1 ? times[i] : null,
              state: state,
              isLast: isLast,
            );
          }),
          if (c.status == 'rejected') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Pengaduan ini ditolak dan tidak dapat diproses.',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: const Color(0xFFDC2626))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String desc,
    DateTime? time,
    required int state, // 0=pending,1=done,2=active,-1=rejected
    required bool isLast,
  }) {
    Color circleColor;
    Color lineColor;
    Widget circleChild;

    if (state == 1) {
      circleColor = AppTheme.primary;
      lineColor = AppTheme.primary;
      circleChild = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
    } else if (state == 2) {
      circleColor = const Color(0xFFEA580C);
      lineColor = AppTheme.border;
      circleChild = Container(width: 8, height: 8,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
    } else {
      circleColor = Colors.grey.shade300;
      lineColor = AppTheme.border;
      circleChild = Container(width: 8, height: 8,
          decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + line column
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(child: circleChild),
              ),
              if (!isLast)
                Container(
                  width: 2, height: 44,
                  color: lineColor,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Text content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: state == 0 ? Colors.grey.shade400 : AppTheme.textPrimary)),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(time),
                      style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 3),
                Text(desc,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: state == 0 ? Colors.grey.shade400 : AppTheme.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lokasi Kejadian',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.location,
                    style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(Complaint c) {
    final urls = <String>[];
    if (c.photoUrl?.isNotEmpty == true) {
      final u = _normalizeImageUrl(c.photoUrl!);
      if (u.isNotEmpty) urls.add(u);
    }
    if (c.attachments != null) {
      urls.addAll(c.attachments!
          .where((a) => !a.isVideo)
          .map((a) => _normalizeImageUrl(a.fileUrl))
          .where((u) => u.isNotEmpty)
          .toList());
    }
    if (urls.isEmpty) return const SizedBox.shrink();

    const maxShow = 3;
    final shown = urls.take(maxShow).toList();
    final extra = urls.length - maxShow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Lampiran',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(shown.length, (i) {
              final isLast = i == shown.length - 1;
              final showOverlay = isLast && extra > 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < shown.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => _showFullImage(showOverlay ? urls[i] : shown[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: shown[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                            ),
                            if (showOverlay)
                              Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Center(
                                  child: Text('+$extra',
                                      style: GoogleFonts.nunito(
                                          fontSize: 18, fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosSection(Complaint c) {
    final videos = c.attachments!.where((a) => a.isVideo).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Video Lampiran',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final video = videos[i];
              final name = video.fileName.isNotEmpty
                  ? video.fileName
                  : video.fileUrl.split('/').last.split('?').first;
              return InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(video.fileUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_outline_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text('Ketuk untuk membuka',
                                style: GoogleFonts.nunito(
                                    fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponseThread(Complaint c) {
    final thread = [...c.responses]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggapan Petugas',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...thread.map((item) {
            final isAdmin = item.isAdmin;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppTheme.primary.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isAdmin
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isAdmin ? AppTheme.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.userName.isNotEmpty ? item.userName[0].toUpperCase() : 'A',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(isAdmin ? 'Admin' : item.userName,
                                style: GoogleFonts.nunito(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM, HH:mm', 'id_ID').format(item.createdAt),
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(item.message,
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegacyAdminResponse(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.admin_panel_settings, size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin',
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 5),
                Text(c.adminResponse!,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isAdminSession ? 'Berikan Tanggapan' : 'Beri Umpan Balik',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _responseController,
            maxLines: 4,
            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: _isAdminSession
                  ? 'Tulis tanggapan Anda untuk pengaduan ini...'
                  : 'Tulis umpan balik atau pertanyaan Anda...',
              hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingResponse ? null : _submitResponse,
              icon: _isSubmittingResponse
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSubmittingResponse ? 'Mengirim...' : 'Kirim',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserConfirmationActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, size: 20, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tindakan Anda Dibutuhkan',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pengaduan telah ditangani admin. Konfirmasi jika masalah benar-benar selesai.',
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF9A3412), height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirmResolution,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text('Konfirmasi Sekarang',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterInfoCard() {
    final name = (_reporter?['name'] ?? _reporter?['full_name'])?.toString();
    final email = _reporter?['email']?.toString();
    final phone = _reporter?['phone']?.toString();
    final nik   = (_reporter?['nik'] ?? _reporter?['national_id'])?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Informasi Pelapor',
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ),
          Divider(height: 1, color: AppTheme.border),
          _infoRow(Icons.person_outline, 'Nama', name ?? 'ID #${_complaint?.userId ?? '-'}'),
          if (email?.isNotEmpty == true) _infoRow(Icons.email_outlined, 'Email', email!),
          if (phone?.isNotEmpty == true) _infoRow(Icons.phone_outlined, 'Telepon', phone!),
          if (nik?.isNotEmpty == true) _infoRow(Icons.credit_card, 'NIK', nik!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Utility methods ──────────────────────────────────────────

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeImageUrl(String rawUrl) {
    final t = rawUrl.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = AppConfig.baseUrl.replaceAll('/api', '');
    return t.startsWith('/') ? '$base$t' : '$base/$t';
  }

  Widget _buildResolutionPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Dokumentasi Penyelesaian',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: _resolutionPhotoUrls.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _showFullImage(_resolutionPhotoUrls[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: _resolutionPhotoUrls[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractResolutionPhotoUrls(dynamic source) {
    if (source is! Map) return const [];
    final data = Map<String, dynamic>.from(source as Map);
    final keys = ['resolution_attachments', 'resolution_photos', 'resolved_photos',
        'documentation_photos', 'resolution_images', 'resolve_photos', 'photos'];
    final results = <String>[];

    for (final key in keys) {
      final value = data[key];
      if (value is! List) continue;
      for (final item in value) {
        if (!_isResolutionAttachment(item, key)) continue;
        final url = _normalizeImageUrl(_extractMediaUrl(item));
        if (url.isNotEmpty) results.add(url);
      }
      if (results.isNotEmpty) break;
    }

    final status = (data['status']?.toString() ?? '').toLowerCase();
    if (results.isEmpty && status == 'resolved') {
      final attachments = data['attachments'];
      if (attachments is List) {
        for (final item in attachments) {
          if (!_isResolutionAttachment(item, 'attachments')) continue;
          final url = _normalizeImageUrl(_extractMediaUrl(item));
          if (url.isNotEmpty) results.add(url);
        }
      }
    }
    return results.toSet().toList();
  }

  String _extractMediaUrl(dynamic item) {
    if (item == null) return '';
    if (item is String) return item.trim();
    if (item is Map) {
      final m = Map<String, dynamic>.from(item as Map);
      return (m['url'] ?? m['file_url'] ?? m['photo_url'] ??
              m['path'] ?? m['file_path'] ?? m['name'])
          ?.toString().trim() ?? '';
    }
    return '';
  }

  bool _isResolutionAttachment(dynamic item, String sourceKey) {
    if (sourceKey == 'resolution_attachments' || sourceKey == 'resolution_photos') return true;
    if (item is Map) {
      final type = Map<String, dynamic>.from(item as Map)['attachment_type']?.toString().toLowerCase() ?? '';
      if (type.isNotEmpty) return type == 'resolution';
    }
    return sourceKey != 'attachments' && sourceKey != 'complaint_attachments';
  }
}

// ─── Helper data class ────────────────────────────────────────────────────────
class _StatusInfo {
  final String label;
  final Color color;
  final Color bg;
  const _StatusInfo(this.label, this.color, this.bg);
}
