DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  // Handle Laravel/PHP style date objects: { date: "...", timezone: "..." }
  if (value is Map<String, dynamic> && value['date'] != null) {
    return DateTime.parse(value['date'].toString());
  }

  // Fallback: try to parse any other representation to string
  return DateTime.tryParse(value.toString());
}

class Announcement {
  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String content;
  final String priority;
  final String? coverImage;
  final List<String>? targetAudience;
  final List<String>? attachments;
  final List<AnnouncementAttachment>? attachmentItems;
  final bool isActive;
  final bool isSticky;
  final bool allowComments;
  final DateTime? publishedAt;
  final int viewsCount;
  final int? authorId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    required this.content,
    required this.priority,
    this.coverImage,
    this.targetAudience,
    this.attachments,
    this.attachmentItems,
    this.isActive = true,
    this.isSticky = false,
    this.allowComments = true,
    this.publishedAt,
    this.viewsCount = 0,
    this.authorId,
    this.status = 'unpublished',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Normalize attachments into display-ready items while keeping the old
    // string URL list for existing screens.
    List<String>? attachments;
    List<AnnouncementAttachment>? attachmentItems;
    if (json['attachments'] != null && json['attachments'] is List) {
      attachmentItems = (json['attachments'] as List)
          .map((item) => AnnouncementAttachment.fromJson(item))
          .where((item) => item.url.isNotEmpty)
          .toList();
      attachments = attachmentItems.map((item) => item.url).toList();
    }

    // Normalize target audience into list of strings as well
    List<String>? targetAudience;
    if (json['target_audience'] != null && json['target_audience'] is List) {
      targetAudience = (json['target_audience'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return Announcement(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      summary: json['summary'] as String?,
      content: json['content']?.toString() ?? '',
      priority: json['priority'] as String? ?? 'medium',
      coverImage: json['cover_image'] as String? ?? json['image_url'] as String? ?? json['image'] as String?,
      targetAudience: targetAudience,
      attachments: attachments,
      attachmentItems: attachmentItems,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isSticky: json['is_sticky'] == 1 || json['is_sticky'] == true,
      allowComments: json['allow_comments'] == 1 || json['allow_comments'] == true,
      publishedAt: _parseDate(json['published_at']),
      viewsCount: json['views_count'] as int? ?? 0,
      authorId: json['author_id'] as int?,
      status: json['status'] as String? ?? 'unpublished',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'summary': summary,
      'content': content,
      'priority': priority,
      'cover_image': coverImage,
      'target_audience': targetAudience,
      'attachments': attachments,
      'is_active': isActive,
      'is_sticky': isSticky,
      'allow_comments': allowComments,
      'published_at': publishedAt?.toIso8601String(),
      'views_count': viewsCount,
      'author_id': authorId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPublished => status == 'published';
  bool get isUrgent => priority == 'urgent' || priority == 'high';
}

class AnnouncementAttachment {
  final String name;
  final String url;

  const AnnouncementAttachment({
    required this.name,
    required this.url,
  });

  factory AnnouncementAttachment.fromJson(dynamic value) {
    if (value is String) {
      return AnnouncementAttachment(
        name: _fileNameFromUrl(value),
        url: value,
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final url = map['file_url']?.toString() ??
          map['secure_url']?.toString() ??
          map['download_url']?.toString() ??
          map['url']?.toString() ??
          map['file_path']?.toString() ??
          map['path']?.toString() ??
          '';
      final name = map['original_name']?.toString() ??
          map['file_name']?.toString() ??
          map['filename']?.toString() ??
          map['name']?.toString() ??
          map['title']?.toString() ??
          _fileNameFromUrl(url);

      return AnnouncementAttachment(name: name, url: url);
    }

    final fallback = value.toString();
    return AnnouncementAttachment(
      name: _fileNameFromUrl(fallback),
      url: fallback,
    );
  }
}

String _fileNameFromUrl(String value) {
  final uri = Uri.tryParse(value);
  final path = uri?.path ?? value;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final name = parts.isEmpty ? '' : parts.last;
  return name.isEmpty ? 'Lampiran' : name;
}
