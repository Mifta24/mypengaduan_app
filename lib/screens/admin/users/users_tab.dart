import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import 'user_detail_screen.dart';

InputDecoration _userFormFieldDecoration({
  required String label,
  String? hint,
  String? errorText,
}) {
  return AppTheme.inputDecoration(label: label, hint: hint, errorText: errorText);
}

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
                return _toInt(userMap['id']) != currentUserId;
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

  Future<void> _resetUserPassword(int id, {String? userName}) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((userName ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('User: $userName'),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _userFormFieldDecoration(label: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: _userFormFieldDecoration(label: 'Konfirmasi Password'),
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

  Future<void> _showCreateUserDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateUserDialog(adminService: _adminService),
    );

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
                onPressed: _showCreateUserDialog,
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
                        itemBuilder: (_, i) => _buildUserCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final role = user['role']?.toString() ?? 'user';
    final isVerified = _toBool(user['is_user_verified']) || _toBool(user['is_verified']);
    final name  = user['name']?.toString()  ?? 'Pengguna';
    final email = user['email']?.toString() ?? '';
    final initials = name.trim().split(' ').take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final avatarColor = isVerified ? AppTheme.primary : const Color(0xFFD97706);

    return GestureDetector(
      onTap: () => _showUserDetailDialog(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials,
                    style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w800, color: avatarColor)),
              ),
            ),
            const SizedBox(width: 12),
            // Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Role + verification badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (role == 'admin' ? const Color(0xFF6366F1) : AppTheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role == 'admin' ? 'Admin' : 'Warga',
                    style: GoogleFonts.nunito(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: role == 'admin' ? const Color(0xFF6366F1) : AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.verified_rounded : Icons.cancel_rounded,
                      size: 13,
                      color: isVerified ? AppTheme.primary : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isVerified ? 'Terverifikasi' : 'Belum',
                      style: GoogleFonts.nunito(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isVerified ? AppTheme.primary : const Color(0xFFD97706)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            // More actions
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              onSelected: (value) {
                switch (value) {
                  case 'verify':     _verifyUser(_toInt(user['id']));
                  case 'make_admin': _changeRole(_toInt(user['id']), 'admin');
                  case 'make_user':  _changeRole(_toInt(user['id']), 'user');
                  case 'view':       _showUserDetailDialog(user);
                  case 'reset_password':
                    _resetUserPassword(_toInt(user['id']), userName: name);
                }
              },
              itemBuilder: (_) => [
                if (!isVerified)
                  const PopupMenuItem(value: 'verify', child: Row(children: [Icon(Icons.verified_user, size: 16, color: AppTheme.primary), SizedBox(width: 8), Text('Verifikasi')])),
                if (role != 'admin')
                  const PopupMenuItem(value: 'make_admin', child: Row(children: [Icon(Icons.admin_panel_settings, size: 16, color: Colors.indigo), SizedBox(width: 8), Text('Jadikan Admin')])),
                if (role == 'admin')
                  const PopupMenuItem(value: 'make_user', child: Row(children: [Icon(Icons.person, size: 16, color: Colors.teal), SizedBox(width: 8), Text('Jadikan User')])),
                const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 16), SizedBox(width: 8), Text('Lihat Detail')])),
                const PopupMenuItem(value: 'reset_password', child: Row(children: [Icon(Icons.lock_reset, size: 16, color: Colors.blueGrey), SizedBox(width: 8), Text('Reset Password')])),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Future<Map<String, dynamic>> _fetchUserDetail(dynamic user) async {
    final summary = Map<String, dynamic>.from(user as Map);
    final id = _toInt(summary['id']);

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
        onEditUser: _showEditUserDialog,
        onToggleVerification: _toggleUserVerification,
        onToggleEmailVerification: _toggleEmailVerification,
        onToggleStatus: _toggleUserStatus,
        onResetPassword: _resetUserPassword,
        onDelete: _confirmDeleteUser,
        onShowAllComplaints: _showAllUserComplaints,
      ),
    );
  }


  Future<void> _toggleUserStatus(Map<String, dynamic> detail) async {
    final id = _toInt(detail['id']);
    if (id == 0) return;

    final isActive =
        detail['is_active'] == null ? true : _toBool(detail['is_active']);

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
    final id = _toInt(detail['id']);
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
    final id = _toInt(detail['id']);
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
    final id = _toInt(detail['id']);
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

  Future<void> _showEditUserDialog(Map<String, dynamic> detail) async {
    final id = _toInt(detail['id']);
    if (id == 0) return;
    final originalRole = detail['role']?.toString() ?? 'user';

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => _EditUserDialog(
        adminService: _adminService,
        detail: detail,
      ),
    );

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
    final id = _toInt(detail['id']);
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
    final id = _toInt(detail['id']);
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
          final uid = _toInt(complaintUser['id']);
          if (uid != 0) return uid == id;
        }
        final complaintUserId = _toInt(complaint['user_id']);
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'aktif';
    }
    return false;
  }





  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }



}

