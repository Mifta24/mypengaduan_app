import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import 'user_complaints_screen.dart';
import 'user_detail_screen.dart';
import 'user_form_utils.dart';
import 'widgets/user_list_card.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _users = [];
  bool _hasLoadedData = false;
  String? _selectedRole;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '👥 [AdminUsersTab] Screen initialized - will load after visible');
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          debugPrint('👥 [AdminUsersTab] Screen visible - loading users now');
          _loadUsers();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    if (_hasLoadedData && !forceRefresh) return;

    debugPrint('Admin Users: Loading users... (forceRefresh: $forceRefresh)');
    try {
      final response = await _adminService.getUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _selectedRole,
        perPage: 10,
      );

      if (mounted) {
        final currentUserId = context.read<AuthProvider>().user?.id;
        final fetchedUsers = (response['data'] ?? []) as List;

        final filteredUsers = currentUserId == null
            ? fetchedUsers
            : fetchedUsers.where((item) {
                if (item is! Map) return true;
                final userMap = Map<String, dynamic>.from(item);
                return parseUserId(userMap['id']) != currentUserId;
              }).toList();

        setState(() {
          _users = filteredUsers;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      if (mounted) {
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _verifyUser(int id) async {
    try {
      await _adminService.verifyUser(id);
      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User berhasil diverifikasi'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal verifikasi: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _changeRole(int id, String role) async {
    try {
      await _adminService.changeUserRole(id, role);
      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role berhasil diubah'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal ubah role: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _resetUserPassword(int id, String userName) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userName.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('User: $userName'),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: userFormFieldDecoration(label: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: userFormFieldDecoration(label: 'Konfirmasi Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.trim().isEmpty ||
                  confirmController.text.trim().isEmpty ||
                  passwordController.text.trim() !=
                      confirmController.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password tidak valid / tidak cocok'),
                      backgroundColor: AppTheme.danger),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.resetUserPassword(id, passwordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password berhasil direset'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal reset password: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _navigateToAddUser() async {
    final created = await context.push<bool>(AppRouter.adminUsersAdd);

    if (created == true && mounted) {
      await _loadUsers(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengguna berhasil dibuat'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _users.where((u) {
      final name  = u['name']?.toString().toLowerCase()  ?? '';
      final email = u['email']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || email.contains(q);
    }).toList();

    return Column(
      children: [
        // ── Search + Tambah ─────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.nunito(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email pengguna...',
                    hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onSubmitted: (_) => _loadUsers(forceRefresh: true),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _navigateToAddUser,
                icon: const Icon(Icons.person_add, size: 16),
                label: Text('Tambah', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppTheme.border),

        // ── Users list ───────────────────────────────────────
        Expanded(
          child: !_hasLoadedData && _users.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : filtered.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.people_outline,
                      title: 'Tidak ada pengguna',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(forceRefresh: true),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => UserListCard(
                          user: filtered[i],
                          onTap: () => _showUserDetailDialog(filtered[i]),
                          onVerify: _verifyUser,
                          onChangeRole: _changeRole,
                          onResetPassword: _resetUserPassword,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchUserDetail(dynamic user) async {
    final summary = Map<String, dynamic>.from(user as Map);
    final id = parseUserId(summary['id']);

    if (id == 0) return summary;

    try {
      final response = await _adminService.getUser(id);
      final raw = response['data'] ?? response['user'] ?? response;
      final Map<String, dynamic> result = raw is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw)
          : raw is Map
              ? Map<String, dynamic>.from(raw)
              : Map<String, dynamic>.from(summary);

      // Flatten nested profile object so fields like phone/rt_number are top-level
      for (final key in ['profile', 'user_profile', 'userProfile']) {
        final nested = result[key];
        if (nested is Map) {
          for (final e in nested.entries) {
            result.putIfAbsent(e.key as String, () => e.value);
          }
        }
      }

      return result;
    } catch (_) {
      return summary;
    }
  }

  void _showUserDetailDialog(dynamic user) {
    context.push(
      AppRouter.adminUserDetail,
      extra: AdminUserDetailArgs(
        user: user,
        fetchDetail: _fetchUserDetail,
        onEditUser: _navigateToEditUser,
        onToggleVerification: _toggleUserVerification,
        onToggleEmailVerification: _toggleEmailVerification,
        onToggleStatus: _toggleUserStatus,
        onResetPassword: (id, {String? userName}) => _resetUserPassword(id, userName ?? ''),
        onDelete: _confirmDeleteUser,
        onShowAllComplaints: _showAllUserComplaints,
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> detail) async {
    final id = parseUserId(detail['id']);
    if (id == 0) return;

    final isActive = parseUserBool(detail['is_active'], defaultValue: true);

    try {
      await _adminService.updateUser(id, {'is_active': !isActive});
      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive
                ? 'Pengguna berhasil dinonaktifkan'
                : 'Pengguna berhasil diaktifkan'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update status: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> detail) async {
    final id = parseUserId(detail['id']);
    if (id == 0 || !mounted) return;

    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Hapus Pengguna',
      message: 'Yakin ingin menghapus ${detail['name'] ?? 'pengguna'}?',
    );

    if (!confirmed) return;

    try {
      await _adminService.deleteUser(id);
      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengguna berhasil dihapus'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal hapus pengguna: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _toggleUserVerification(Map<String, dynamic> detail,
      {required bool shouldVerify}) async {
    final id = parseUserId(detail['id']);
    if (id == 0) return;

    try {
      if (shouldVerify) {
        await _adminService.verifyUser(id);
      } else {
        await _adminService.rejectUserVerification(id);
      }

      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldVerify
                ? 'Pengguna berhasil diverifikasi'
                : 'Verifikasi pengguna dibatalkan'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update verifikasi: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _toggleEmailVerification(Map<String, dynamic> detail,
      {required bool shouldVerify}) async {
    final id = parseUserId(detail['id']);
    if (id == 0) return;

    try {
      if (shouldVerify) {
        await _adminService.verifyUserEmail(id);
      } else {
        await _adminService.unverifyUserEmail(id);
      }

      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldVerify
                ? 'Email pengguna berhasil diverifikasi'
                : 'Verifikasi email dibatalkan'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update verifikasi email: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _navigateToEditUser(Map<String, dynamic> detail) async {
    final id = parseUserId(detail['id']);
    if (id == 0) return;
    final originalRole = detail['role']?.toString() ?? 'user';

    final newRole = await context.push<String>(AppRouter.adminUsersEdit, extra: detail);

    if (newRole == null || !mounted) return;

    // Explicitly change role via dedicated endpoint when it changed
    if (newRole != originalRole) {
      try {
        await _adminService.changeUserRole(id, newRole);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data disimpan tapi role gagal diubah: $e'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }
    }

    await _loadUsers(forceRefresh: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data pengguna berhasil diperbarui'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _showAllUserComplaints(Map<String, dynamic> detail) async {
    final id = parseUserId(detail['id']);
    final name = detail['name']?.toString() ?? 'Pengguna';

    if (id == 0) {
      _showInfo('ID pengguna tidak valid.');
      return;
    }

    await context.push(
      AppRouter.adminUserComplaints,
      extra: AdminUserComplaintsArgs(
        userName: name,
        fetchComplaints: () => _fetchUserComplaints(detail),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserComplaints(
      Map<String, dynamic> detail) async {
    final id = parseUserId(detail['id']);
    if (id == 0) return [];

    try {
      final response = await _adminService.getComplaints(
        perPage: 50,
        search: detail['name']?.toString(),
        userId: id,
      );
      final raw = (response['data'] as List?) ?? const [];
      final complaints = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final filtered = complaints.where((complaint) {
        final complaintUser = complaint['user'];
        if (complaintUser is Map) {
          final uid = parseUserId(complaintUser['id']);
          if (uid != 0) return uid == id;
        }
        final complaintUserId = parseUserId(complaint['user_id']);
        return complaintUserId == 0 ? true : complaintUserId == id;
      }).toList();

      filtered.sort((a, b) {
        final ad = _parseDate(a['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _parseDate(b['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      return filtered;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat keluhan pengguna: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
      return [];
    }
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
