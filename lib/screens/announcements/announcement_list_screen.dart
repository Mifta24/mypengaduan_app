import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/announcement_model.dart' as models;
import '../../services/announcement_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'widgets/announcement_list_card.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final AnnouncementService _announcementService = AnnouncementService();
  String _selectedPriority = 'Semua Prioritas';
  List<models.Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Static variable to track if data has been loaded across all instances
  static bool _hasLoadedDataGlobally = false;
  static List<models.Announcement> _cachedAnnouncements = [];

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📢 [AnnouncementListScreen] Screen initialized - will load after visible');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedAnnouncements.isNotEmpty) {
      debugPrint(
          'Using cached announcements (${_cachedAnnouncements.length} items)');
      _announcements = _cachedAnnouncements;
      setState(() {});
    } else if (!_hasLoadedOnce) {
      // Load only once when screen becomes visible
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasLoadedDataGlobally) {
          debugPrint(
              '📢 [AnnouncementListScreen] Screen visible - loading announcements now');
          _loadAnnouncements();
        }
      });
    }
  }

  bool _hasLoadedOnce = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements({bool forceRefresh = false}) async {
    // Skip if already loading
    if (_isLoading) {
      debugPrint('Already loading, skipping...');
      return;
    }

    // Skip if already loaded globally and not forcing refresh
    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Announcements already loaded globally, skipping...');
      return;
    }

    // Check mounted before setState
    if (!mounted) return;

    debugPrint('Loading announcements... (forceRefresh: $forceRefresh)');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _announcementService.getAnnouncements(
        page: 1,
        perPage: 50,
      );

      if (mounted) {
        setState(() {
          _announcements = response.data;
          _cachedAnnouncements = response.data; // Update cache
          _hasLoadedDataGlobally = true; // Mark as loaded globally
          _isLoading = false;
        });
        debugPrint('Announcements loaded: ${_announcements.length} items');
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');

      // Check if it's token expiration error
      if (e.toString().contains('Token expired') && mounted) {
        // Auto-logout and redirect to landing page
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          context.go(AppRouter.landing);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Dummy data for fallback - kept for reference
  // final List<Announcement> _dummyAnnouncements = [
  //   Announcement(
  //     id: 1,
  //     title: 'Pengumuman Penting: Pemadaman Listrik',
  //     content: 'PLN akan melakukan pemadaman listrik terjadwal di wilayah RT 01. Berdasarkan informasi dari PLN, akan dilakukan pemadaman listrik terjadwal di wilayah RT 01 pada hari Sabtu, 12 Oktober 2025 mulai pukul 08:00 - 16:00 WIB. Mohon atas perhatian dan kerjasamanya.',
  //     author: 'Ketua RT',
  //     priority: 'Mendesak',
  //     date: DateTime(2026, 1, 11, 21, 27),
  //     category: 'Semua Warga',
  //   ),
  //   Announcement(
  //     id: 2,
  //     title: 'Gotong Royong Mingguan',
  //     content: 'Mengundang seluruh warga RT 01 untuk mengikuti gotong royong setiap hari Minggu pagi mulai pukul 07:00 WIB. Mari bersama-sama menjaga kebersihan lingkungan kita.',
  //     author: 'Ketua RT',
  //     priority: 'Tinggi',
  //     date: DateTime(2026, 1, 11, 3, 27),
  //     category: 'Semua Warga',
  //   ),
  //   Announcement(
  //     id: 3,
  //     title: 'Rapat RT Bulanan',
  //     content: 'Rapat RT akan dilaksanakan pada hari Rabu, 15 Oktober 2025 pukul 19:30 WIB di Pos RT. Agenda: pembahasan iuran RT dan program kerja bulan depan.',
  //     author: 'Ketua RT',
  //     priority: 'Sedang',
  //     date: DateTime(2026, 1, 11, 16, 27),
  //     category: 'Semua Warga',
  //   ),
  //   Announcement(
  //     id: 4,
  //     title: 'Peringatan Hari Kemerdekaan',
  //     content: 'Dalam rangka memperingati HUT RI ke-80, Lurah 01 akan mengadakan lomba untuk anak-anak dan dewasa dalam rangka HUT RI. Lomba meliputi balap karung, makan kerupuk, dan panjat pinang.',
  //     author: 'Ketua RT',
  //     priority: 'Rendah',
  //     date: DateTime(2025, 12, 13, 3, 27),
  //     category: 'Semua Warga',
  //   ),
  // ];

  List<models.Announcement> get _filteredAnnouncements {
    final list = _announcements.where((announcement) {
      final matchesSearch = announcement.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          announcement.content
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      const priorityMap = {
        'Semua Prioritas': '',
        'Mendesak': 'urgent',
        'Tinggi': 'high',
        'Sedang': 'normal',
        'Rendah': 'low',
      };

      final matchesPriority = _selectedPriority == 'Semua Prioritas' ||
          announcement.priority.toLowerCase() ==
              priorityMap[_selectedPriority]?.toLowerCase();

      return matchesSearch && matchesPriority;
    }).toList();

    // Sticky announcements always appear first, then sorted by date descending
    list.sort((a, b) {
      if (a.isSticky && !b.isSticky) return -1;
      if (!a.isSticky && b.isSticky) return 1;
      final dateA = a.publishedAt ?? a.createdAt;
      final dateB = b.publishedAt ?? b.createdAt;
      return dateB.compareTo(dateA);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Pengumuman',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari pengumuman...',
                    hintStyle: GoogleFonts.nunito(
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Button
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<String>(
                        initialValue: _selectedPriority,
                        onSelected: (value) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filter',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          'Semua Prioritas',
                          'Mendesak',
                          'Tinggi',
                          'Sedang',
                          'Rendah',
                        ].map((priority) {
                          return PopupMenuItem<String>(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat pengumuman',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadAnnouncements,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _filteredAnnouncements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 80,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada pengumuman',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _loadAnnouncements(forceRefresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAnnouncements.length,
                              itemBuilder: (context, index) {
                                final announcement =
                                    _filteredAnnouncements[index];
                                return AnnouncementListCard(
                                  announcement: announcement,
                                  onTap: () => context.push(
                                    AppRouter.announcementDetail,
                                    extra: announcement,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
