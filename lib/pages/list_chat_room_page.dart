import 'package:flutter/material.dart';
import 'package:my_chat_app/pages/chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

class ChatRoomListPage extends StatefulWidget {
  const ChatRoomListPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ChatRoomListPage());
  }

  @override
  _ChatRoomListPageState createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  late final Stream<List<Map<String, dynamic>>> _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    _chatRoomsStream = supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Rooms')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final rooms = snapshot.data!;
            if (rooms.isEmpty) {
              return const Center(child: Text('No chat rooms available.'));
            }
            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  title: Text(room['name'] ?? 'Unnamed Room'),
                  onTap: () {
                    // Navigate to the selected room
                    final roomId = room['id'];
                    Navigator.push(
                      context,
                      ChatPage.route(roomId),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
