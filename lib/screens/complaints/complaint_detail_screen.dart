import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../admin/complaints/resolve_complaint_screen.dart';
import 'edit_complaint_screen.dart';

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
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isEmpty
                ? 'Gagal konfirmasi penyelesaian'
                : response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal konfirmasi penyelesaian: $e'),
          backgroundColor: Colors.red,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pengaduan: $e'),
          backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingResponse = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _complaint == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          title: const Text('Detail Pengaduan'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isAdminSession &&
                  _complaint!.status != 'resolved' &&
                  _complaint!.status != 'rejected' &&
                  _complaint!.status != 'waiting_user_confirmation')
                TextButton.icon(
                  onPressed: _handleResolve,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 18),
                  label: Text(
                    'Selesaikan',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!_isAdminSession &&
                  _complaint!.status == 'waiting_user_confirmation')
                TextButton.icon(
                  onPressed: _confirmResolution,
                  icon:
                      const Icon(Icons.verified, color: Colors.white, size: 18),
                  label: Text(
                    'Konfirmasi',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_isAdminSession)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _handleEditComplaint();
                    } else if (value == 'delete') {
                      _handleDeleteComplaint();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Pengaduan'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus Pengaduan'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Detail Pengaduan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  if (!_isAdminSession &&
                      _complaint!.status == 'waiting_user_confirmation') ...[
                    _buildUserConfirmationActionCard(),
                    const SizedBox(height: 16),
                  ],

                  // Ringkasan Status
                  _buildStatusSummaryCard(),
                  const SizedBox(height: 16),

                  // Informasi Pelapor
                  _buildReporterInfoCard(),
                  const SizedBox(height: 16),

                  // Main Info Card
                  _buildMainInfoCard(),
                  const SizedBox(height: 16),

                  // Images & attachments (if available)
                  if (_complaint!.photoUrl != null ||
                      (_complaint!.attachments != null &&
                          _complaint!.attachments!.isNotEmpty)) ...[
                    _buildImagesSection(),
                    const SizedBox(height: 16),
                  ],

                  // Location Card
                  _buildLocationCard(),
                  const SizedBox(height: 16),

                  // Response thread
                  if (_complaint!.responses.isNotEmpty) ...[
                    _buildResponsesThreadCard(),
                    const SizedBox(height: 16),
                  ],

                  // Legacy admin response fallback (for old payload)
                  if (_complaint!.responses.isEmpty &&
                      _complaint!.adminResponse != null &&
                      _complaint!.adminResponse!.isNotEmpty) ...[
                    _buildAdminResponseCard(),
                    const SizedBox(height: 16),
                  ],

                  // Response input disabled only when complaint already final
                  if (_complaint!.status != 'resolved' &&
                      _complaint!.status != 'rejected') ...[
                    _buildAdminResponseForm(),
                    const SizedBox(height: 16),
                  ],

                  if (_resolutionPhotoUrls.isNotEmpty) ...[
                    _buildResolutionPhotosSection(),
                    const SizedBox(height: 16),
                  ],

                  // Timeline Card
                  _buildTimelineCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;
    String description;

    switch (_complaint!.status) {
      case 'pending':
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        text = 'Menunggu';
        icon = Icons.schedule;
        description = 'Pengaduan Anda sedang menunggu untuk diproses';
        break;
      case 'in_progress':
        backgroundColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        text = 'Diproses';
        icon = Icons.sync;
        description = 'Pengaduan Anda sedang dalam proses penanganan';
        break;
      case 'waiting_user_confirmation':
        backgroundColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        text = 'Menunggu Konfirmasi';
        icon = Icons.hourglass_top;
        description =
            'Admin sudah menyelesaikan pengaduan. Silakan konfirmasi.';
        break;
      case 'resolved':
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        text = 'Selesai';
        icon = Icons.check_circle;
        description = 'Pengaduan Anda telah selesai ditangani';
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        text = 'Ditolak';
        icon = Icons.cancel;
        description = 'Pengaduan Anda tidak dapat diproses';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        text = _complaint!.status;
        icon = Icons.info;
        description = 'Status pengaduan';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: textColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user,
                size: 20,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tindakan Anda Dibutuhkan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jika masalah sudah selesai, silakan konfirmasi agar status menjadi selesai final.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9A3412),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirmResolution,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                'Konfirmasi Sekarang',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
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

  Widget _buildStatusSummaryCard() {
    if (_complaint == null) return const SizedBox.shrink();

    final statusText = _complaint!.statusText;

    String priorityText;
    switch ((_complaint!.priority ?? '').toLowerCase()) {
      case 'low':
        priorityText = 'Rendah';
        break;
      case 'medium':
        priorityText = 'Sedang';
        break;
      case 'high':
        priorityText = 'Tinggi';
        break;
      default:
        priorityText = _complaint!.priority?.isNotEmpty == true
            ? _complaint!.priority!
            : '-';
    }

    final createdAt = _complaint!.createdAt;
    final bool isResolved = _complaint!.status == 'resolved';
    final DateTime endTime =
        isResolved ? _complaint!.updatedAt : DateTime.now();
    final duration = endTime.difference(createdAt);

    String formatDuration(Duration d) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      final minutes = d.inMinutes % 60;

      if (days > 0) {
        return '${days} hari ${hours} jam ${minutes} menit';
      }
      if (hours > 0) {
        return '${hours} jam ${minutes} menit';
      }
      return '${minutes} menit';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Status Saat Ini', statusText),
          const SizedBox(height: 8),
          _buildSummaryRow('Prioritas', priorityText),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Tanggal Dibuat',
            DateFormat('dd MMM yyyy').format(createdAt),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Lama Penanganan', formatDuration(duration)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          if (_complaint!.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _complaint!.category!.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Title
          Text(
            _complaint!.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Deskripsi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _complaint!.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterInfoCard() {
    if (_complaint == null && _reporter == null) {
      return const SizedBox.shrink();
    }

    final reporterName = (_reporter != null
            ? (_reporter!['name'] ?? _reporter!['full_name'])
            : null)
        ?.toString();
    final reporterEmail = _reporter?['email']?.toString();
    final reporterPhone = _reporter?['phone']?.toString();
    final reporterNik =
        (_reporter?['nik'] ?? _reporter?['national_id'])?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pelapor',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Nama Pelapor',
            reporterName ?? 'ID Pengguna #${_complaint?.userId ?? '-'}',
          ),
          if (reporterEmail != null && reporterEmail.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Email', reporterEmail),
          ],
          if (reporterPhone != null && reporterPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('No. Telepon', reporterPhone),
          ],
          if (reporterNik != null && reporterNik.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('NIK', reporterNik),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    // Collect all image URLs: main photo + attachments
    final List<String> imageUrls = [];

    if (_complaint!.photoUrl != null && _complaint!.photoUrl!.isNotEmpty) {
      final normalizedMain = _normalizeImageUrl(_complaint!.photoUrl!);
      if (normalizedMain.isNotEmpty) {
        imageUrls.add(normalizedMain);
      }
    }

    if (_complaint!.attachments != null &&
        _complaint!.attachments!.isNotEmpty) {
      imageUrls.addAll(
        _complaint!.attachments!
            .map((attachment) => attachment.fileUrl)
            .map(_normalizeImageUrl)
            .where((url) => url.isNotEmpty),
      );
    }

    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final String mainImageUrl = imageUrls.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Foto Pengaduan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: GestureDetector(
              onTap: () {
                // Show full screen image
                _showFullImage(mainImageUrl);
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: mainImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image,
                            size: 48, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 8),
                        const Text('Gagal memuat gambar'),
                        const SizedBox(height: 8),
                        Text(
                          'URL: $mainImageUrl',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (imageUrls.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return GestureDetector(
                    onTap: () => _showFullImage(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(
                            color: const Color(0xFFF3F4F6),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(Icons.broken_image,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
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

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Kejadian',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _complaint!.location,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminResponseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tanggapan Admin',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _complaint!.adminResponse!,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF374151),
                height: 1.6,
              ),
            ),
          ),
          if (_complaint!.estimatedResolution != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimasi selesai: ${DateFormat('dd/MM/yyyy').format(_complaint!.estimatedResolution!)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionPhotosSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Foto Dokumentasi Penyelesaian',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _resolutionPhotoUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = _resolutionPhotoUrls[index];
                return GestureDetector(
                  onTap: () => _showFullImage(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, _, __) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image,
                            color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractResolutionPhotoUrls(dynamic source) {
    if (source is! Map) return const [];

    final data = Map<String, dynamic>.from(source as Map);
    final candidateKeys = <String>[
      'resolution_attachments',
      'resolution_photos',
      'resolved_photos',
      'documentation_photos',
      'resolution_images',
      'resolve_photos',
      'photos',
    ];

    final results = <String>[];

    for (final key in candidateKeys) {
      final value = data[key];
      if (value is! List) continue;

      for (final item in value) {
        if (!_isResolutionAttachment(item, key)) continue;
        final rawUrl = _extractMediaUrl(item);
        if (rawUrl.isEmpty) continue;
        final normalizedUrl = _normalizeImageUrl(rawUrl);
        if (normalizedUrl.isEmpty) continue;
        results.add(normalizedUrl);
      }

      if (results.isNotEmpty) {
        break;
      }
    }

    // Backend can store completion documentation inside generic attachments.
    final status = (data['status']?.toString() ?? '').toLowerCase();
    if (results.isEmpty && status == 'resolved') {
      final attachments = data['attachments'];
      if (attachments is List) {
        for (final item in attachments) {
          if (!_isResolutionAttachment(item, 'attachments')) continue;
          final rawUrl = _extractMediaUrl(item);
          if (rawUrl.isEmpty) continue;
          final normalizedUrl = _normalizeImageUrl(rawUrl);
          if (normalizedUrl.isEmpty) continue;
          results.add(normalizedUrl);
        }
      }
    }

    return results.toSet().toList();
  }

  String _extractMediaUrl(dynamic item) {
    if (item == null) return '';
    if (item is String) return item.trim();
    if (item is Map) {
      final map = Map<String, dynamic>.from(item as Map);
      final url = map['url'] ??
          map['file_url'] ??
          map['photo_url'] ??
          map['path'] ??
          map['file_path'] ??
          map['name'];
      return url?.toString().trim() ?? '';
    }
    return '';
  }

  String _normalizeImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = AppConfig.baseUrl.replaceAll('/api', '');
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  bool _isResolutionAttachment(dynamic item, String sourceKey) {
    // Dedicated resolution fields should be accepted as-is.
    if (sourceKey == 'resolution_attachments' ||
        sourceKey == 'resolution_photos') {
      return true;
    }

    if (item is Map) {
      final map = Map<String, dynamic>.from(item as Map);
      final type = map['attachment_type']?.toString().toLowerCase() ?? '';
      if (type.isNotEmpty) {
        return type == 'resolution';
      }
    }

    // For legacy arrays without type metadata, keep previous permissive behavior.
    return sourceKey != 'attachments' && sourceKey != 'complaint_attachments';
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            icon: Icons.flag,
            title: 'Tanggal Kejadian',
            date: _complaint!.reportDate,
            isFirst: true,
          ),
          _buildTimelineItem(
            icon: Icons.send,
            title: 'Pengaduan Dibuat',
            date: _complaint!.createdAt,
          ),
          _buildTimelineItem(
            icon: Icons.update,
            title: 'Terakhir Diperbarui',
            date: _complaint!.updatedAt,
            isLast: _complaint!.status != 'resolved' &&
                _complaint!.status != 'waiting_user_confirmation',
          ),
          if (_complaint!.status == 'waiting_user_confirmation')
            _buildTimelineItem(
              icon: Icons.hourglass_top,
              title: 'Menunggu Konfirmasi Pengguna',
              date: _complaint!.updatedAt,
              isLast: true,
              color: const Color(0xFFEA580C),
            ),
          if (_complaint!.status == 'resolved')
            _buildTimelineItem(
              icon: Icons.check_circle,
              title: 'Selesai Ditangani',
              date: _complaint!.updatedAt,
              isLast: true,
              color: const Color(0xFF059669),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required DateTime date,
    bool isFirst = false,
    bool isLast = false,
    Color? color,
  }) {
    final displayColor = color ?? const Color(0xFF6366F1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: displayColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy • HH:mm').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminResponseForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.reply,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isAdminSession ? 'Berikan Tanggapan' : 'Balas Tanggapan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _responseController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _isAdminSession
                  ? 'Tulis tanggapan Anda untuk pengaduan ini...'
                  : 'Tulis balasan Anda terkait pengaduan ini...',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingResponse ? null : _submitResponse,
              icon: _isSubmittingResponse
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmittingResponse ? 'Mengirim...' : 'Kirim Pesan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesThreadCard() {
    final thread = [..._complaint!.responses]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Tanggapan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...thread.map((item) {
            final bg = item.isAdmin
                ? const Color(0xFFEEF2FF)
                : const Color(0xFFF3F4F6);
            final label = item.isAdmin ? 'Admin' : item.userName;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy • HH:mm').format(item.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                      height: 1.5,
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
}
