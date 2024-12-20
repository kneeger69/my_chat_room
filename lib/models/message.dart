class Message {
  Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.isMine,
    required this.chatRoomId,
  });

  final String id;
  final String profileId;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final String chatRoomId;

  Message.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  })  : id = map['id'],
        profileId = map['profile_id'],
        content = map['content'],
        createdAt = DateTime.parse(map['created_at']),
        isMine = myUserId == map['profile_id'],
        chatRoomId = map['chat_room_id'];
}
