class UserModel {
  final String id;
  final String name;
  final String email;
  final String image;
  final String role; // "user", "seller", "admin"

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      image: map['image']?.toString() ?? map['avatar']?.toString() ?? '',
      role:
          (map['role'] ??
                  (map['roles'] is List && map['roles'].isNotEmpty
                      ? map['roles'][0]
                      : ''))
              .toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'role': role,
    };
  }
}
