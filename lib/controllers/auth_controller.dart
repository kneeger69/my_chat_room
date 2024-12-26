import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/list_chat_room_page.dart';
import '../utils/constants.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
    ) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    Navigator.of(context).pushAndRemoveUntil(
      ChatRoomListPage.route(),
          (route) => false,
    );
  }

  Future<void> signUp(
    BuildContext context,
    String email,
    String password,
    String username,
    ) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'email' : email},
    );
    Navigator.of(context).pushAndRemoveUntil(
      ChatRoomListPage.route(),
          (route) => false,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

}
