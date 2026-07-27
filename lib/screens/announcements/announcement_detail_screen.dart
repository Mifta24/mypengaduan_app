import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/announcement_model.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/announcement_service.dart';
import '../../services/file_download_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/announcement_detail_widgets.dart';
import 'widgets/announcement_comments_section.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;
  const AnnouncementDetailScreen({super.key, required this.announcement});

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
  bool _hasLoadedComments = false;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _syncBookmarkState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool forceRefresh = false}) async {
    if (!widget.announcement.allowComments) return;
    if (_hasLoadedComments && !forceRefresh) return;

    setState(() => _isLoadingComments = true);
    try {
      final comments =
          await _announcementService.getComments(widget.announcement.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
        _hasLoadedComments = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingComments = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat komentar: $e')));
    }
  }

  Future<void> _syncBookmarkState() async {
    try {
      final bookmarked =
          await _announcementService.getBookmarkedAnnouncements();
      if (!mounted) return;
      setState(() => _isBookmarked =
          bookmarked.any((b) => b.id == widget.announcement.id));
    } catch (_) {}
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isBookmarked
            ? 'Pengumuman disimpan'
            : 'Pengumuman dihapus dari simpanan'),
        backgroundColor: AppTheme.success,
      ));
      return;
    }
    setState(() => _isBookmarked = previous);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Gagal: ${response.message}')));
  }

  Future<void> _shareAnnouncement() async {
    try {
      final text =
          '${widget.announcement.title}\n\n${widget.announcement.content}\n\nDibagikan dari MyPengaduan';
      try {
        await Share.share(text, subject: widget.announcement.title);
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Teks disalin ke clipboard!'),
            backgroundColor: AppTheme.success,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _downloadAttachment(String url, String fileName) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL lampiran tidak tersedia')));
      }
      return;
    }
    try {
      await _fileDownloadService.downloadToDownloads(
          url: url, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File tersimpan di Downloads: $fileName')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunduh lampiran: $e')));
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar tidak boleh kosong')));
      return;
    }
    if (content.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar minimal 3 karakter')));
      return;
    }

    setState(() => _isSubmittingComment = true);
    try {
      final response = await _announcementService.addComment(
          widget.announcement.id, content);
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      if (response.success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Komentar berhasil dikirim!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ));
        _loadComments(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: ${response.message}'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child:
                    CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
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
    final isVerified =
        context.watch<AuthProvider>().user?.isUserVerified ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Detail Pengumuman',
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
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
                    AnnouncementHeaderCard(announcement: widget.announcement),
                    const SizedBox(height: 16),
                    AnnouncementContentCard(
                      announcement: widget.announcement,
                      onShowFullImage: _showFullImage,
                      onDownloadAttachment: _downloadAttachment,
                    ),
                    const SizedBox(height: 16),
                    AnnouncementActionButtons(
                      isBookmarked: _isBookmarked,
                      isBookmarkLoading: _isBookmarkLoading,
                      onShare: _shareAnnouncement,
                      onToggleBookmark: _toggleBookmark,
                    ),
                    const SizedBox(height: 24),
                    if (widget.announcement.allowComments)
                      AnnouncementCommentsSection(
                        comments: _comments,
                        isLoading: _isLoadingComments,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.announcement.allowComments)
            AnnouncementCommentInput(
              isVerified: isVerified,
              controller: _commentController,
              isSubmitting: _isSubmittingComment,
              onSubmit: _submitComment,
            ),
        ],
      ),
    );
  }
}
