import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_filter_panel.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../../widgets/admin/admin_section_header.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../complaints/complaint_detail_screen.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  // Static cache for global state persistence
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _cachedUsers = [];

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

    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedUsers.isNotEmpty) {
      debugPrint(
          '👥 [AdminUsersTab] Using cached data (${_cachedUsers.length} items)');
      _users = _cachedUsers;
      _hasLoadedData = true;
    }
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasLoadedDataGlobally) {
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
    // Skip loading if already loaded globally and not forcing refresh
    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Admin Users: Already loaded globally, skipping...');
      return;
    }

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
          _cachedUsers = _users; // Update cache
          _hasLoadedDataGlobally = true; // Mark as loaded globally
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
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User berhasil diverifikasi'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal verifikasi: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeRole(int id, String role) async {
    try {
      await _adminService.changeUserRole(id, role);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role berhasil diubah'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal ubah role: $e'),
              backgroundColor: Colors.red),
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
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Konfirmasi Password'),
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
                      backgroundColor: Colors.red),
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
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal reset password: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final addressController = TextEditingController();
    final nikController = TextEditingController();
    final rtController = TextEditingController();
    final rwController = TextEditingController();

    String selectedRole = 'user';
    final fieldErrors = <String, String>{};

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final passwordStrength =
              _calculatePasswordStrength(passwordController.text);
          final passwordStrengthLabel =
              _passwordStrengthLabel(passwordStrength);
          final passwordStrengthColor =
              _passwordStrengthColor(passwordStrength);

          return AlertDialog(
            title: const Text('Tambah Pengguna'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap*',
                        errorText: fieldErrors['name'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email*',
                        errorText: fieldErrors['email'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Password*',
                        errorText: fieldErrors['password'],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Kekuatan password: $passwordStrengthLabel',
                        style: TextStyle(
                            fontSize: 12, color: passwordStrengthColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: passwordStrength,
                        color: passwordStrengthColor,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password*',
                        errorText: fieldErrors['password_confirmation'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        errorText: fieldErrors['phone'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Alamat',
                        errorText: fieldErrors['address'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nikController,
                      decoration: InputDecoration(
                        labelText: 'NIK',
                        errorText: fieldErrors['nik'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rtController,
                            decoration: InputDecoration(
                              labelText: 'RT',
                              errorText:
                                  fieldErrors['rt_number'] ?? fieldErrors['rt'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: rwController,
                            decoration: InputDecoration(
                              labelText: 'RW',
                              errorText:
                                  fieldErrors['rw_number'] ?? fieldErrors['rw'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Peran'),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setLocalState(() => selectedRole = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  setLocalState(() => fieldErrors.clear());

                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  final passwordConfirmation =
                      confirmPasswordController.text.trim();

                  final localErrors = <String, String>{};

                  if (name.isEmpty) {
                    localErrors['name'] = 'Nama wajib diisi';
                  }

                  if (email.isEmpty) {
                    localErrors['email'] = 'Email wajib diisi';
                  } else if (!_isValidEmail(email)) {
                    localErrors['email'] = 'Format email tidak valid';
                  }

                  if (password.isEmpty) {
                    localErrors['password'] = 'Password wajib diisi';
                  } else if (!_isStrongPassword(password)) {
                    localErrors['password'] =
                        'Minimal 8 karakter, kombinasi huruf dan angka';
                  }

                  if (passwordConfirmation.isEmpty) {
                    localErrors['password_confirmation'] =
                        'Konfirmasi password wajib diisi';
                  } else if (passwordConfirmation != password) {
                    localErrors['password_confirmation'] =
                        'Konfirmasi password tidak sama';
                  }

                  if (localErrors.isNotEmpty) {
                    setLocalState(() {
                      fieldErrors
                        ..clear()
                        ..addAll(localErrors);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Periksa kembali input form'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  try {
                    final response = await _adminService.createUser({
                      'name': name,
                      'email': email,
                      'password': password,
                      'password_confirmation': passwordConfirmation,
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'nik': nikController.text.trim(),
                      'rt_number': rtController.text.trim(),
                      'rw_number': rwController.text.trim(),
                      'role': selectedRole,
                      'is_active': true,
                    });

                    if (!response.success) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(response.message.isEmpty
                                ? 'Gagal membuat pengguna'
                                : response.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadUsers(forceRefresh: true);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Pengguna berhasil dibuat'),
                          backgroundColor: Colors.green),
                    );
                  } on DioException catch (e) {
                    final parsed = _extractFieldErrors(e.response?.data);
                    if (parsed.isNotEmpty) {
                      setLocalState(() {
                        fieldErrors
                          ..clear()
                          ..addAll(parsed);
                      });
                    }

                    final fallbackMessage =
                        _extractGeneralMessage(e.response?.data) ??
                            'Gagal buat pengguna';
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                            content: Text(fallbackMessage),
                            backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                            content: Text('Gagal buat pengguna: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    nikController.dispose();
    rtController.dispose();
    rwController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdminFilterPanel(
            child: Column(
              children: [
                const AdminSectionHeader(
                  title: 'Manajemen Pengguna',
                  subtitle:
                      'Kelola data pengguna, peran, dan status verifikasi.',
                  icon: Icons.people,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari pengguna...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value);
                          _loadUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) {
                        setState(() =>
                            _selectedRole = value == 'all' ? null : value);
                        _loadUsers();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'all', child: Text('Semua Role')),
                        const PopupMenuItem(
                            value: 'admin', child: Text('Admin')),
                        const PopupMenuItem(value: 'user', child: Text('User')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Tambah User'),
                    ),
                  ],
                ),
                if (_selectedRole != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('Filter: $_selectedRole'),
                      onDeleted: () {
                        setState(() => _selectedRole = null);
                        _loadUsers();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Users List
        Expanded(
          child: !_hasLoadedData
              ? ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: 5,
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                )
              : _users.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.people_outline,
                      title: 'Tidak ada pengguna',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final role = user['role']?.toString() ?? 'user';
    final isVerified =
        user['is_user_verified'] == true || user['is_user_verified'] == 1;
    final isEmailVerified =
        user['is_email_verified'] == true || user['is_email_verified'] == 1;
    final roleColor = role == 'admin' ? Colors.red : Colors.blue;

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: roleColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      onTap: () {
        _showUserDetailDialog(user);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'user_${user['id']}',
            child: CircleAvatar(
              radius: 28,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified_user,
                                      size: 16, color: Colors.green),
                                ),
                              if (isEmailVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child:
                                      Icon(Icons.verified, size: 16, color: Colors.blue),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        switch (value) {
                          case 'verify':
                            _verifyUser(user['id']);
                            break;
                          case 'make_admin':
                            _changeRole(user['id'], 'admin');
                            break;
                          case 'make_user':
                            _changeRole(user['id'], 'user');
                            break;
                          case 'view':
                            _showUserDetailDialog(user);
                            break;
                          case 'reset_password':
                            _resetUserPassword(_toInt(user['id']),
                                userName: user['name']?.toString());
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isVerified)
                          const PopupMenuItem(
                            value: 'verify',
                            child: Row(
                              children: [
                                Icon(Icons.verified_user, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Verifikasi User'),
                              ],
                            ),
                          ),
                        if (role != 'admin')
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Jadikan Admin'),
                              ],
                            ),
                          ),
                        if (role == 'admin')
                          const PopupMenuItem(
                            value: 'make_user',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Jadikan User'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('Lihat Detail'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reset_password',
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Reset Password'),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchUserDetail(dynamic user) async {
    final summary = Map<String, dynamic>.from(user as Map);
    final id = _toInt(summary['id']);

    if (id == 0) return summary;

    try {
      final response = await _adminService.getUser(id);
      final data = response['data'] ?? response['user'] ?? response;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return summary;
    } catch (_) {
      return summary;
    }
  }

  void _showUserDetailDialog(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(
            title: const Text('Detail Pengguna'),
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserDetail(user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final detail =
                  snapshot.data ?? Map<String, dynamic>.from(user as Map);
              final id = _toInt(detail['id']);
              final role = detail['role']?.toString() ?? 'user';
              final roleColor = role == 'admin' ? Colors.red : Colors.blue;
              final isVerified = _toBool(detail['is_user_verified']) ||
                  _toBool(detail['is_verified']);
              final isEmailVerified = _toBool(detail['is_email_verified']) ||
                  detail['email_verified_at'] != null;
              final isActive = detail['is_active'] == null
                  ? true
                  : _toBool(detail['is_active']);

              final totalComplaints = _firstInt(detail, [
                'complaints_count',
                'total_complaints',
                'total_keluhan',
                'resolved_complaints',
                'total_reports',
              ]);
              final resolvedComplaintsRaw = _firstInt(detail, [
                'resolved_complaints_count',
                'resolved_complaints',
                'resolved_count',
                'completed_complaints_count',
                'completed_complaints',
                'completed_count',
                'resolved',
                'completed',
                'keluhan_selesai',
              ]);

              final resolvedComplaints = resolvedComplaintsRaw > 0
                  ? resolvedComplaintsRaw
                  : _countComplaintsByStatus(
                      detail, const {'resolved', 'completed'});

              final pendingComplaintsRaw = _firstInt(detail, [
                'pending_complaints_count',
                'pending_count',
                'in_progress_count',
                'pending',
                'in_progress',
                'keluhan_pending',
              ]);

              final pendingComplaints = pendingComplaintsRaw > 0
                  ? pendingComplaintsRaw
                  : _countComplaintsByStatus(
                      detail, const {'pending', 'in_progress', 'processing'});

              final totalComplaintsFinal = totalComplaints > 0
                  ? totalComplaints
                  : _extractComplaintList(detail).length;
              final totalComments = _firstInt(detail, [
                'comments_count',
                'total_comments',
                'komentar_count',
              ]);

              final latestComplaint = _firstMap(detail, [
                    'latest_complaint',
                    'recent_complaint',
                  ]) ??
                  _firstMapFromList(detail, [
                    'latest_complaints',
                    'recent_complaints',
                    'complaints',
                  ]);

              final latestComment = _firstMap(detail, [
                    'latest_comment',
                    'recent_comment',
                  ]) ??
                  _firstMapFromList(detail, [
                    'latest_comments',
                    'recent_comments',
                    'comments',
                  ]);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: roleColor,
                          child: Text(
                            (detail['name']?.toString().isNotEmpty ?? false)
                                ? detail['name']
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail['name']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStatusChip(
                                    isActive ? 'Aktif' : 'Nonaktif',
                                    isActive ? Colors.green : Colors.red,
                                    isActive ? Icons.check_circle : Icons.block,
                                  ),
                                  _buildStatusChip(
                                    role == 'admin' ? 'Admin' : 'User',
                                    role == 'admin' ? Colors.red : Colors.blue,
                                    role == 'admin'
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                  ),
                                  _buildStatusChip(
                                    isEmailVerified
                                        ? 'Email Verified'
                                        : '! Email Belum Verified',
                                    isEmailVerified
                                        ? Colors.green
                                        : Colors.orange,
                                    isEmailVerified
                                        ? Icons.verified
                                        : Icons.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(detail['email']?.toString() ?? '-'),
                              Text(detail['phone']?.toString() ?? '-'),
                              Text(
                                  'Bergabung ${_formatDate(detail['created_at'])}'),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            OutlinedButton(
                              onPressed: () => _showEditUserDialog(detail),
                              child: const Text('Ubah'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(routeContext),
                              child: const Text('Kembali'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width < 620 ? 1 : 2;
                        final itemWidth =
                            (width - (10 * (crossAxisCount - 1))) /
                                crossAxisCount;

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _buildStatCard(
                                  'Total Keluhan',
                                  totalComplaintsFinal.toString(),
                                  Icons.report_problem_outlined),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _buildStatCard(
                                  'Keluhan Selesai',
                                  resolvedComplaints.toString(),
                                  Icons.task_alt),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _buildStatCard(
                                  'Keluhan Pending',
                                  pendingComplaints.toString(),
                                  Icons.pending_actions),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _buildStatCard(
                                  'Total Komentar',
                                  totalComments.toString(),
                                  Icons.comment_outlined),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Keluhan Terbaru',
                      action: TextButton(
                        onPressed: () => _showAllUserComplaints(detail),
                        child: const Text('Lihat Semua'),
                      ),
                    ),
                    if (latestComplaint == null)
                      _buildEmptyTile('Belum ada keluhan',
                          'Pengguna ini belum pernah membuat keluhan.')
                    else
                      _buildLatestComplaintCard(latestComplaint),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Komentar Terbaru'),
                    if (latestComment == null)
                      _buildEmptyTile('Belum ada komentar',
                          'Pengguna ini belum pernah memberikan komentar.')
                    else
                      _buildLatestCommentCard(latestComment),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Detail Pengguna'),
                    _buildDetailRow(Icons.person, 'Nama Lengkap',
                        detail['name']?.toString() ?? '-'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.email, 'Email',
                        detail['email']?.toString() ?? '-'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.phone, 'Nomor Telepon',
                        detail['phone']?.toString() ?? '-'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.location_on, 'Alamat',
                        detail['address']?.toString() ?? '-'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        Icons.apartment,
                        'Lurah',
                        _firstString(detail, ['lurah', 'rt_number'],
                            fallback: '-')),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.home, 'RW',
                        _firstString(detail, ['rw_number'], fallback: '-')),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        Icons.badge, 'NIK', detail['nik']?.toString() ?? '-'),
                    const SizedBox(height: 14),
                    Text('Foto KTP',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    const SizedBox(height: 8),
                    _buildKtpBlock(detail),
                    const SizedBox(height: 14),
                    Text('Status Verifikasi KTP',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    const SizedBox(height: 6),
                    _buildStatusChip(
                      isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                      isVerified ? Colors.green : Colors.orange,
                      isVerified ? Icons.check_circle : Icons.warning,
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(
                        detail['verified_at'] ?? detail['updated_at'],
                        withTime: true)),
                    const SizedBox(height: 18),
                    _buildSectionHeader('Aksi Verifikasi'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isVerified
                              ? () {
                                  Navigator.pop(routeContext);
                                  _toggleUserVerification(detail,
                                      shouldVerify: false);
                                }
                              : () {
                                  Navigator.pop(routeContext);
                                  _toggleUserVerification(detail,
                                      shouldVerify: true);
                                },
                          icon: Icon(
                              isVerified ? Icons.undo : Icons.verified_user),
                          label: Text(isVerified
                              ? 'Batalkan Verifikasi'
                              : 'Verifikasi User'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(routeContext);
                            _toggleEmailVerification(detail,
                                shouldVerify: !isEmailVerified);
                          },
                          icon: Icon(isEmailVerified
                              ? Icons.mark_email_unread
                              : Icons.mark_email_read),
                          label: Text(isEmailVerified
                              ? 'Batalkan Verifikasi Email'
                              : 'Verifikasi Email'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader('Aksi'),
                    _buildDetailRow(Icons.security, 'Peran',
                        role == 'admin' ? 'Admin' : 'User'),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.toggle_on, 'Status',
                        isActive ? 'Aktif' : 'Nonaktif'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      Icons.mark_email_read,
                      'Email Verification',
                      isEmailVerified ? 'Verified' : 'Belum Verified',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.calendar_today, 'Bergabung',
                        _formatDate(detail['created_at'], withTime: true)),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.update, 'Terakhir Update',
                        _formatDate(detail['updated_at'], withTime: true)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditUserDialog(detail),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Pengguna'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(routeContext);
                            _toggleUserStatus(detail);
                          },
                          icon:
                              Icon(isActive ? Icons.block : Icons.check_circle),
                          label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAllUserComplaints(detail),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Lihat Semua Keluhan'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _resetUserPassword(id,
                              userName: detail['name']?.toString()),
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Reset Password'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(routeContext);
                            _confirmDeleteUser(detail);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Hapus Pengguna',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: Colors.blueGrey, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status']?.toString() ?? 'pending';
    final category = _firstString(
      complaint,
      ['category_name', 'category', 'category_title'],
      fallback: 'Tanpa Kategori',
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            complaint['title']?.toString() ??
                complaint['description']?.toString() ??
                '-',
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$category • ${_timeAgo(complaint['created_at'])}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildStatusChip(_complaintStatusText(status),
              _complaintStatusColor(status), Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildLatestCommentCard(Map<String, dynamic> comment) {
    final content =
        _firstString(comment, ['content', 'comment', 'message'], fallback: '-');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(_timeAgo(comment['created_at']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyTile(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildKtpBlock(Map<String, dynamic> detail) {
    final name = detail['name']?.toString() ?? 'Pengguna';
    final ktpUrl = _firstString(detail, ['ktp_url', 'ktp_path'], fallback: '');

    if (ktpUrl.isEmpty) {
      return _buildEmptyTile('KTP $name', 'Foto KTP belum tersedia.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.image),
          const SizedBox(width: 8),
          Expanded(
              child: Text('KTP $name',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () => _showKtpImage(ktpUrl, 'KTP $name'),
            child: const Text('Lihat ukuran penuh'),
          ),
        ],
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update status: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> detail) async {
    final id = _toInt(detail['id']);
    if (id == 0 || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin ingin menghapus ${detail['name'] ?? 'pengguna'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteUser(id);
      await _loadUsers(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengguna berhasil dihapus'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal hapus pengguna: $e'),
              backgroundColor: Colors.red),
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update verifikasi: $e'),
              backgroundColor: Colors.red),
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update verifikasi email: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditUserDialog(Map<String, dynamic> detail) {
    final id = _toInt(detail['id']);
    if (id == 0) return;

    final nameController =
        TextEditingController(text: detail['name']?.toString() ?? '');
    final emailController =
        TextEditingController(text: detail['email']?.toString() ?? '');
    final phoneController =
        TextEditingController(text: detail['phone']?.toString() ?? '');
    final addressController =
        TextEditingController(text: detail['address']?.toString() ?? '');
    final nikController =
        TextEditingController(text: detail['nik']?.toString() ?? '');
    final rtController =
        TextEditingController(text: detail['rt_number']?.toString() ?? '');
    final rwController =
        TextEditingController(text: detail['rw_number']?.toString() ?? '');

    String selectedRole = detail['role']?.toString() ?? 'user';
    bool isActive =
        detail['is_active'] == null ? true : _toBool(detail['is_active']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Edit Pengguna'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nama Lengkap')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Nomor Telepon')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Alamat')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: nikController,
                      decoration: const InputDecoration(labelText: 'NIK')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rtController,
                          decoration:
                              const InputDecoration(labelText: 'RT / Lurah'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: rwController,
                          decoration: const InputDecoration(labelText: 'RW'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Peran'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setLocalState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: const Text('Status Aktif'),
                    onChanged: (value) => setLocalState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _adminService.updateUser(id, {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'address': addressController.text.trim(),
                    'nik': nikController.text.trim(),
                    'rt_number': rtController.text.trim(),
                    'rw_number': rwController.text.trim(),
                    'role': selectedRole,
                    'is_active': isActive,
                  });

                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                  await _loadUsers(forceRefresh: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Data pengguna berhasil diperbarui'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal update pengguna: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      addressController.dispose();
      nikController.dispose();
      rtController.dispose();
      rwController.dispose();
    });
  }

  Future<void> _showAllUserComplaints(Map<String, dynamic> detail) async {
    final id = _toInt(detail['id']);
    final name = detail['name']?.toString() ?? 'Pengguna';

    if (id == 0) {
      _showInfo('ID pengguna tidak valid.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(
            title: Text('Semua Keluhan - $name'),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUserComplaints(detail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final complaints = snapshot.data ?? [];
              if (complaints.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Pengguna ini belum memiliki keluhan.'),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: complaints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return _buildUserComplaintItem(complaint);
                },
              );
            },
          ),
        ),
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
              backgroundColor: Colors.red),
        );
      }
      return [];
    }
  }

  Widget _buildUserComplaintItem(Map<String, dynamic> complaint) {
    final status = complaint['status']?.toString() ?? 'pending';

    return InkWell(
      onTap: () async {
        try {
          final complaintModel = Complaint.fromJson(complaint);
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ComplaintDetailScreen(complaint: complaintModel)),
          );
        } catch (_) {
          _showInfo('Detail keluhan tidak dapat dibuka.');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint['title']?.toString() ??
                  complaint['description']?.toString() ??
                  '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_firstString(complaint, [
                    'category_name',
                    'category'
                  ], fallback: 'Tanpa Kategori')} • ${_timeAgo(complaint['created_at'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildStatusChip(_complaintStatusText(status),
                _complaintStatusColor(status), Icons.info_outline),
          ],
        ),
      ),
    );
  }

  void _showKtpImage(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Gagal memuat gambar KTP'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  int _firstInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      return _toInt(source[key]);
    }
    return 0;
  }

  String _firstString(Map<String, dynamic> source, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  Map<String, dynamic>? _firstMap(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Map<String, dynamic>? _firstMapFromList(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  List<Map<String, dynamic>> _extractComplaintList(
      Map<String, dynamic> source) {
    const listKeys = [
      'complaints',
      'latest_complaints',
      'recent_complaints',
      'user_complaints',
    ];

    for (final key in listKeys) {
      final value = source[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return const [];
  }

  int _countComplaintsByStatus(
      Map<String, dynamic> source, Set<String> statuses) {
    final normalizedTargets = statuses.map((e) => e.toLowerCase()).toSet();

    // 1) Try aggregate maps if backend provides counters by status.
    const mapKeys = [
      'complaints_by_status',
      'complaint_status_counts',
      'status_counts',
      'statistics',
      'stats',
    ];

    for (final key in mapKeys) {
      final value = source[key];
      if (value is Map) {
        final counts = Map<String, dynamic>.from(value);
        var total = 0;
        for (final target in normalizedTargets) {
          total += _toInt(counts[target]);
        }
        if (total > 0) return total;
      }
    }

    // 2) Fallback to counting directly from complaint list payload.
    final complaints = _extractComplaintList(source);
    if (complaints.isEmpty) return 0;

    return complaints.where((complaint) {
      final status = complaint['status']?.toString().toLowerCase() ?? '';
      return normalizedTargets.contains(status);
    }).length;
  }

  String _formatDate(dynamic value, {bool withTime = false}) {
    final date = _parseDate(value);
    if (date == null) return '-';
    if (withTime) {
      return DateFormat('d MMMM y, HH:mm').format(date);
    }
    return DateFormat('d MMMM y').format(date);
  }

  String _timeAgo(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _formatDate(date);
  }

  String _complaintStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _complaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is! Map) return const {};

    final map = Map<String, dynamic>.from(data);
    final errorsRaw = map['errors'];
    if (errorsRaw is! Map) return const {};

    final result = <String, String>{};
    final errors = Map<String, dynamic>.from(errorsRaw);

    for (final entry in errors.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is List && value.isNotEmpty) {
        result[key] = value.first.toString();
      } else if (value != null) {
        result[key] = value.toString();
      }
    }

    return result;
  }

  String? _extractGeneralMessage(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final message = map['message'];
    if (message == null) return null;
    return message.toString();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    return hasLetter && hasNumber;
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    var score = 0.0;
    if (password.length >= 8) score += 0.35;
    if (password.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 0.15;

    if (score > 1) return 1;
    return score;
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
}
