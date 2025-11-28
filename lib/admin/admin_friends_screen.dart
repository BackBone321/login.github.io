import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../screens/messages_screen.dart';
import '../services/database_service.dart';
import '../widgets/guardian_avatar.dart';

class AdminFriendsScreen extends StatefulWidget {
  const AdminFriendsScreen({super.key});

  @override
  State<AdminFriendsScreen> createState() => _AdminFriendsScreenState();
}

class _AdminFriendsScreenState extends State<AdminFriendsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();

  late final Stream<List<UserModel>> _allUsersStream;
  Stream<List<String>>? _friendsStream;

  String _friendFilter = 'all';
  String _searchFilter = 'all';
  Future<List<UserModel>>? _searchFuture;
  Timer? _debounce;
  String? _lastQuery;

  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _deepGreen = Color(0xFF1B4332);
  static const Color _accent = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _allUsersStream = _dbService.getAllUsers().asBroadcastStream();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _friendsStream = _dbService.getFriends(uid).asBroadcastStream();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: _deepGreen,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Friend network',
              style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Track who is online, review invites, and add admins instantly.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: _deepGreen),
            onPressed: () => setState(() {}),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _friendsStream == null
          ? _buildAuthWarning()
          : StreamBuilder<List<String>>(
              stream: _friendsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friendIds = snapshot.data ?? [];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1100;
                    final content = isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildFriendPanel(friendIds)),
                              const SizedBox(width: 24),
                              Flexible(
                                flex: 5,
                                child: _buildSearchPanel(friendIds),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildFriendPanel(friendIds),
                              const SizedBox(height: 24),
                              _buildSearchPanel(friendIds),
                            ],
                          );
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 48 : 20,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: content,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildAuthWarning() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Admin session expired. Please sign in again.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildFriendPanel(List<String> friendIds) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin friend list',
            style: TextStyle(
              color: _deepGreen,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor trusted contacts, see who is online, and coordinate faster.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _buildPendingRequestsCard(),
          Row(
            children: [
              Text(
                'Connections',
                style: TextStyle(
                  color: _deepGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (friendIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text('${friendIds.length} total'),
                  backgroundColor: const Color(0xFFE8F5E9),
                  labelStyle: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFriendFilterChip(
                'all',
                'All statuses',
                Icons.all_inclusive,
              ),
              _buildFriendFilterChip('online', 'Online now', Icons.circle),
              _buildFriendFilterChip(
                'offline',
                'Offline',
                Icons.nightlight_round,
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<UserModel>>(
            stream: _allUsersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final friends =
                  snapshot.data
                      ?.where((user) => friendIds.contains(user.uid))
                      .toList() ??
                  [];
              if (friends.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'No admin friends yet',
                  subtitle:
                      'Use the search panel to add trusted collaborators.',
                );
              }

              final filtered =
                  friends.where((user) {
                    if (_friendFilter == 'online') return user.isOnline;
                    if (_friendFilter == 'offline') return !user.isOnline;
                    return true;
                  }).toList()..sort((a, b) {
                    if (a.isOnline == b.isOnline) {
                      return (a.displayName ?? a.email).toLowerCase().compareTo(
                        (b.displayName ?? b.email).toLowerCase(),
                      );
                    }
                    return a.isOnline ? -1 : 1;
                  });

              if (filtered.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.filter_alt_off,
                  title: 'No matches for this filter',
                  subtitle: 'Try switching to a different status filter.',
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildFriendCard(filtered[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsCard() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<FriendModel>>(
      stream: _dbService.getPendingRequests(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final requests = snapshot.data!;
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_alt_1, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    '${requests.length} pending invite${requests.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showRequestsSheet(requests),
                    child: const Text('Review all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: requests.take(2).map((request) {
                  return FutureBuilder<UserModel?>(
                    future: _dbService.getUser(request.userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return _buildRequestCard(snapshot.data!, request);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendFilterChip(String value, String label, IconData icon) {
    final selected = _friendFilter == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? _accent : Colors.grey),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _friendFilter = value),
      selectedColor: _accent.withOpacity(0.15),
      backgroundColor: const Color(0xFFF2F4F7),
      labelStyle: TextStyle(
        color: selected ? _accent : Colors.grey[700],
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildSearchPanel(List<String> friendIds) {
    final friendSet = friendIds.toSet();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search people',
            style: TextStyle(
              color: _deepGreen,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Look up guardians by email or name and add them instantly.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              return TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: _handleSearchChanged,
                onSubmitted: (_) => _performSearch(dismissKeyboard: true),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.trim().isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _debounce?.cancel();
                            _searchController.clear();
                            setState(() {
                              _searchFuture = null;
                              _lastQuery = null;
                            });
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchFilterChip('all', 'Any status'),
              _buildSearchFilterChip('online', 'Online now'),
              _buildSearchFilterChip('offline', 'Offline'),
            ],
          ),
          const SizedBox(height: 20),
          if (_searchFuture == null)
            _buildEmptyState(
              icon: Icons.travel_explore,
              title: 'Find people to add',
              subtitle: 'Search by email or name to see who is online.',
            )
          else
            FutureBuilder<List<UserModel>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final uid = _auth.currentUser?.uid;
                final results =
                    snapshot.data?.where((user) => user.uid != uid).toList() ??
                    [];
                final filtered = results.where((user) {
                  if (_searchFilter == 'online') return user.isOnline;
                  if (_searchFilter == 'offline') return !user.isOnline;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.person_search,
                    title: 'No people found',
                    subtitle: 'Try a different spelling or invite manually.',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isFriend = friendSet.contains(user.uid);
                    return _buildSearchCard(user, isFriend);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterChip(String value, String label) {
    final selected = _searchFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _searchFilter = value),
      selectedColor: _accent.withOpacity(0.15),
      backgroundColor: const Color(0xFFF2F4F7),
      labelStyle: TextStyle(
        color: selected ? _accent : Colors.grey[700],
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildFriendCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GuardianAvatar(style: user.avatarStyle, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final label = Text(
                      _displayLabel(user),
                      style: TextStyle(
                        color: _deepGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    );
                    final badge = Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildPresenceBadge(user),
                    );
                    if (constraints.maxWidth > 260) {
                      return Row(
                        children: [
                          Expanded(child: label),
                          badge,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        const SizedBox(height: 8),
                        _buildPresenceBadge(user),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.bio!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                tooltip: 'Open chat',
                icon: const Icon(Icons.chat_bubble_outline, color: _accent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnhancedChatScreen(otherUser: user),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _deepGreen),
                onSelected: (value) {
                  if (value == 'profile') {
                    _showProfile(user);
                  } else if (value == 'remove') {
                    _handleUnfriend(user);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: const [
                        Icon(Icons.person_outline, color: _accent),
                        SizedBox(width: 8),
                        Text('View profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: const [
                        Icon(Icons.person_remove, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Remove friend',
                          style: TextStyle(color: Colors.redAccent),
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
    );
  }

  Widget _buildPresenceBadge(UserModel user) {
    final color = user.isOnline ? _accent : Colors.grey[600]!;
    final background = user.isOnline
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF1F2F4);
    final label = user.isOnline
        ? 'Online now'
        : _formatLastSeen(user.lastSeen ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(UserModel user, bool isFriend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GuardianAvatar(style: user.avatarStyle, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayLabel(user),
                  style: TextStyle(
                    color: _deepGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                _buildPresenceBadge(user),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isFriend)
            Chip(
              label: const Text('Connected'),
              backgroundColor: const Color(0xFFE8F5E9),
              labelStyle: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _handleAddFriend(user),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add friend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(UserModel user, FriendModel request) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          GuardianAvatar(style: user.avatarStyle, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayLabel(user),
                  style: TextStyle(
                    color: _deepGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Accept',
            icon: const Icon(Icons.check_circle, color: _accent),
            onPressed: () => _respondToRequest(request, accept: true),
          ),
          IconButton(
            tooltip: 'Decline',
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => _respondToRequest(request, accept: false),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _accent.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: _deepGreen,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddFriend(UserModel user) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == user.uid) return;
    try {
      await _dbService.connectWithUser(user.uid);
      if (!mounted) return;
      _showSnack('Connected with ${_displayLabel(user)}');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to add ${_displayLabel(user)} right now', error: true);
    }
  }

  Future<void> _handleUnfriend(UserModel user) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend', style: TextStyle(color: _deepGreen)),
        content: Text('Remove ${_displayLabel(user)} from your admin friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _dbService.unfriend(currentUid, user.uid);
        if (!mounted) return;
        _showSnack('Removed ${_displayLabel(user)}');
      } catch (_) {
        if (!mounted) return;
        _showSnack('Unable to remove friend', error: true);
      }
    }
  }

  Future<void> _respondToRequest(
    FriendModel request, {
    required bool accept,
  }) async {
    try {
      if (accept) {
        await _dbService.acceptFriendRequest(request.id);
        if (!mounted) return;
        _showSnack('Connected with requestor');
      } else {
        await _dbService.rejectFriendRequest(request.id);
        if (!mounted) return;
        _showSnack('Invite declined');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to update request', error: true);
    }
  }

  void _showProfile(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _displayLabel(user),
          style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: ${user.email}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Bio',
                style: TextStyle(
                  color: _deepGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.bio!, style: TextStyle(color: Colors.grey[700])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRequestsSheet(List<FriendModel> requests) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pending invitations',
                style: TextStyle(
                  color: _deepGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accept or decline incoming friend requests.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return FutureBuilder<UserModel?>(
                      future: _dbService.getUser(request.userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return _buildRequestCard(snapshot.data!, request);
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

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchFuture = null;
        _lastQuery = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _performSearch(overrideQuery: trimmed);
    });
  }

  void _performSearch({String? overrideQuery, bool dismissKeyboard = false}) {
    final query = (overrideQuery ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
        _lastQuery = null;
      });
      return;
    }
    if (_lastQuery == query && _searchFuture != null) return;
    if (dismissKeyboard) FocusScope.of(context).unfocus();
    setState(() {
      _lastQuery = query;
      _searchFuture = _dbService.searchUsers(query);
    });
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : _accent,
      ),
    );
  }

  String _displayLabel(UserModel user) {
    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return user.email;
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    return 'Last seen ${diff.inDays}d ago';
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE3E9ED)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
