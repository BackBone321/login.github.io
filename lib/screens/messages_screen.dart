import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Friends Section
          StreamBuilder<List<String>>(
            stream: _dbService.getFriends(_auth.currentUser!.uid),
            builder: (context, friendsSnapshot) {
              if (friendsSnapshot.hasData && friendsSnapshot.data!.isNotEmpty) {
                return Container(
                  height: 120,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Your Friends',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: friendsSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            final friendId = friendsSnapshot.data![index];
                            return FutureBuilder<UserModel?>(
                              future: _dbService.getUser(friendId),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return SizedBox.shrink();
                                }
                                return _buildFriendChip(userSnapshot.data!);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          Divider(),
          // Conversations Section
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.getConversations(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, size: 64, color: darkGreen.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: darkGreen),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with your friends',
                          style: TextStyle(
                            color: darkGreen.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final conversation = snapshot.data![index];
                    return _buildConversationCard(conversation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendChip(UserModel user) {
    final darkGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(otherUser: user),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: darkGreen,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                user.displayName ?? user.email,
                style: TextStyle(
                  fontSize: 12,
                  color: darkGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final darkGreen = Color(0xFF2E7D32);
    final userId = conversation['userId'] as String;

    return FutureBuilder<UserModel?>(
      future: _dbService.getUser(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return SizedBox.shrink();
        }
        final user = userSnapshot.data!;
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(otherUser: user),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: darkGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: darkGreen,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        conversation['lastMessage'] as String,
                        style: TextStyle(
                          color: darkGreen.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  ChatScreen({required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text(widget.otherUser.displayName ?? widget.otherUser.email),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dbService.getMessages(currentUserId, widget.otherUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: darkGreen),
                    ),
                  );
                }
                final messages = snapshot.data!.reversed.toList();
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: lightBeige,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: darkGreen,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      if (_messageController.text.isNotEmpty) {
                        final message = MessageModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          senderId: currentUserId,
                          receiverId: widget.otherUser.uid,
                          senderName: _auth.currentUser!.displayName ??
                              _auth.currentUser!.email ??
                              'User',
                          content: _messageController.text,
                          timestamp: DateTime.now(),
                        );
                        await _dbService.sendMessage(message);
                        _messageController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final darkGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFC8E6C9);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? darkGreen : lightGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                  fontSize: 12,
                ),
              ),
            SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : darkGreen,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isMe ? Colors.white70 : darkGreen.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

