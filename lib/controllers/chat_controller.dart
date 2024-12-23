import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:timeago/timeago.dart';

import '../utils/constants.dart';

class ChatController {
  final String roomId;
  final Map<String, Profile> _profileCache = {};

  ChatController(this.roomId);

  Stream<List<Message>> getMessagesStream(String myUserId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', roomId)
        .order('created_at')
        .map((maps) =>
        maps.map((map) => Message.fromMap(map: map, myUserId: myUserId)).toList());
  }

  Future<String> loadChatRoomName() async {
    try {
      final data = await supabase
          .from('chat_rooms')
          .select('name')
          .eq('id', roomId)
          .single();
      return data['name'];
    } catch (e) {
      return 'Unknown Chat Room';
    }
  }

  Future<Profile?> loadProfileCache(String profileId) async {
    try {
      // Lấy dữ liệu profile từ Supabase
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', profileId)
          .single();

      // Chuyển dữ liệu từ Map sang đối tượng Profile
      return Profile.fromMap(profileData);
    } catch (e) {
      // Xử lý lỗi và trả về null nếu có lỗi
      print('Error loading profile: $e');
      return null;
    }
  }


  Profile? getCachedProfile(String profileId) {
    return _profileCache[profileId];
  }

  Future<void> submitMessage(String text, String myUserId) async {
    if (text.isEmpty) {
      return;
    }
    await supabase.from('messages').insert({
      'profile_id': myUserId,
      'content': text,
      'chat_room_id': roomId,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await supabase.from('messages').delete().eq('id', messageId);
  }

  Future<void> deleteChatRoom() async {
    await supabase.from('chat_rooms').delete().eq('id', roomId);
  }

  Future<void> renameChatRoom(String newName) async {
    if (newName.isEmpty) {
      throw Exception('Chat room name cannot be empty');
    }
    return supabase.from('chat_rooms').update({'name': newName}).eq('id', roomId);
  }

  String formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inHours < 24) {
      return format(messageTime, locale: 'en_short');
    } else {
      return "${messageTime.day.toString().padLeft(2, '0')}/"
          "${messageTime.month.toString().padLeft(2, '0')}/"
          "${messageTime.year}";
    }
  }
}
