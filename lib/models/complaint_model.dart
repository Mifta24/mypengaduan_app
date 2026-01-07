class Complaint {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final String description;
  final String location;
  final String status;
  final DateTime reportDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;
  final List<Attachment>? attachments;

  Complaint({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.reportDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.attachments,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] != null 
          ? Category.fromJson(json['category']) 
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((item) => Attachment.fromJson(item))
              .toList()
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class Attachment {
  final int id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;

  Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
    );
  }

  String get fileUrl => filePath;
}
