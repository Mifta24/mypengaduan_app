import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';
import '../../routes/app_router.dart';
import 'widgets/user_complaint_list_card.dart';

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
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 3),
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
                UserComplaintWaitingBanner(
                  waitingComplaints: waitingComplaints,
                  onOpen: (c) => context
                      .push('/complaint/${c.id}')
                      .then((_) => _loadComplaints()),
                ),
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
          return UserComplaintListCard(
            complaint: complaint,
            onTap: () => context.push('/complaint/${complaint.id}').then((r) {
              if (r == true) _loadComplaints();
            }),
            onEdit: complaint.status == 'pending'
                ? () => context.push(AppRouter.editComplaint, extra: {
                      'complaint': complaint,
                      'allowEditAnyStatus': false,
                    }).then((r) {
                      if (r == true) _loadComplaints();
                    })
                : null,
            onConfirm: complaint.status == 'waiting_user_confirmation'
                ? () => context.push('/complaint/${complaint.id}').then((r) {
                      if (r == true) _loadComplaints();
                    })
                : null,
          );
        },
      ),
    );
  }
}
