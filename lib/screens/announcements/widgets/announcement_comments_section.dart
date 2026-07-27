import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/comment_model.dart';
import '../../../theme/app_theme.dart';

class AnnouncementCommentsSection extends StatelessWidget {
  final List<Comment> comments;
  final bool isLoading;

  const AnnouncementCommentsSection({
    super.key,
    required this.comments,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Komentar',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Belum ada komentar',
                        style: GoogleFonts.nunito(
                            fontSize: 14, color: const Color(0xFF9CA3AF))),
                    const SizedBox(height: 4),
                    Text('Jadilah yang pertama berkomentar!',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, index) => _CommentItem(comment: comments[index]),
            ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primary,
          child: Text(
            comment.userName.substring(0, 1).toUpperCase(),
            style: GoogleFonts.nunito(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(comment.userName,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937))),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(comment.createdAt),
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(comment.content,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class AnnouncementCommentInput extends StatelessWidget {
  final bool isVerified;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const AnnouncementCommentInput({
    super.key,
    required this.isVerified,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBEB),
          border: Border(top: BorderSide(color: Color(0xFFFCD34D))),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verifikasi akun diperlukan untuk berkomentar.',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: const Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                hintStyle: GoogleFonts.nunito(color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.nunito(
                  fontSize: 14, color: const Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
