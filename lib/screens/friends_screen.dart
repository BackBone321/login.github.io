import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'messages_screen.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text('People'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _showSearch ? _buildSearchView() : _buildFriendsView(),
    );
  }

  Widget _buildFriendsView() {
    final darkGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text('Please login'));

    return Column(
      children: [
        // Pending Requests
        StreamBuilder<List<FriendModel>>(
          stream: _dbService.getPendingRequests(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Text(
                      'Friend Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...snapshot.data!.map((request) {
                      return FutureBuilder<UserModel?>(
                        future: _dbService.getUser(request.userId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return SizedBox.shrink();
                          }
                          final friendUser = userSnapshot.data!;
                          return _buildFriendRequestCard(friendUser, request);
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        // Friends List
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: _dbService.getFriends(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No friends yet',
                    style: TextStyle(color: darkGreen),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final friendId = snapshot.data![index];
                  return FutureBuilder<UserModel?>(
                    future: _dbService.getUser(friendId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      return _buildFriendCard(userSnapshot.data!);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendRequestCard(UserModel user, FriendModel request) {
    final darkGreen = Color(0xFF2E7D32);

    return Container(
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
                if (user.bio != null)
                  Text(
                    user.bio!,
                    style: TextStyle(
                      color: darkGreen.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbService.acceptFriendRequest(request.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(UserModel user) {
    final darkGreen = Color(0xFF2E7D32);

    return Container(
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
                if (user.bio != null)
                  Text(
                    user.bio!,
                    style: TextStyle(
                      color: darkGreen.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.message, color: darkGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(otherUser: user),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: darkGreen),
            onSelected: (value) async {
              if (value == 'unfriend') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Unfriend'),
                    content: Text('Are you sure you want to unfriend ${user.displayName ?? user.email}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Unfriend'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _dbService.unfriend(_auth.currentUser!.uid, user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unfriended ${user.displayName ?? user.email}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'unfriend',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Unfriend', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    final darkGreen = Color(0xFF2E7D32);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: darkGreen),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: darkGreen),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: darkGreen),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: _searchController.text.isEmpty
              ? Center(
                  child: Text(
                    'Start typing to search users',
                    style: TextStyle(color: darkGreen),
                  ),
                )
              : FutureBuilder<List<UserModel>>(
                  future: _dbService.searchUsers(_searchController.text),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: darkGreen),
                        ),
                      );
                    }
                    final currentUserId = _auth.currentUser!.uid;
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final user = snapshot.data![index];
                        if (user.uid == currentUserId) return SizedBox.shrink();
                        return _buildSearchUserCard(user);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchUserCard(UserModel user) {
    final darkGreen = Color(0xFF2E7D32);

    return Container(
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
                if (user.bio != null)
                  Text(
                    user.bio!,
                    style: TextStyle(
                      color: darkGreen.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: _dbService.areFriends(_auth.currentUser!.uid, user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return Text(
                  'Friends',
                  style: TextStyle(color: darkGreen),
                );
              }
              return ElevatedButton(
                onPressed: () async {
                  await _dbService.sendFriendRequest(user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Friend request sent')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text('Add'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

