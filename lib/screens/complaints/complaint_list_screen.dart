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
    print(
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
          print(
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
          style: GoogleFonts.poppins(
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
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Cari pengaduan...',
                    hintStyle: GoogleFonts.inter(
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
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
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
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${waitingComplaints.length} pengaduan menunggu konfirmasi selesai',
                  style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComplaintDetailScreen(complaint: complaint),
              ),
            ).then((result) {
              // Only reload if there were changes (e.g., status updated)
              if (result == true) {
                _loadComplaints();
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(complaint.status),
                    Text(
                      DateFormat('dd/MM/yyyy').format(complaint.reportDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  complaint.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  complaint.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Footer: Category & Location
                Row(
                  children: [
                    if (complaint.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              complaint.category!.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              complaint.location,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Edit button (only when status is pending)
                if (complaint.status == 'pending')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditComplaintScreen(
                              complaint: complaint,
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadComplaints();
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      label: Text(
                        'Edit Pengaduan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        text = 'Menunggu';
        icon = Icons.schedule;
        break;
      case 'in_progress':
        backgroundColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        text = 'Diproses';
        icon = Icons.sync;
        break;
      case 'waiting_user_confirmation':
        backgroundColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        text = 'Menunggu Konfirmasi';
        icon = Icons.hourglass_top;
        break;
      case 'resolved':
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        text = 'Selesai';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        text = 'Ditolak';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        text = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
