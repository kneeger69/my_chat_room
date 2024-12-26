// user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/user_controller.dart';
import '../models/profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final UserController _userController;
  late Profile _profile;
  bool _isLoading = true;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _userController = UserController(Supabase.instance.client);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userController.loadUserProfile();
      setState(() => _profile = profile!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    if (_pickedImage == null) return;

    setState(() => _isLoading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully!')),
      );
      await _userController.uploadAvatar(_pickedImage!);
      await _loadUserProfile();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _userController.pickImage();
      setState(() => _pickedImage = pickedImage);
      await _uploadAvatar();
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController(text: _profile.username);
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 18),
              const TextField(
                decoration: InputDecoration(labelText: 'Email'),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final userId = _profile.id;
                await _userController.updateProfile(
                  userId,
                  usernameController.text.trim()
                );
                await _loadUserProfile();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                backgroundImage:NetworkImage(_profile.avatarUrl),
                child: _profile.avatarUrl.isEmpty
                  ? Text(
                      _profile.username.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontSize: 30),
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              subtitle: const Text('User name'),
              title: Text(_profile.username),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              subtitle: const Text('Email'),
              title: Text(_profile.email),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              subtitle: const Text('Account created'),
              title: Text(
                _profile.createdAt.toLocal().toString().split(' ')[0],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editProfile,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
