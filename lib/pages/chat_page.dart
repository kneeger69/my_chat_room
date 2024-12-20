import 'package:flutter/material.dart';
import 'package:my_chat_app/pages/login_page.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';
import '../utils/constants.dart';

class ChatPage extends StatefulWidget {
  final String roomId;

  const ChatPage({super.key, required this.roomId});

  static Route<void> route(String roomId) {
    return MaterialPageRoute(
      builder: (context) => ChatPage(roomId: roomId),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};
  String chatRoomName = '';

  @override
  void initState() {
    super.initState();
    final myUserId = supabase.auth.currentUser!.id; // Get the current user ID
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', widget.roomId)
        .order('created_at')
        .map((maps) =>
        maps
            .map((map) =>
            Message.fromMap(map: map, myUserId: myUserId)) // Pass myUserId here
            .toList());
    _loadChatRoomName();
  }

  Future<void> _loadChatRoomName() async {
    try {
      final data = await supabase
          .from('chat_rooms')
          .select('name')
          .eq('id', widget.roomId)
          .single();

      setState(() {
        chatRoomName = data['name'];
      });
    } catch (e) {
      // Xử lý lỗi nếu không thể lấy tên chat room
      setState(() {
        chatRoomName = 'Unknown Chat Room';
      });
    }
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
    await supabase.from('profiles').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  // Thực hiện đăng xuất
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut(); // Đăng xuất người dùng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (
            context) => const LoginPage()), // Chuyển về màn hình đăng nhập
      );
    } catch (e) {
      // Xử lý lỗi nếu có
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatRoomName.isEmpty ? 'Loading...' : chatRoomName),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut, // Gọi phương thức đăng xuất
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                    child: Text('Start your conversation now :)'),
                  )
                      : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      _loadProfileCache(message.profileId);
                      return _ChatBubble(
                        message: message,
                        profile: _profileCache[message.profileId],
                      );
                    },
                  ),
                ),
                _MessageBar(roomId: widget.roomId), // Pass roomId here
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }
}

class _MessageBar extends StatefulWidget {
  final String roomId;  // Add roomId as a parameter

  const _MessageBar({super.key, required this.roomId});

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
        'chat_room_id': widget.roomId, // Use roomId passed from ChatPage
      });
    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  Future<void> _deleteMessage(BuildContext context) async {
    try {
      // Xóa tin nhắn khỏi bảng messages
      await supabase.from('messages').delete().eq('id', message.id);
      Navigator.pop(context); // Đóng modal sau khi xóa
    } catch (e) {
      context.showErrorSnackBar(message: 'Error deleting message');
    }
  }

  void _showDeleteDialog(BuildContext context) {
    // Hiển thị modal xác nhận xóa tin nhắn
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('Are you sure to delete this message?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context), // Đóng modal mà không làm gì
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => _deleteMessage(context), // Gọi phương thức xóa tin nhắn
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Xác định người dùng hiện tại
    final currentUserId = supabase.auth.currentUser?.id;

    // Kiểm tra xem tin nhắn có phải của người dùng hiện tại không
    final isMine = message.profileId == currentUserId;

    List<Widget> chatContents = [
      if (!isMine) // Nếu không phải là người dùng hiện tại, hiển thị avatar và username
        CircleAvatar(
          child: profile == null
              ? preloader
              : Text(profile!.username.substring(0, 2)),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: isMine
                ? Colors.blue[500]
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine) // Chỉ hiển thị username khi tin nhắn không phải của người dùng hiện tại
                Text(
                  profile?.username ?? 'Loading...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              Text(message.content, style: TextStyle(fontSize: 16,
                  color: isMine ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4), // Khoảng cách giữa tin nhắn và thời gian
              if(!isMine)
                Text(
                  format(message.createdAt, locale: 'en_short'),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if(isMine)
                Text(
                    format(message.createdAt, locale: 'en_short'),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      if (isMine) // Nếu tin nhắn thuộc về người dùng hiện tại, hiển thị biểu tượng 3 chấm
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () => _showDeleteDialog(context), // Hiển thị modal xác nhận xóa
        ),
    ];

    if (isMine) {
      chatContents = chatContents.reversed.toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}


