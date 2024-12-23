class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.avatarUrl,
    required this.email,
  });

  final String id;

  final String username;

  final DateTime createdAt;

  final String avatarUrl;

  final String email;

  Profile copy({
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username'],
        createdAt = DateTime.parse(map['created_at']),
        avatarUrl = map['avatar_url'],
        email = map['email'];
}
