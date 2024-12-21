class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.avatarUrl,
  });

  final String id;

  final String username;

  final DateTime createdAt;

  final String avatarUrl;

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username'],
        createdAt = DateTime.parse(map['created_at']),
        avatarUrl = map['avatar_url'];
}
