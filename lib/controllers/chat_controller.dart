import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';

import '../utils/constants.dart';

class ChatController {
  final String roomId;
  final Map<String, Profile> _profileCache = {};
  final BuildContext context;
  final ImagePicker _imagePicker = ImagePicker();

  ChatController(this.roomId, this.context);

  Stream<List<Message>> getMessagesStream(String myUserId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => Message.fromMap(map: map, myUserId: myUserId)).toList());
  }

  Future<void> sendMessage(String content, String userId) async {
    if (content.isEmpty) return;
      await Supabase.instance.client.from('messages').insert({
        'profile_id': userId,
        'content': content,
        'chat_room_id': roomId,
      });
  }

  Future<String> loadChatRoomName() async {
      final data = await supabase
          .from('chat_rooms')
          .select('name')
          .eq('id', roomId)
          .single();
      return data['name'];
  }

  Future<String> loadChatRoomAvatarUrl() async {
      final data = await supabase
          .from('chat_rooms')
          .select('avatar_url')
          .eq('id', roomId)
          .single();
      return data['avatar_url'];
  }

  Stream<Profile?> loadProfileCache(String profileId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', profileId)
        .map((maps) => maps.isNotEmpty ? Profile.fromMap(maps.first) : null);
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
    await supabase.from('chat_rooms').update({'name': newName}).eq('id', roomId);
  }


  Future<void> updateChatAvatar(String chatRoomId) async {
    // Chọn ảnh từ gallery
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    // Hiển thị trạng thái đang tải
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating chat room avatar...')),
    );

    final file = File(pickedImage.path);
    final filePath = 'chat_avatars/$chatRoomId/${pickedImage.name}';

    // Upload ảnh lên Supabase Storage
    await Supabase.instance.client.storage
        .from('images')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    // Lấy URL công khai của ảnh
    final publicURL = Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(filePath);

    // Cập nhật URL avatar trong cơ sở dữ liệu
    await Supabase.instance.client.from('chat_rooms').update({
      'avatar_url': publicURL,
    }).eq('id', chatRoomId);

    // Thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar updated successfully!')),
    );
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
