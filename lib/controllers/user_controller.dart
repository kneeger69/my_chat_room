// user_controller.dart
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class UserController {
  final SupabaseClient _client;
  final ImagePicker _imagePicker;

  UserController(this._client) : _imagePicker = ImagePicker();

  Future<Profile?> loadUserProfile() async {
      final user = _client.auth.currentUser;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user?.id)
          .single();
      return Profile.fromMap(response);
  }

  Future<XFile?> pickImage() async {
    return await _imagePicker.pickImage(source: ImageSource.gallery);
  }
  Future<void> uploadAvatar(XFile pickedImage) async {
      final userId = _client.auth.currentUser?.id;
      final file = File(pickedImage.path);
      final filePath = 'avatars/$userId/${pickedImage.name}';

      await _client.storage
          .from('images')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));
      final publicURL = _client.storage.from('images').getPublicUrl(filePath);
      await _client
          .from('profiles')
          .update({'avatar_url': publicURL})
          .eq('id', userId);
  }


  Future<void> updateProfile(String userId, String username) async {
      await _client
          .from('profiles')
          .update({'username': username})
          .eq('id', userId);
  }
}
