class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final double balance;
  final DateTime createdAt;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.balance,
    required this.createdAt,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle backend response format (based on actual response)
    String userId =
        json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    DateTime createdDate;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdDate = DateTime.parse(json['createdAt']);
      } else {
        createdDate = DateTime.now();
      }
    } else {
      createdDate = DateTime.now();
    }

    return User(
      id: userId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      balance: (json['balance'] ?? 0.0)
          .toDouble(), // Default to 0 since backend doesn't return this
      createdAt: createdDate,
      isVerified:
          json['isVerified'] ??
          false, // Default to false since backend doesn't return this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    double? balance,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