// ---------------------------------------------------------------------------
// Extracted StatefulWidget for the "Tambah Pengguna" dialog so that
// TextEditingControllers are disposed in State.dispose() — only called after
// the dialog exit animation fully completes — preventing the
// "TextEditingController used after being disposed" and
// "_dependents.isEmpty" assertion errors.
// ---------------------------------------------------------------------------

class _CreateUserDialog extends StatefulWidget {
  final AdminService adminService;
  const _CreateUserDialog({required this.adminService});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _nikController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();

  String _selectedRole = 'user';
  final _fieldErrors = <String, String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _calcPasswordStrength(_passwordController.text);
    final strengthLabel = _passwordStrengthLabel(passwordStrength);
    final strengthColor = _passwordStrengthColor(passwordStrength);

    return AlertDialog(
      title: const Text('Tambah Pengguna'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: _userFormFieldDecoration(
                  label: 'Nama Lengkap*',
                  errorText: _fieldErrors['name'],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: _userFormFieldDecoration(
                  label: 'Email*',
                  errorText: _fieldErrors['email'],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: _userFormFieldDecoration(
                  label: 'Password*',
                  errorText: _fieldErrors['password'],
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kekuatan password: $strengthLabel',
                  style: TextStyle(fontSize: 12, color: strengthColor),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: passwordStrength,
                  color: strengthColor,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: _userFormFieldDecoration(
                  label: 'Konfirmasi Password*',
                  errorText: _fieldErrors['password_confirmation'],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: _userFormFieldDecoration(
                  label: 'Nomor Telepon',
                  errorText: _fieldErrors['phone'],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: _userFormFieldDecoration(
                  label: 'Alamat',
                  errorText: _fieldErrors['address'],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nikController,
                decoration: _userFormFieldDecoration(
                  label: 'NIK',
                  errorText: _fieldErrors['nik'],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rtController,
                      decoration: _userFormFieldDecoration(
                        label: 'RT',
                        errorText:
                            _fieldErrors['rt_number'] ?? _fieldErrors['rt'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rwController,
                      decoration: _userFormFieldDecoration(
                        label: 'RW',
                        errorText:
                            _fieldErrors['rw_number'] ?? _fieldErrors['rw'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: _userFormFieldDecoration(label: 'Peran'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _fieldErrors.clear());

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirmation = _confirmPasswordController.text.trim();

    final localErrors = <String, String>{};

    if (name.isEmpty) localErrors['name'] = 'Nama wajib diisi';

    if (email.isEmpty) {
      localErrors['email'] = 'Email wajib diisi';
    } else if (!_isValidEmail(email)) {
      localErrors['email'] = 'Format email tidak valid';
    }

    if (password.isEmpty) {
      localErrors['password'] = 'Password wajib diisi';
    } else if (!_isStrongPassword(password)) {
      localErrors['password'] = 'Minimal 8 karakter, kombinasi huruf dan angka';
    }

    if (passwordConfirmation.isEmpty) {
      localErrors['password_confirmation'] = 'Konfirmasi password wajib diisi';
    } else if (passwordConfirmation != password) {
      localErrors['password_confirmation'] = 'Konfirmasi password tidak sama';
    }

    if (localErrors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(localErrors);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Periksa kembali input form'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    try {
      final response = await widget.adminService.createUser({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        ..._adminUserProfilePayload(
          phone: _phoneController.text,
          address: _addressController.text,
          nik: _nikController.text,
          rtNumber: _rtController.text,
          rwNumber: _rwController.text,
        ),
        'role': _selectedRole,
        'is_active': true,
      });

      if (!response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isEmpty
                  ? 'Gagal membuat pengguna'
                  : response.message),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Server may create user as 'user' regardless of role param.
      // Explicitly change role if admin was requested.
      if (_selectedRole == 'admin') {
        final rawData = response.data;
        if (rawData is Map) {
          final rawId = rawData['id'];
          final numId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          if (numId != null && numId > 0) {
            try {
              await widget.adminService.changeUserRole(numId, 'admin');
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User dibuat tapi gagal set role admin: $e'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            }
          }
        }
      }

      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      final parsed = _extractCreateFieldErrors(e.response?.data);
      if (parsed.isNotEmpty) {
        setState(() {
          _fieldErrors
            ..clear()
            ..addAll(parsed);
        });
      }
      final fallbackMessage =
          _extractCreateGeneralMessage(e.response?.data) ?? 'Gagal buat pengguna';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMessage), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal buat pengguna: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  bool _isStrongPassword(String password) {
    if (password.length < 8) { return false; }
    return RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  double _calcPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0.0;
    if (password.length >= 8) score += 0.35;
    if (password.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String _passwordStrengthLabel(double score) {
    if (score >= 0.85) return 'Sangat Kuat';
    if (score >= 0.65) return 'Kuat';
    if (score >= 0.4) return 'Sedang';
    if (score > 0) return 'Lemah';
    return '-';
  }

  Color _passwordStrengthColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.65) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Map<String, String> _extractCreateFieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final errorsRaw = Map<String, dynamic>.from(data)['errors'];
    if (errorsRaw is! Map) return const {};
    final result = <String, String>{};
    for (final entry in Map<String, dynamic>.from(errorsRaw).entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty) {
        result[entry.key] = v.first.toString();
      } else if (v != null) {
        result[entry.key] = v.toString();
      }
    }
    return result;
  }

  String? _extractCreateGeneralMessage(dynamic data) {
    if (data is! Map) return null;
    final message = Map<String, dynamic>.from(data)['message'];
    return message?.toString();
  }
}

// ---------------------------------------------------------------------------
// Extracted StatefulWidget for the "Edit Pengguna" dialog.
// Controllers are owned by State.dispose() so they are released only after
// the dialog exit animation completes. The dialog returns the selected role
// (String) on save, or null on cancel.
// ---------------------------------------------------------------------------

class _EditUserDialog extends StatefulWidget {
  final AdminService adminService;
  final Map<String, dynamic> detail;

  const _EditUserDialog({
    required this.adminService,
    required this.detail,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _nikController;
  late final TextEditingController _rtController;
  late final TextEditingController _rwController;

  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _nameController    = TextEditingController(text: _pick(d, ['name']));
    _emailController   = TextEditingController(text: _pick(d, ['email']));
    _phoneController   = TextEditingController(text: _pick(d, ['phone', 'phone_number']));
    _addressController = TextEditingController(text: _pick(d, ['address', 'alamat']));
    _nikController     = TextEditingController(text: _pick(d, ['nik']));
    _rtController      = TextEditingController(text: _pick(d, ['rt_number', 'rt']));
    _rwController      = TextEditingController(text: _pick(d, ['rw_number', 'rw']));
    _selectedRole      = d['role']?.toString() ?? 'user';
    _isActive          = _parseBool(d['is_active']);
  }

  static String _pick(Map<String, dynamic> d, List<String> keys) {
    for (final key in keys) {
      final v = d[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pengguna'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: _userFormFieldDecoration(label: 'Nama Lengkap'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: _userFormFieldDecoration(label: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: _userFormFieldDecoration(label: 'Nomor Telepon'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: _userFormFieldDecoration(label: 'Alamat'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nikController,
                decoration: _userFormFieldDecoration(label: 'NIK'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rtController,
                      decoration: _userFormFieldDecoration(label: 'RT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rwController,
                      decoration: _userFormFieldDecoration(label: 'RW'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: _userFormFieldDecoration(label: 'Peran'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                title: const Text('Status Aktif'),
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final id = _toInt(widget.detail['id']);
    try {
      await widget.adminService.updateUser(id, {
        'name':       _nameController.text.trim(),
        'email':      _emailController.text.trim(),
        ..._adminUserProfilePayload(
          phone: _phoneController.text,
          address: _addressController.text,
          nik: _nikController.text,
          rtNumber: _rtController.text,
          rwNumber: _rwController.text,
        ),
        'role':       _selectedRole,
        'is_active':  _isActive,
      });
      if (mounted) Navigator.pop(context, _selectedRole);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update pengguna: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
    }
    return false;
  }
}

Map<String, dynamic> _adminUserProfilePayload({
  required String phone,
  required String address,
  required String nik,
  required String rtNumber,
  required String rwNumber,
}) {
  return {
    'phone': phone.trim(),
    'address': address.trim(),
    'nik': nik.trim(),
    'rt_number': rtNumber.trim(),
    'rw_number': rwNumber.trim(),
    'rt': rtNumber.trim(),
    'rw': rwNumber.trim(),
  };
}
