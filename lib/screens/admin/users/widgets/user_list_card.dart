import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../user_form_utils.dart';

/// Single row card in the admin users list, with the role/verification
/// badges and the "more actions" popup menu.
class UserListCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;
  final void Function(int id) onVerify;
  final void Function(int id, String role) onChangeRole;
  final void Function(int id, String userName) onResetPassword;

  const UserListCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onVerify,
    required this.onChangeRole,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'user';
    final isVerified = parseUserBool(user['is_user_verified']) || parseUserBool(user['is_verified']);
    final name = user['name']?.toString() ?? 'Pengguna';
    final email = user['email']?.toString() ?? '';
    final initials = name.trim().split(' ').take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final avatarColor = isVerified ? AppTheme.primary : const Color(0xFFD97706);
    final id = parseUserId(user['id']);

    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: avatarColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(
                child: Text(initials,
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: avatarColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isVerified ? AppTheme.primary : const Color(0xFFD97706)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              onSelected: (value) {
                switch (value) {
                  case 'verify':
                    onVerify(id);
                  case 'make_admin':
                    onChangeRole(id, 'admin');
                  case 'make_user':
                    onChangeRole(id, 'user');
                  case 'view':
                    onTap();
                  case 'reset_password':
                    onResetPassword(id, name);
                }
              },
              itemBuilder: (_) => [
                if (!isVerified)
                  const PopupMenuItem(
                      value: 'verify',
                      child: Row(children: [
                        Icon(Icons.verified_user, size: 16, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Verifikasi'),
                      ])),
                if (role != 'admin')
                  const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Jadikan Admin'),
                      ])),
                if (role == 'admin')
                  const PopupMenuItem(
                      value: 'make_user',
                      child: Row(children: [
                        Icon(Icons.person, size: 16, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Jadikan User'),
                      ])),
                const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('Lihat Detail'),
                    ])),
                const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(children: [
                      Icon(Icons.lock_reset, size: 16, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text('Reset Password'),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
