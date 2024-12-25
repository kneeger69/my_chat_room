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
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return Profile.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadAvatar(XFile pickedImage) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final file = File(pickedImage.path);
      final filePath = 'avatars/$userId/${pickedImage.name}';
      await _client.storage
          .from('images')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final publicURL = _client.storage.from('images').getPublicUrl(filePath);

      await _client.from('profiles').update({'avatar_url': publicURL}).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<XFile?> pickImage() async {
    return await _imagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<void> updateProfile(String userId, String username, String email) async {
    try {
      await _client.from('profiles').update({
        'username': username,
        'email': email,
      }).eq('id', userId);

      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        await _client.auth.updateUser(
          UserAttributes(email: email),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
