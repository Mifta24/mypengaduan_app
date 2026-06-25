import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';
import 'create_complaint_screen.dart';
import 'complaint_detail_screen.dart';
import 'edit_complaint_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    debugPrint(
        '📋 [ComplaintListScreen] Screen initialized - will load after visible');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          debugPrint(
              '📋 [ComplaintListScreen] Screen visible - loading complaints now');
          _loadComplaintsIfNeeded();
        }
      });
    }
  }

  bool _hasLoadedOnce = false;

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaintsIfNeeded() async {
    final provider = context.read<ComplaintProvider>();
    // Only load if no complaints loaded yet
    if (provider.complaints.isEmpty) {
      // Load complaints and categories together
      await Future.wait([
        provider.loadComplaints(),
        provider.loadCategories(),
      ]);
    }
  }

  Future<void> _loadComplaints() async {
    final provider = context.read<ComplaintProvider>();
    // Only reload complaints, categories already loaded
    await provider.loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Pengaduan Saya',
          style: GoogleFonts.nunito(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  style: GoogleFonts.nunito(),
                  decoration: InputDecoration(
                    hintText: 'Cari pengaduan...',
                    hintStyle: GoogleFonts.nunito(
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                indicator: UnderlineTabIndicator(
                  borderSide: const BorderSide(color: AppTheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(3),
                  insets: const EdgeInsets.symmetric(horizontal: 16),
                ),
                tabs: const [
                  Tab(text: 'Semua'),
                  Tab(text: 'Menunggu'),
                  Tab(text: 'Diproses'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          final waitingComplaints = provider.complaints
              .where((c) => c.status == 'waiting_user_confirmation')
              .toList();

          if (provider.isLoading && provider.complaints.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          return Column(
            children: [
              if (waitingComplaints.isNotEmpty)
                _buildWaitingConfirmationBanner(waitingComplaints),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComplaintList(provider.complaints, 'all'),
                    _buildComplaintList(
                      provider.complaints
                          .where((c) => c.status == 'pending')
                          .toList(),
                      'pending',
                    ),
                    _buildComplaintList(
                      provider.complaints
                          .where((c) =>
                              c.status == 'in_progress' ||
                              c.status == 'waiting_user_confirmation')
                          .toList(),
                      'in_progress',
                    ),
                    _buildComplaintList(
                      provider.complaints
                          .where((c) => c.status == 'resolved')
                          .toList(),
                      'resolved',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateComplaintScreen(),
            ),
          ).then((result) {
            // Only reload if complaint was successfully created
            if (result == true) {
              _loadComplaints();
            }
          });
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Buat Pengaduan',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintList(List<Complaint> complaints, String filterStatus) {
    // Filter by search query
    final filteredComplaints = complaints.where((complaint) {
      if (_searchQuery.isEmpty) return true;
      return complaint.title.toLowerCase().contains(_searchQuery) ||
          complaint.description.toLowerCase().contains(_searchQuery) ||
          complaint.location.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada hasil pencarian'
                  : 'Belum ada pengaduan',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Buat pengaduan pertama Anda',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredComplaints.length,
        itemBuilder: (context, index) {
          final complaint = filteredComplaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildWaitingConfirmationBanner(List<Complaint> waitingComplaints) {
    final sortedWaiting = [...waitingComplaints]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final highlightedComplaint = sortedWaiting.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(0xFFEA580C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perlu Konfirmasi Anda',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${waitingComplaints.length} pengaduan menunggu konfirmasi selesai',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF9A3412),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintDetailScreen(
                    complaint: highlightedComplaint,
                  ),
                ),
              ).then((_) {
                _loadComplaints();
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              'Buka',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final statusInfo = _statusInfo(complaint.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaint)),
      ).then((r) { if (r == true) _loadComplaints(); }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status strip kiri
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusInfo.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Konten
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: ID + Status badge + Tanggal
                      Row(
                        children: [
                          Text(
                            '#${complaint.id.toString().padLeft(4, '0')}',
                            style: GoogleFonts.nunito(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          _statusBadge(statusInfo),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 11, color: Colors.grey.shade400),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('dd/MM/yy').format(complaint.reportDate),
                                style: GoogleFonts.nunito(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Judul
                      Text(
                        complaint.title,
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Deskripsi
                      Text(
                        complaint.description,
                        style: GoogleFonts.nunito(
                            fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Baris bawah: Kategori + Lokasi
                      Row(
                        children: [
                          if (complaint.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sell_outlined, size: 11, color: AppTheme.primary),
                                  const SizedBox(width: 3),
                                  Text(complaint.category!.name,
                                      style: GoogleFonts.nunito(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: AppTheme.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12, color: Colors.grey.shade400),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(complaint.location,
                                      style: GoogleFonts.nunito(
                                          fontSize: 11, color: Colors.grey.shade400),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tombol aksi
                      if (complaint.status == 'pending' ||
                          complaint.status == 'waiting_user_confirmation') ...[
                        const SizedBox(height: 10),
                        Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (complaint.status == 'pending')
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditComplaintScreen(complaint: complaint),
                                  ),
                                ).then((r) { if (r == true) _loadComplaints(); }),
                                icon: const Icon(Icons.edit_rounded, size: 15),
                                label: Text('Edit',
                                    style: GoogleFonts.nunito(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact),
                              ),
                            if (complaint.status == 'waiting_user_confirmation')
                              FilledButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ComplaintDetailScreen(complaint: complaint),
                                  ),
                                ).then((r) { if (r == true) _loadComplaints(); }),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                                label: Text('Konfirmasi Selesai',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12, fontWeight: FontWeight.w700)),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFEA580C),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, Color bg, String label, IconData icon}) _statusInfo(String s) {
    switch (s) {
      case 'pending':
        return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7),
            label: 'Menunggu', icon: Icons.schedule_rounded);
      case 'in_progress':
        return (color: const Color(0xFF0891B2), bg: const Color(0xFFDBEAFE),
            label: 'Diproses', icon: Icons.sync_rounded);
      case 'waiting_user_confirmation':
        return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED),
            label: 'Konfirmasi', icon: Icons.hourglass_top_rounded);
      case 'resolved':
        return (color: AppTheme.primary, bg: const Color(0xFFD1FAE5),
            label: 'Selesai', icon: Icons.check_circle_rounded);
      case 'rejected':
        return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2),
            label: 'Ditolak', icon: Icons.cancel_rounded);
      default:
        return (color: Colors.grey, bg: Colors.grey.shade100,
            label: s, icon: Icons.info_rounded);
    }
  }

  Widget _statusBadge(({Color color, Color bg, String label, IconData icon}) info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: info.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 11, color: info.color),
          const SizedBox(width: 3),
          Text(info.label,
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w700, color: info.color)),
        ],
      ),
    );
  }
}
