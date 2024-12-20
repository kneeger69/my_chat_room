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
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Navigator.of(context).pushAndRemoveUntil(
        ChatRoomListPage.route(),
            (route) => false,
      );
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  Future<void> signUp(
      BuildContext context,
      String email,
      String password,
      String username,
      ) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      Navigator.of(context).pushAndRemoveUntil(
        ChatRoomListPage.route(),
            (route) => false,
      );
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (error) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}
