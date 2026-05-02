import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../theme/app_theme.dart';
import '../complaints/complaint_detail_screen.dart';

class PopularCategoriesScreen extends StatefulWidget {
  const PopularCategoriesScreen({super.key});

  @override
  State<PopularCategoriesScreen> createState() => _PopularCategoriesScreenState();
}

class _PopularCategoriesScreenState extends State<PopularCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ComplaintProvider>();
      if (p.categories.isEmpty) {
        Future.wait([p.loadCategories(), p.loadComplaints()]);
      } else if (p.complaints.isEmpty) {
        p.loadComplaints();
      }
    });
  }

  static const _categoryIcons = <String, IconData>{
    'jalan': Icons.add_road_rounded,
    'infrastruktur': Icons.construction_rounded,
    'kebersihan': Icons.cleaning_services_rounded,
    'sampah': Icons.delete_rounded,
    'air': Icons.water_drop_rounded,
    'listrik': Icons.bolt_rounded,
    'perizinan': Icons.assignment_rounded,
    'keamanan': Icons.security_rounded,
    'drainase': Icons.water_damage_rounded,
    'lingkungan': Icons.park_rounded,
    'sosial': Icons.people_rounded,
    'kesehatan': Icons.local_hospital_rounded,
    'pendidikan': Icons.school_rounded,
    'lainnya': Icons.more_horiz_rounded,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.label_rounded;
  }

  static const _palette = [
    Color(0xFF2E7D32), Color(0xFF0891B2), Color(0xFF6366F1),
    Color(0xFFD97706), Color(0xFFDC2626), Color(0xFF0D9488),
    Color(0xFF7C3AED), Color(0xFFEA580C),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kategori Keluhan',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Belum ada kategori',
                      style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          // Hitung jumlah complaint per kategori
          final counts = <int, int>{};
          for (final c in provider.complaints) {
            final id = c.categoryId ?? c.category?.id;
            if (id != null) counts[id] = (counts[id] ?? 0) + 1;
          }

          final categories = provider.categories
              .where((c) => c.isActive)
              .toList()
            ..sort((a, b) =>
                (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.loadCategories(),
                provider.loadComplaints(),
              ]);
            },
            color: AppTheme.primary,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final count = counts[cat.id] ?? 0;
                final color = _palette[i % _palette.length];
                return _CategoryCard(
                  category: cat,
                  icon: _iconFor(cat.name),
                  color: color,
                  count: count,
                  complaints: provider.complaints
                      .where((c) =>
                          c.categoryId == cat.id || c.category?.id == cat.id)
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  final IconData icon;
  final Color color;
  final int count;
  final List<Complaint> complaints;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.color,
    required this.count,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _CategoryComplaintsScreen(
            category: category,
            color: color,
            icon: icon,
            complaints: complaints,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(category.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: count > 0 ? color.withValues(alpha: 0.10) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count > 0 ? '$count pengaduan' : 'Belum ada',
                style: GoogleFonts.nunito(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: count > 0 ? color : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Complaints per Category ──────────────────────────────────────────────────
class _CategoryComplaintsScreen extends StatelessWidget {
  final Category category;
  final Color color;
  final IconData icon;
  final List<Complaint> complaints;

  const _CategoryComplaintsScreen({
    required this.category,
    required this.color,
    required this.icon,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(category.name,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 17,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Belum ada pengaduan di kategori ini',
                      style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (_, i) =>
                  _ComplaintMiniCard(complaint: complaints[i], accentColor: color),
            ),
    );
  }
}

// ─── Mini Complaint Card (dalam kategori) ─────────────────────────────────────
class _ComplaintMiniCard extends StatelessWidget {
  final Complaint complaint;
  final Color accentColor;
  const _ComplaintMiniCard({required this.complaint, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(complaint.status);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ComplaintDetailScreen(complaint: complaint))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.report_rounded, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complaint.title,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(complaint.location,
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: Colors.grey.shade400),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusInfo.bg,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statusInfo.label,
                  style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: statusInfo.color)),
            ),
          ],
        ),
      ),
    );
  }

  ({Color color, Color bg, String label}) _statusInfo(String s) {
    switch (s) {
      case 'pending':
        return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7), label: 'Menunggu');
      case 'in_progress':
        return (color: const Color(0xFF0891B2), bg: const Color(0xFFDBEAFE), label: 'Diproses');
      case 'waiting_user_confirmation':
        return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED), label: 'Konfirmasi');
      case 'resolved':
        return (color: AppTheme.primary, bg: const Color(0xFFD1FAE5), label: 'Selesai');
      case 'rejected':
        return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2), label: 'Ditolak');
      default:
        return (color: Colors.grey, bg: Colors.grey.shade100, label: s);
    }
  }
}