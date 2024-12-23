import 'package:flutter/material.dart';
import 'package:my_chat_app/controllers/chat_controller.dart';
import 'package:my_chat_app/models/message.dart';
import '../models/profile.dart';
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
  late final ChatController _controller;
  late final Stream<List<Message>> _messagesStream;
  String chatRoomName = '';
  String chatRoomAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _controller = ChatController(widget.roomId);
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = _controller.getMessagesStream(myUserId);
    _loadChatRoomName();
  }

  Future<void> _loadChatRoomName() async {
    final name = await _controller.loadChatRoomName();
    setState(() {
      chatRoomName = name;
    });
  }

  Future<void> _loadChatRoomAvatarUrl() async {
    final avatar_url = await _controller.loadChatRoomAvatarUrl();
    setState(() {
      chatRoomAvatarUrl = avatar_url;
    });
  }

  Future<void> _deleteChatRoom() async {
    Navigator.pop(context);
    Navigator.pop(context);
    await _controller.deleteChatRoom();
  }

  Future<void> _renameChatRoom() async {
    final TextEditingController roomNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat Room'),
        content: TextField(
          controller: roomNameController,
          decoration: const InputDecoration(
            hintText: 'Enter new room name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = roomNameController.text.trim();
              Navigator.pop(context);
              await _controller.renameChatRoom(newName);
              if (mounted) {
                setState(() {
                  chatRoomName = newName;
                });
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                right: 5,
              ),
              child: Container(
                alignment: Alignment.centerLeft,
                width: 50,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: chatRoomAvatarUrl.isNotEmpty
                      ? NetworkImage(chatRoomAvatarUrl)
                      : null,
                ),
              ),
            ),
            Text(chatRoomName.isEmpty ? 'Loading...' : chatRoomName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                builder: (context) => _buildDrawerContent(),
              );
            },
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
                            _controller.loadProfileCache(message.profileId);
                            return _ChatBubble(
                              message: message,
                              profile: _controller
                                  .getCachedProfile(message.profileId),
                              controller: _controller,
                            );
                          },
                        ),
                ),
                _MessageBar(
                  controller: _controller,
                  roomId: widget.roomId,
                ),
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }

  Widget _buildDrawerContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Chat Room'),
            onTap: () {
              Navigator.pop(context);
              _renameChatRoom();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Chat Room'),
            onTap: () {
              _deleteChatRoom();
            },
          ),
        ],
      ),
    );
  }
}

class _MessageBar extends StatefulWidget {
  final String roomId;

  const _MessageBar({required this.roomId, required controller});

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
                  child: const Icon(Icons.send)),
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
    await supabase.from('messages').insert({
      'profile_id': myUserId,
      'content': text,
      'chat_room_id': widget.roomId,
    });
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.profile,
    required this.controller,
  });

  final Message message;
  final Profile? profile;
  final ChatController controller;

  Future<void> _deleteMessage(BuildContext context) async {
    Navigator.pop(context);
    await supabase.from('messages').delete().eq('id', message.id);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('Are you sure to delete this message?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _deleteMessage(context),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isMine = message.profileId == currentUserId;

    // FutureBuilder để tải profile và hiển thị thông tin người dùng
    return FutureBuilder<Profile?>(
      future: controller.loadProfileCache(message.profileId),
      // Tải profile từ cache
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Nếu vẫn đang tải, hiển thị một placeholder hoặc loader
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMine)
                  const CircleAvatar(
                    child: CircularProgressIndicator(),
                  ),
                // Có thể thêm một loader nếu cần
              ],
            ),
          );
        } else if (snapshot.hasError) {
          // Nếu có lỗi khi tải, hiển thị một thông báo lỗi
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMine)
                  const CircleAvatar(
                    child: Icon(Icons.error),
                  ),
                const Text('Error loading profile'),
              ],
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // Nếu đã có profile, hiển thị avatar và thông tin
          final profile = snapshot.data!;

          List<Widget> chatContents = [
            if (!isMine)
              CircleAvatar(
                backgroundImage: profile.avatarUrl.isNotEmpty
                    ? NetworkImage(profile.avatarUrl)
                    : null,
                child: profile.avatarUrl.isEmpty
                    ? Text(
                        profile.username.substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isMine ? Colors.blue[500] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Text(
                        profile.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 16,
                        color: isMine ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.formatMessageTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isMine ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isMine)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => _showDeleteDialog(context),
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
        } else {
          // Nếu không có dữ liệu nào, hiển thị một placeholder
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMine)
                  const CircleAvatar(
                    child: Icon(Icons.error),
                  ),
                const Text('Profile not found'),
              ],
            ),
          );
        }
      },
    );
  }
}
