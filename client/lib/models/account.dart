class Account {
  final int id;
  final String username;
  final String? email;
  final int gender; // 10=未设置 0=男 1=女
  final int status;
  final DateTime? createdAt;
  final String? token;

  static const genderUnset = 10;

  Account({
    required this.id,
    required this.username,
    this.email,
    this.gender = genderUnset,
    required this.status,
    this.createdAt,
    this.token,
  });

  bool get needsGender => gender == genderUnset;

  factory Account.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int d = 0]) {
      if (v == null) return d;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? d;
    }
    return Account(
      id: asInt(json['id']),
      username: json['username'] ?? '',
      email: json['email'],
      gender: asInt(json['gender'], genderUnset),
      status: asInt(json['status'], 1),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      token: json['token'] as String?,
    );
  }

  Account copyWith({int? gender, String? token}) => Account(
        id: id,
        username: username,
        email: email,
        gender: gender ?? this.gender,
        status: status,
        createdAt: createdAt,
        token: token ?? this.token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'gender': gender,
        'status': status,
        'token': token,
      };
}
