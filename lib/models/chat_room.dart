class ChatRoom {
  final String id;
  final String name;
  final String avatar_url;
  final DateTime createdAt;

  ChatRoom({
    required this.avatar_url,
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      avatar_url: map['avatar_url'],
    );
  }
}
