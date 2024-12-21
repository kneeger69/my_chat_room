import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  XFile? _pickedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _profile = Profile.fromMap(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_pickedImage == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload file to Supabase Storage
      final file = File(_pickedImage!.path);
      final filePath = 'avatars/$userId/${_pickedImage!.name}';
      await Supabase.instance.client.storage
          .from('images')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      // Get public URL for the uploaded image
      final publicURL = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(filePath);

      // Update avatar URL in `profiles` table
      await Supabase.instance.client.from('profiles').update({
        'avatar_url': publicURL,
      }).eq('id', userId);

      // Reload profile after updating
      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload avatar')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedImage =
    await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
      });
      await _uploadAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profile?.avatarUrl != null &&
                    _profile!.avatarUrl.isNotEmpty
                    ? NetworkImage(_profile!.avatarUrl)
                    : null,
                child: _profile?.avatarUrl == null ||
                    _profile!.avatarUrl.isEmpty
                    ? Text(
                  _profile?.username.substring(0, 2).toUpperCase() ?? '',
                  style: const TextStyle(fontSize: 30),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(_profile?.username ?? 'Unknown'),
              subtitle: const Text('Username'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(Supabase.instance.client.auth.currentUser?.email ??
                  'Unknown'),
              subtitle: const Text('Email'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _profile?.createdAt.toLocal().toString().split(' ')[0] ??
                    'Unknown',
              ),
              subtitle: const Text('Account Created'),
            ),
          ],
        ),
      ),
    );
  }
}
