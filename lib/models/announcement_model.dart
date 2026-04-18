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
  final List<String>? targetAudience;
  final List<String>? attachments;
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
    this.targetAudience,
    this.attachments,
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
    // Normalize attachments into a list of strings (e.g. URLs or filenames)
    List<String>? attachments;
    if (json['attachments'] != null && json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((item) {
            if (item is String) return item;
            if (item is Map<String, dynamic>) {
              // Try common keys that might store a file path or URL
              return item['file_url']?.toString() ??
                  item['file_path']?.toString() ??
                  item['url']?.toString() ??
                  item['path']?.toString() ??
                  item['name']?.toString() ??
                  item.toString();
            }
            return item.toString();
          })
          .toList();
    }

    // Normalize target audience into list of strings as well
    List<String>? targetAudience;
    if (json['target_audience'] != null && json['target_audience'] is List) {
      targetAudience = (json['target_audience'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String,
      priority: json['priority'] as String? ?? 'medium',
      targetAudience: targetAudience,
      attachments: attachments,
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
