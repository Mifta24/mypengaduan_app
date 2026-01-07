class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isUserVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.roles,
    this.isEmailVerified = false,
    this.isUserVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      roles: json['roles'] != null 
          ? List<String>.from(json['roles'].map((role) => role['name']))
          : [],
      isEmailVerified: json['email_verified_at'] != null,
      isUserVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'roles': roles,
      'is_email_verified': isEmailVerified,
      'is_user_verified': isUserVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => roles.contains('admin');
  bool get isUser => roles.contains('user');
}
