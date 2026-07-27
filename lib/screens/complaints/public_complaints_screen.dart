import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/complaint_model.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../theme/app_theme.dart';
import 'complaint_detail_utils.dart';
import 'widgets/complaint_detail_cards.dart';
import 'widgets/complaint_media_section.dart';
import 'widgets/complaint_status_tracker.dart';
import 'widgets/complaint_thread_section.dart';
import 'widgets/user_complaint_list_card.dart';

class PublicComplaintsScreen extends StatefulWidget {
  const PublicComplaintsScreen({super.key});

  @override
  State<PublicComplaintsScreen> createState() => _PublicComplaintsScreenState();
}

class _PublicComplaintsScreenState extends State<PublicComplaintsScreen> {
  late final ComplaintService _service;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<Complaint> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ComplaintService(AuthService());
    _scrollController.addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
    });

    try {
      final response = await _service.getPublicComplaints(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _hasMore = response.meta.hasMorePages;
        _page = response.meta.currentPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _service.getPublicComplaints(
        page: _page + 1,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(response.data);
        _hasMore = response.meta.hasMorePages;
        _page = response.meta.currentPage;
      });
    } catch (_) {
      // Keep the already loaded feed visible if only pagination fails.
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        foregroundColor: Colors.white,
        title: Text(
          'Pengaduan Publik',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transparansi untuk warga',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pantau pengaduan dan progres penanganannya. Identitas pelapor tidak ditampilkan.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau isi pengaduan',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Pengaduan publik belum dapat dimuat',
        message: _error!,
        buttonLabel: 'Coba Lagi',
        onPressed: _load,
      );
    }

    if (_items.isEmpty) {
      return _MessageState(
        icon: Icons.forum_outlined,
        title: 'Belum ada pengaduan publik',
        message: _searchController.text.isEmpty
            ? 'Pengaduan yang dipilih sebagai publik akan tampil di sini.'
            : 'Tidak ada hasil untuk pencarian tersebut.',
        buttonLabel: _searchController.text.isEmpty ? null : 'Hapus Pencarian',
        onPressed: _searchController.text.isEmpty
            ? null
            : () {
                _searchController.clear();
                _load();
              },
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            );
          }
          final complaint = _items[index];
          return UserComplaintListCard(
            complaint: complaint,
            onTap: () => context.push(
              AppRouter.publicComplaintDetailPath(complaint.id),
            ),
          );
        },
      ),
    );
  }
}

class PublicComplaintDetailScreen extends StatefulWidget {
  final int complaintId;

  const PublicComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<PublicComplaintDetailScreen> createState() =>
      _PublicComplaintDetailScreenState();
}

class _PublicComplaintDetailScreenState
    extends State<PublicComplaintDetailScreen> {
  late final ComplaintService _service;
  Complaint? _complaint;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ComplaintService(AuthService());
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final complaint =
          await _service.getPublicComplaintDetail(widget.complaintId);
      if (!mounted) return;
      setState(() => _complaint = complaint);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _complaint = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        foregroundColor: Colors.white,
        title: Text(
          'Detail Pengaduan Publik',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: complaint == null
          ? (_error == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _MessageState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Pengaduan tidak tersedia',
                  message: _error!,
                  buttonLabel: 'Coba Lagi',
                  onPressed: _load,
                ))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  ComplaintIdCard(
                    complaint: complaint,
                    statusInfo: complaintStatusInfo(complaint.status),
                  ),
                  const SizedBox(height: 16),
                  ComplaintMainCard(complaint: complaint),
                  const SizedBox(height: 16),
                  ComplaintStatusTracker(complaint: complaint),
                  const SizedBox(height: 16),
                  ComplaintLocationCard(location: complaint.location),
                  if (complaint.photoUrl != null ||
                      complaint.attachments?.any((a) => !a.isVideo) ==
                          true) ...[
                    const SizedBox(height: 16),
                    ComplaintPhotosSection(complaint: complaint),
                  ],
                  if (complaint.attachments?.any((a) => a.isVideo) == true) ...[
                    const SizedBox(height: 16),
                    ComplaintVideosSection(
                      videos: complaint.attachments!
                          .where((a) => a.isVideo)
                          .toList(),
                    ),
                  ],
                  if (complaint.responses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ComplaintResponseThread(complaint: complaint),
                  ],
                  if (complaint.responses.isEmpty &&
                      complaint.adminResponse?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    ComplaintLegacyResponse(response: complaint.adminResponse!),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.privacy_tip_outlined,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Identitas dan data pribadi pelapor dirahasiakan.',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              height: 1.4,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: AppTheme.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onPressed,
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
