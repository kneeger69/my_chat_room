class ChatRoom {
  final String id;
  final String name;
  final String avatarUrl;
  final DateTime createdAt;

  ChatRoom({
    required this.avatarUrl,
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      avatarUrl: map['avatar_url'],
    );
  }
}
