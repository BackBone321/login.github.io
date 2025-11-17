import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'messages_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'My Friends',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Friend Requests Section (if any)
            StreamBuilder<List<FriendModel>>(
              stream: _dbService.getPendingRequests(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    color: lightGreen,
                    child: Row(
                      children: [
                        Icon(Icons.notifications, color: primaryGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${snapshot.data!.length} friend request${snapshot.data!.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showFriendRequests(snapshot.data!),
                          child: Text(
                            'View',
                            style: TextStyle(color: primaryGreen),
                          ),
                        ),
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
                stream: _dbService.getFriends(_auth.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyFriendsView();
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
        ),
      ),
    );
  }

  Widget _buildEmptyFriendsView() {
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
              Icons.people_outline,
              size: 48,
              color: primaryGreen.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find and connect with people',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSearchDialog(),
            icon: Icon(Icons.search),
            label: Text('Find Friends'),
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

  Widget _buildFriendCard(UserModel user) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryGreen,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),

              // User Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.email!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        user.bio!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.message, color: primaryGreen),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnhancedChatScreen(otherUser: user),
                        ),
                      );
                    },
                    tooltip: 'Send Message',
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: primaryGreen),
                    onSelected: (value) async {
                      if (value == 'unfriend') {
                        await _unfriendUser(user);
                      } else if (value == 'view_profile') {
                        _showUserProfile(user);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view_profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: primaryGreen),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unfriend',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Unfriend',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Find Friends',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or email',
            prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_searchController.text.isNotEmpty) {
                _performSearch();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final primaryGreen = Color(0xFF2E7D32);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: primaryGreen,
            title: Text('Search Results'),
          ),
          body: FutureBuilder<List<UserModel>>(
            future: _dbService.searchUsers(_searchController.text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: primaryGreen),
                  ),
                );
              }

              final currentUserId = _auth.currentUser!.uid;
              final users = snapshot.data!
                  .where((user) => user.uid != currentUserId)
                  .toList();

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildSearchUserCard(users[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchUserCard(UserModel user) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryGreen,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email ?? 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 16,
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Text(
                    user.bio!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: _dbService.areFriends(_auth.currentUser!.uid, user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Friends',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return ElevatedButton(
                onPressed: () async {
                  await _dbService.sendFriendRequest(user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Friend request sent'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Add Friend'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFriendRequests(List<FriendModel> requests) {
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
              'Friend Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            Expanded(
              child: ListView(
                children: requests.map((request) {
                  return FutureBuilder<UserModel?>(
                    future: _dbService.getUser(request.userId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return SizedBox.shrink();
                      return _buildFriendRequestCard(
                        userSnapshot.data!,
                        request,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(UserModel user, FriendModel request) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryGreen,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email ?? 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _dbService.acceptFriendRequest(request.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request accepted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text('Accept'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _dbService.rejectFriendRequest(request.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request declined'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unfriendUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfriend', style: TextStyle(color: Color(0xFF2E7D32))),
        content: Text(
          'Are you sure you want to unfriend ${user.displayName ?? user.email}?',
        ),
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

  void _showUserProfile(UserModel user) {
    final primaryGreen = Color(0xFF2E7D32);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.displayName ?? user.email ?? 'Profile',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...[
              Text(
                'Email: ${user.email}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
            ],
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              Text(
                'Bio:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(user.bio!, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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
