import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../models/group_message_model.dart';

const String _adminUid = 'admin_user';
const String _adminDisplayName = 'Admin';
const String _adminEmail = 'admin@agriguard.local';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ensureAdminUser();
  }

  Future<void> _ensureAdminUser() async {
    final existing = await _dbService.getUser(_adminUid);
    if (existing == null) {
      await _dbService.createUser(
        UserModel(
          uid: _adminUid,
          email: _adminEmail,
          displayName: _adminDisplayName,
          isAdmin: true,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF2E7D32);

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text('Admin Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showUserSearch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
            Tab(icon: Icon(Icons.groups), text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          _buildGroupsTab(),
        ],
      ),
    );
  }

  void _showUserSearch() {
    final primaryGreen = const Color(0xFF2E7D32);
    final searchController = TextEditingController();
    List<UserModel> results = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Search Users',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Name or email',
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) async {
                  setState(() {
                    isSearching = true;
                  });
                  final users =
                      await _dbService.searchUsers(searchController.text.trim());
                  if (mounted) {
                    setState(() {
                      results = users
                          .where((u) => u.uid != _adminUid)
                          .toList();
                      isSearching = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (isSearching)
                const Center(child: CircularProgressIndicator())
              else if (results.isEmpty)
                Text(
                  'No results',
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final user = results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryGreen,
                          child:
                              const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          user.displayName ?? user.email,
                          style: TextStyle(color: primaryGreen),
                        ),
                        subtitle: Text(user.email),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminChatScreen(otherUser: user),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    final primaryGreen = const Color(0xFF2E7D32);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getConversations(_adminUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load chats',
              style: TextStyle(color: Colors.red[400]),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final conversations = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final convo = conversations[index];
            final otherUserId = convo['userId'] as String;
            return FutureBuilder<UserModel?>(
              future: _dbService.getUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox.shrink();
                final user = userSnapshot.data!;
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryGreen,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      user.displayName ?? user.email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    subtitle: Text(
                      (convo['lastMessage'] ?? '') as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatScreen(otherUser: user),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    final primaryGreen = const Color(0xFF2E7D32);

    return StreamBuilder<List<GroupModel>>(
      stream: _dbService.getAllGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load groups',
              style: TextStyle(color: Colors.red[400]),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No groups yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final groups = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen,
                  child: const Icon(Icons.groups, color: Colors.white),
                ),
                title: Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                subtitle: Text('${group.memberIds.length} members'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminGroupChatScreen(group: group),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const AdminChatScreen({super.key, required this.otherUser});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFFE8F5E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.displayName ?? widget.otherUser.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'User',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dbService.getMessages(_adminUid, widget.otherUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load messages',
                      style: TextStyle(color: Colors.red[400]),
                    ),
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
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with this user',
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
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _adminUid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      if (_messageController.text.trim().isNotEmpty) {
                        final message = MessageModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          senderId: _adminUid,
                          receiverId: widget.otherUser.uid,
                          senderName: _adminDisplayName,
                          content: _messageController.text.trim(),
                          timestamp: DateTime.now(),
                          isRead: false,
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
    final primaryGreen = const Color(0xFF2E7D32);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMe ? primaryGreen : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
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
}

class AdminGroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const AdminGroupChatScreen({super.key, required this.group});

  @override
  State<AdminGroupChatScreen> createState() => _AdminGroupChatScreenState();
}

class _AdminGroupChatScreenState extends State<AdminGroupChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFFE8F5E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.group.memberIds.length} members',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load messages',
                        style: TextStyle(color: Colors.red[400]),
                      ),
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
                          const SizedBox(height: 16),
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
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _adminUid;
                      return _buildGroupMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () async {
                      if (_messageController.text.trim().isNotEmpty) {
                        final message = GroupMessageModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          groupId: widget.group.id,
                          senderId: _adminUid,
                          senderName: _adminDisplayName,
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

  Widget _buildGroupMessageBubble(
      GroupMessageModel message, bool isMe) {
    final primaryGreen = const Color(0xFF2E7D32);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMe ? primaryGreen : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : primaryGreen,
                        ),
                      ),
                    ),
                  Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
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
}
