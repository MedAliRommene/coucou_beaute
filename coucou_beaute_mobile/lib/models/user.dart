class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.createdAt,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      createdAt: DateTime.parse(json['date_joined']),
      isActive: json['is_active'] ?? true,
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': createdAt.toIso8601String(),
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }
}
