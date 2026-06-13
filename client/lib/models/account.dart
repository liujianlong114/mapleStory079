class Account {
  final int id;
  final String username;
  final String? email;
  final int status;
  final DateTime? createdAt;
  final String? token;

  Account({
    required this.id,
    required this.username,
    this.email,
    required this.status,
    this.createdAt,
    this.token,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      status: json['status'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'status': status,
      'token': token,
    };
  }
}
