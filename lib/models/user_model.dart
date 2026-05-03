class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? nik;
  final String? ktpPath;
  final String? ktpUrl;
  final String? rtNumber;
  final String? rwNumber;
  final String role;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isUserVerified;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.nik,
    this.ktpPath,
    this.ktpUrl,
    this.rtNumber,
    this.rwNumber,
    this.role = 'user',
    required this.roles,
    this.isEmailVerified = false,
    this.isUserVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      print('User.fromJson input: $json');
      // Handle nested user object (e.g., {user: {...}})
      final userData = json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;
      print('userData after check: $userData');
      print('userData role: ${userData['role']}');
      
      // Safe int parsing for id
      int userId;
      if (userData['id'] is int) {
        userId = userData['id'] as int;
      } else if (userData['id'] is String) {
        userId = int.parse(userData['id']);
      } else {
        throw Exception('Invalid user id: ${userData['id']}');
      }

      return User(
        id: userId,
        name: userData['name']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        phone: userData['phone']?.toString(),
        address: userData['address']?.toString(),
        nik: userData['nik']?.toString(),
        ktpPath: userData['ktp_path']?.toString(),
        ktpUrl: userData['ktp_url']?.toString(),
        rtNumber: (userData['rt_number'] ?? userData['rt'])?.toString(),
        rwNumber: (userData['rw_number'] ?? userData['rw'])?.toString(),
        role: userData['role']?.toString() ?? 'user',
        roles: userData['roles'] != null 
            ? (userData['roles'] is List 
                ? List<String>.from(userData['roles'].map((role) => 
                    role is String ? role : (role['name']?.toString() ?? 'user')))
                : [userData['role']?.toString() ?? 'user'])
            : [userData['role']?.toString() ?? 'user'],
        isEmailVerified: userData['email_verified_at'] != null,
        isUserVerified: userData['is_verified'] == 1 || userData['is_verified'] == true,
        isActive: userData['is_active'] == 1 || userData['is_active'] == true || userData['is_active'] == null,
        createdAt: userData['created_at'] != null 
            ? (DateTime.tryParse(userData['created_at'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing User from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'nik': nik,
      'ktp_path': ktpPath,
      'ktp_url': ktpUrl,
      'rt_number': rtNumber,
      'rw_number': rwNumber,
      'role': role,
      'roles': roles,
      'is_email_verified': isEmailVerified,
      'is_user_verified': isUserVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => roles.contains('admin');
  bool get isUser => roles.contains('user');
}
