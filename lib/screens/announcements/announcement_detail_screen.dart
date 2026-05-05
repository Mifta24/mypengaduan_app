import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/announcement_model.dart';
import '../../models/comment_model.dart';
import '../../services/announcement_service.dart';
import '../../services/file_download_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final FileDownloadService _fileDownloadService = FileDownloadService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  bool _hasLoadedComments = false; // Track if comments already loaded
  List<Comment> _comments = [];

  List<AnnouncementAttachment> get _announcementAttachments {
    final structured = widget.announcement.attachmentItems;
    if (structured != null && structured.isNotEmpty) return structured;

    return (widget.announcement.attachments ?? [])
        .map((url) => AnnouncementAttachment.fromJson(url))
        .where((item) => item.url.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _syncBookmarkState();
    // Load comments once on init
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  Future<void> _downloadAttachment(String url, String fileName) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL lampiran tidak tersedia')),
        );
      }
      return;
    }

    try {
      await _fileDownloadService.downloadToDownloads(
        url: url,
        fileName: fileName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File tersimpan di Downloads: $fileName')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh lampiran: $e')),
        );
      }
    }
  }

  Future<void> _loadComments({bool forceRefresh = false}) async {
    if (!widget.announcement.allowComments) return;

    // Skip if already loaded and not forcing refresh
    if (_hasLoadedComments && !forceRefresh) return;

    setState(() => _isLoadingComments = true);

    try {
      final comments =
          await _announcementService.getComments(widget.announcement.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
        _hasLoadedComments = true;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat komentar: $e')),
        );
      }
    }
  }

  Future<void> _syncBookmarkState() async {
    try {
      final bookmarked =
          await _announcementService.getBookmarkedAnnouncements();
      if (!mounted) return;

      final isBookmarked =
          bookmarked.any((item) => item.id == widget.announcement.id);
      setState(() => _isBookmarked = isBookmarked);
    } catch (_) {
      // Ignore bookmark sync failure and keep default local state.
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    final previous = _isBookmarked;
    setState(() {
      _isBookmarkLoading = true;
      _isBookmarked = !_isBookmarked;
    });

    final response =
        await _announcementService.toggleBookmark(widget.announcement.id);

    if (!mounted) return;

    setState(() => _isBookmarkLoading = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Pengumuman disimpan'
                : 'Pengumuman dihapus dari simpanan',
          ),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() => _isBookmarked = previous);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: ${response.message}')),
    );
  }

  Future<void> _shareAnnouncement() async {
    try {
      final text =
          '${widget.announcement.title}\n\n${widget.announcement.content}\n\nDibagikan dari MyPengaduan';

      try {
        await Share.share(text, subject: widget.announcement.title);
      } catch (e) {
        // Fallback: Copy to clipboard if share fails (mobile plugin issue)
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teks disalin ke clipboard!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    if (content.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar minimal 3 karakter')),
      );
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final response = await _announcementService.addComment(
        widget.announcement.id,
        content,
      );

      setState(() => _isSubmittingComment = false);

      if (mounted) {
        if (response.success) {
          _commentController.clear();
          // Hide keyboard
          FocusScope.of(context).unfocus();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Komentar berhasil dikirim!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Reload comments to show the new one
          _loadComments(forceRefresh: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmittingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Detail Pengumuman',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadComments(forceRefresh: true),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),

                    const SizedBox(height: 16),

                    // Content Card
                    _buildContentCard(),

                    const SizedBox(height: 16),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 24),

                    // Comments Section
                    if (widget.announcement.allowComments) ...[
                      _buildCommentsSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Comment Input (sticky at bottom)
          if (widget.announcement.allowComments) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getPriorityGradient(widget.announcement.priority),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getPriorityColor(widget.announcement.priority)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority Badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.priority_high,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPriorityText(widget.announcement.priority),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Views count
              Row(
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.announcement.viewsCount} kali dilihat',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            widget.announcement.title,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Metadata
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetadataItem(
                Icons.person,
                'Admin',
                Colors.white70,
              ),
              _buildMetadataItem(
                Icons.calendar_today,
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                  widget.announcement.publishedAt ??
                      widget.announcement.createdAt,
                ),
                Colors.white70,
              ),
              if (widget.announcement.updatedAt !=
                  widget.announcement.createdAt)
                _buildMetadataItem(
                  Icons.update,
                  'Diperbarui ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.announcement.updatedAt)}',
                  Colors.white70,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Target Audience
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Ditujukan untuk:',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.announcement.targetAudience?.join(', ') ??
                      'Semua Warga',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary if available
          if (widget.announcement.summary != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                widget.announcement.summary!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content
          Text(
            widget.announcement.content,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF374151),
              height: 1.7,
            ),
          ),

          // Attachments if available
          if (_announcementAttachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Lampiran:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            ..._announcementAttachments.map((attachment) {
              final url = attachment.url;
              final isImage = _isImageUrl(url);
              final fileName = attachment.name;

              if (isImage) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () => _showFullImage(url),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, _) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary),
                                  ),
                                ),
                              ),
                              errorWidget: (context, _, __) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.broken_image,
                                    color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.image,
                                size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
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

              // Non-image files: show as downloadable row
              return InkWell(
                onTap: () => _downloadAttachment(url, fileName),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                      const Icon(Icons.download,
                          size: 20, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Share Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareAnnouncement,
              icon: const Icon(Icons.share, size: 20),
              label: Text(
                'Bagikan Pengumuman',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bookmark Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isBookmarkLoading ? null : _toggleBookmark,
              icon: _isBookmarkLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                    ),
              label: Text(
                'Simpan',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBookmarked
                    ? AppTheme.primary
                    : const Color(0xFFF3F4F6),
                foregroundColor:
                    _isBookmarked ? Colors.white : const Color(0xFF374151),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Komentar',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingComments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama berkomentar!',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentItem(comment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primary,
          child: Text(
            comment.userName.substring(0, 1).toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(comment.createdAt),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              controller: _commentController,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                hintStyle: GoogleFonts.nunito(
                  color: const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmittingComment ? null : _submitComment,
            icon: _isSubmittingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Mendesak';
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      default:
        return 'Sedang';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return const Color(0xFF0891B2);
      case 'low':
        return AppTheme.primary;
      default:
        return AppTheme.primary;
    }
  }

  List<Color> _getPriorityGradient(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return [const Color(0xFFDC2626), const Color(0xFFB91C1C)];
      case 'high':
        return [const Color(0xFFEA580C), const Color(0xFFC2410C)];
      case 'medium':
        return [const Color(0xFF0891B2), const Color(0xFF15803D)];
      case 'low':
        return [AppTheme.primary, const Color(0xFF15803D)];
      default:
        return [AppTheme.primary, AppTheme.secondary];
    }
  }
}
