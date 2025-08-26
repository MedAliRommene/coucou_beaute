import 'user.dart';

class Client {
  final int id;
  final User user;
  final String? phoneNumber;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.user,
    this.phoneNumber,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      user: User.fromJson(json['user']),
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
