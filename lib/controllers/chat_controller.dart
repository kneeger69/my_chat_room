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
  final Map<String, Profile> _profile = {};
  final BuildContext context;
  final ImagePicker _imagePicker = ImagePicker();

  ChatController(this.roomId, this.context);

  Stream<List<Message>> getMessagesStream(String myUserId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', roomId)
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

  Future<void> createChatRoom(String roomName) async{
    await supabase.from('chat_rooms').insert({'name': roomName});
  }

  Future<String> loadChatRoomName() async {
      final data = await supabase
          .from('chat_rooms')
          .select('name')
          .eq('id', roomId)
          .single();
      return data['name'];
  }

  Future<String> loadChatRoomAvatar() async {
      final data = await supabase
          .from('chat_rooms')
          .select('avatar_url')
          .eq('id', roomId)
          .single();
      return data['avatar_url'];
  }

  Stream<Profile?> loadProfile(String profileId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', profileId)
        .map((maps) => maps.isNotEmpty ? Profile.fromMap(maps.first) : null);
  }


  Profile? getProfile(String profileId) {
    return _profile[profileId];
  }


  Future<void> deleteMessage(String messageId) async {
    await supabase
        .from('messages')
        .delete()
        .eq('id', messageId);
  }

  Future<void> deleteChatRoom() async {
    await supabase
        .from('chat_rooms')
        .delete()
        .eq('id', roomId);
  }

  Future<void> renameChatRoom(String newName) async {
    await supabase
        .from('chat_rooms')
        .update({'name': newName})
        .eq('id', roomId);
  }


  Future<void> updateChatAvatar(String chatRoomId) async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    final file = File(pickedImage!.path);
    final filePath = 'chat_avatars/$chatRoomId/${pickedImage.name}';

    await Supabase.instance.client.storage
        .from('images')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));
    final publicURL = Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(filePath);
    await Supabase.instance.client
        .from('chat_rooms')
        .update({'avatar_url': publicURL})
        .eq('id', chatRoomId);
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
