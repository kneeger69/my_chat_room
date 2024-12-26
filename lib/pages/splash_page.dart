import 'package:flutter/material.dart';
import 'package:my_chat_app/pages/login_page.dart';
import 'package:my_chat_app/utils/constants.dart';

import 'list_chat_room_page.dart';

/// Page to redirect users to the appropriate page depending on the initial auth state
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    final session = supabase.auth.currentSession;
    if (!mounted) return;
    if (session == null) {
      Navigator.of(context).pushAndRemoveUntil(LoginPage.route(), (route) => false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(ChatRoomListPage.route(), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: loading);
  }
}

