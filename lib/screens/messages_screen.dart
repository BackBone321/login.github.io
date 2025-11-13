import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Always start on Chats tab
    _tabController.index = 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add this method to manually switch to Chats
  void _switchToChats() {
    setState(() {
      _tabController.animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // Add back to chats button when on groups tab
          if (_tabController.index == 1)
            IconButton(
              icon: Icon(Icons.chat),
              tooltip: 'Back to Chats',
              onPressed: _switchToChats,
            ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Add search functionality
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.add),
            onSelected: (value) {
              if (value == 'new_group') {
                _showCreateGroupDialog();
              } else if (value == 'new_chat') {
                // Navigate to friend selection for new chat
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryGreen),
                    SizedBox(width: 8),
                    Text('New Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'new_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: primaryGreen),
                    SizedBox(width: 8),
                    Text('New Group'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
            Tab(icon: Icon(Icons.groups), text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChatsTab(), _buildGroupsTab()],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _switchToChats,
              backgroundColor: primaryGreen,
              child: Icon(Icons.chat, color: Colors.white),
              tooltip: 'Back to Chats',
            )
          : null,
    );
  }

  Widget _buildChatsTab() {
    final primaryGreen = Color(0xFF2E7D32);

    return Column(
      children: [
        // Quick Friends Access
        Container(
          height: 120,
          padding: EdgeInsets.symmetric(vertical: 16),
          color: Color(0xFFE8F5E8).withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Quick Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _dbService.getFriends(_auth.currentUser!.uid),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      );
                    }
                    if (!friendsSnapshot.hasData ||
                        friendsSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No friends yet',
                          style: TextStyle(color: primaryGreen, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: friendsSnapshot.data!.length,
                      itemBuilder: (context, index) {
                        final friendId = friendsSnapshot.data![index];
                        return FutureBuilder<UserModel?>(
                          future: _dbService.getUser(friendId),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) return SizedBox.shrink();
                            return _buildFriendAvatar(userSnapshot.data!);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Individual Conversations
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.getConversations(_auth.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyConversations();
              }
              return ListView.builder(
                padding: EdgeInsets.all(20),
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
    );
  }

  Widget _buildGroupsTab() {
    final primaryGreen = Color(0xFF2E7D32);

    return StreamBuilder<List<GroupModel>>(
      stream: _dbService.getUserGroups(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyGroups();
        }
        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final group = snapshot.data![index];
            return _buildGroupCard(group);
          },
        );
      },
    );
  }

  Widget _buildEmptyGroups() {
    final primaryGreen = Color(0xFF2E7D32);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 48,
              color: primaryGreen.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first group chat',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateGroupDialog(),
            icon: Icon(Icons.group_add),
            label: Text('Create Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final primaryGreen = Color(0xFF2E7D32);
    final isCreator = group.creatorId == _auth.currentUser!.uid;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups, color: primaryGreen, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      if (isCreator)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${group.memberIds.length} members',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (group.description.isNotEmpty)
                    Text(
                      group.description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primaryGreen.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedFriends = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Create New Group',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: Icon(Icons.group, color: Color(0xFF2E7D32)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(
                      Icons.description,
                      color: Color(0xFF2E7D32),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Text(
                  'Add Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 8),
                StreamBuilder<List<String>>(
                  stream: _dbService.getFriends(_auth.currentUser!.uid),
                  builder: (context, friendsSnapshot) {
                    if (!friendsSnapshot.hasData ||
                        friendsSnapshot.data!.isEmpty) {
                      return Text(
                        'No friends to add',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: friendsSnapshot.data!.length,
                        itemBuilder: (context, index) {
                          final friendId = friendsSnapshot.data![index];
                          return FutureBuilder<UserModel?>(
                            future: _dbService.getUser(friendId),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData)
                                return SizedBox.shrink();
                              final friend = userSnapshot.data!;
                              final isSelected = selectedFriends.contains(
                                friend.uid,
                              );

                              return CheckboxListTile(
                                title: Text(
                                  friend.displayName ?? friend.email ?? 'User',
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedFriends.add(friend.uid);
                                    } else {
                                      selectedFriends.remove(friend.uid);
                                    }
                                  });
                                },
                                activeColor: Color(0xFF2E7D32),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final group = GroupModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    creatorId: _auth.currentUser!.uid,
                    memberIds: [_auth.currentUser!.uid, ...selectedFriends],
                    adminIds: [_auth.currentUser!.uid],
                    createdAt: DateTime.now(),
                  );

                  await _dbService.createGroup(group);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Group created successfully! Tap the chat icon to go back to chats.',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );

                  // Don't auto-switch tabs - let user decide
                  // _tabController.animateTo(1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversations() {
    final primaryGreen = Color(0xFF2E7D32);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: primaryGreen.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation with your friends',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendAvatar(UserModel user) {
    final primaryGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: primaryGreen,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 60,
              child: Text(
                user.displayName ?? user.email ?? 'User',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
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
    final primaryGreen = Color(0xFF2E7D32);
    final userId = conversation['userId'] as String;

    return FutureBuilder<UserModel?>(
      future: _dbService.getUser(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return SizedBox.shrink();
        final user = userSnapshot.data!;
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryGreen,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        conversation['lastMessage'] as String,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTimestamp(conversation['timestamp'] as DateTime),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName ??
                        widget.otherUser.email ??
                        'User',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Online', // You can make this dynamic
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Add more options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[50]),
              child: StreamBuilder<List<MessageModel>>(
                stream: _dbService.getMessages(
                  currentUserId,
                  widget.otherUser.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: primaryGreen.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.reversed.toList();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
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
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: primaryGreen.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      if (_messageController.text.trim().isNotEmpty) {
                        final message = MessageModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          senderId: currentUserId,
                          receiverId: widget.otherUser.uid,
                          senderName:
                              _auth.currentUser!.displayName ??
                              _auth.currentUser!.email ??
                              'User',
                          content: _messageController.text.trim(),
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
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
              bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final isAdmin = widget.group.adminIds.contains(_auth.currentUser!.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${widget.group.memberIds.length} members',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'manage_members') {
                  _showManageMembersDialog();
                } else if (value == 'group_settings') {
                  _showGroupSettingsDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'manage_members',
                  child: Row(
                    children: [
                      Icon(Icons.people, color: primaryGreen),
                      SizedBox(width: 8),
                      Text('Manage Members'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'group_settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: primaryGreen),
                      SizedBox(width: 8),
                      Text('Group Settings'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[50]),
              child: StreamBuilder<List<GroupMessageModel>>(
                stream: _dbService.getGroupMessages(widget.group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: primaryGreen.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start the conversation',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.reversed.toList();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _auth.currentUser!.uid;
                      return _buildGroupMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.group.name}...',
                        hintStyle: TextStyle(
                          color: primaryGreen.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      if (_messageController.text.trim().isNotEmpty) {
                        final message = GroupMessageModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          groupId: widget.group.id,
                          senderId: _auth.currentUser!.uid,
                          senderName:
                              _auth.currentUser!.displayName ??
                              _auth.currentUser!.email ??
                              'User',
                          content: _messageController.text.trim(),
                          timestamp: DateTime.now(),
                        );
                        await _dbService.sendGroupMessage(message);
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

  void _showManageMembersDialog() {
    final primaryGreen = Color(0xFF2E7D32);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'Manage Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = widget.group.memberIds[index];
                  return FutureBuilder<UserModel?>(
                    future: _dbService.getUser(memberId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return SizedBox.shrink();
                      final member = userSnapshot.data!;
                      final isCreator = member.uid == widget.group.creatorId;
                      final isAdmin = widget.group.adminIds.contains(
                        member.uid,
                      );
                      final canManage =
                          widget.group.creatorId == _auth.currentUser!.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryGreen,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          member.displayName ?? member.email ?? 'User',
                        ),
                        subtitle: Row(
                          children: [
                            if (isCreator)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Creator',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (isAdmin && !isCreator)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: canManage && !isCreator
                            ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'remove_member') {
                                    await _removeMember(member);
                                  } else if (value == 'make_admin') {
                                    await _toggleAdmin(member, true);
                                  } else if (value == 'remove_admin') {
                                    await _toggleAdmin(member, false);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (!isAdmin)
                                    PopupMenuItem(
                                      value: 'make_admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings,
                                            color: primaryGreen,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Make Admin'),
                                        ],
                                      ),
                                    ),
                                  if (isAdmin && !isCreator)
                                    PopupMenuItem(
                                      value: 'remove_admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings_outlined,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Remove Admin'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'remove_member',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_remove,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Remove Member',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(UserModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName ?? member.email} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.removeGroupMember(widget.group.id, member.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.displayName ?? member.email} removed from group',
          ),
        ),
      );
    }
  }

  Future<void> _toggleAdmin(UserModel member, bool makeAdmin) async {
    if (makeAdmin) {
      await _dbService.addGroupAdmin(widget.group.id, member.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.displayName ?? member.email} is now an admin',
          ),
        ),
      );
    } else {
      await _dbService.removeGroupAdmin(widget.group.id, member.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.displayName ?? member.email} is no longer an admin',
          ),
        ),
      );
    }
  }

  void _showGroupSettingsDialog() {
    final nameController = TextEditingController(text: widget.group.name);
    final descriptionController = TextEditingController(
      text: widget.group.description,
    );
    final primaryGreen = Color(0xFF2E7D32);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Group Settings',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbService.updateGroup(
                widget.group.id,
                name: nameController.text,
                description: descriptionController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Group settings updated')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMessageBubble(GroupMessageModel message, bool isMe) {
    final primaryGreen = Color(0xFF2E7D32);

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
              bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
