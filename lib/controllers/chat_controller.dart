import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/profile.dart';

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

  Future<void> loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
    await supabase.from('profiles').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    _profileCache[profileId] = profile;
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
}
