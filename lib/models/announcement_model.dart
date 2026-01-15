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
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String,
      priority: json['priority'] as String? ?? 'normal',
      targetAudience: json['target_audience'] != null
          ? List<String>.from(json['target_audience'])
          : null,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isSticky: json['is_sticky'] == 1 || json['is_sticky'] == true,
      allowComments: json['allow_comments'] == 1 || json['allow_comments'] == true,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      viewsCount: json['views_count'] as int? ?? 0,
      authorId: json['author_id'] as int?,
      status: json['status'] as String? ?? 'unpublished',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
