import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  GroupModel? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final brandColor = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 24,
        iconTheme: IconThemeData(color: brandColor),
        title: Row(
          children: [
            Text(
              'Admin Collaboration Hub',
              style: TextStyle(
                color: brandColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.wifi_tethering_outlined, color: Color(0xFF2E7D32)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: user == null ? null : _showCreateGroupDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('New Group'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: user == null
          ? _buildAuthWarning()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1000;
                final groupsPanel = SizedBox(
                  width: isDesktop ? 360 : constraints.maxWidth,
                  child: _buildGroupsPanel(),
                );
                final chatPanel = _buildChatPanel(isDesktop);

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      groupsPanel,
                      Expanded(child: chatPanel),
                    ],
                  );
                }

                return Column(
                  children: [
                    groupsPanel,
                    Expanded(child: chatPanel),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildAuthWarning() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.lock_person_outlined,
                  size: 48,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(height: 16),
                Text(
                  'Sign in required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please sign in to your admin account to access group chats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsPanel() {
    final accent = const Color(0xFF2E7D32);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: StreamBuilder<List<GroupModel>>(
          stream: _dbService.getAllGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final groups = snapshot.data ?? [];
            _syncSelectedGroup(groups);

            final query = _searchController.text.trim().toLowerCase();
            final filteredGroups = query.isEmpty
                ? groups
                : groups
                    .where(
                      (group) =>
                          group.name.toLowerCase().contains(query) ||
                          group.description.toLowerCase().contains(query),
                    )
                    .toList();

            final totalMembers = groups
                .expand((group) => group.memberIds)
                .toSet()
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group channels',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${groups.length} active groups · $totalMembers unique members',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search groups or descriptions',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: filteredGroups.isEmpty
                      ? _buildEmptyGroupsState()
                      : ListView.separated(
                          itemCount: filteredGroups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final group = filteredGroups[index];
                            final isSelected = _selectedGroup?.id == group.id;
                            return _buildGroupTile(
                              group,
                              isSelected: isSelected,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 48,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new channel to start collaborating.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(
    GroupModel group, {
    required bool isSelected,
  }) {
    final accent = const Color(0xFF2E7D32);

    return InkWell(
      onTap: () => setState(() => _selectedGroup = group),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.08) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups, color: Color(0xFF1B4332)),
            ),
            const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B4332),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberIds.length}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.description.isNotEmpty
                        ? group.description
                        : 'No description provided',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          group.adminIds.contains(group.creatorId)
                              ? 'Managed'
                              : 'Community',
                        ),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        label: Text(
                          group.createdAt.toLocal().toString().split(' ').first,
                        ),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(bool isDesktop) {
    final group = _selectedGroup;
    final borderRadius = BorderRadius.circular(24);

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 0 : 24, 24, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: group == null
            ? _buildNoSelectionState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChatHeader(group),
                  const Divider(height: 1),
                  Expanded(child: _buildMessagesList(group)),
                  const Divider(height: 1),
                  _buildComposer(group),
                ],
              ),
      ),
    );
  }

  Widget _buildNoSelectionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_outlined,
                color: Color(0xFF2E7D32),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select a group to start chatting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a channel from the left panel to see its conversation.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(GroupModel group) {
    final accent = const Color(0xFF2E7D32);
    final userId = _auth.currentUser?.uid;
    final isMember = userId != null && group.memberIds.contains(userId);
    final isAdmin = userId != null && group.adminIds.contains(userId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'You manage this group',
                          style: TextStyle(
                            color: Color(0xFF1B4332),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.memberIds.length} members · created ${_formatDate(group.createdAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    group.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showMembersSheet(group),
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Members'),
              ),
              OutlinedButton.icon(
                onPressed: isMember ? _showAddMembersDialog : () => _joinGroup(group),
                icon: Icon(isMember ? Icons.person_add_alt : Icons.login),
                label: Text(isMember ? 'Add' : 'Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(GroupModel group) {
    final accent = const Color(0xFF2E7D32);

    return StreamBuilder<List<GroupMessageModel>>(
      stream: _dbService.getGroupMessages(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum_outlined, size: 48, color: Color(0xFFBDBDBD)),
                const SizedBox(height: 12),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation with an announcement or question.',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sorted = [...messages]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 12),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final message = sorted[index];
            final isMe = message.senderId == _auth.currentUser?.uid;
            final showHeader = index == 0 ||
                sorted[index - 1].senderId != message.senderId ||
                sorted[index - 1].timestamp.day != message.timestamp.day;

            return _buildMessageBubble(
              message,
              isMe: isMe,
              showHeader: showHeader,
              accent: accent,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    GroupMessageModel message, {
    required bool isMe,
    required bool showHeader,
    required Color accent,
  }) {
    final alignment =
        isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        isMe ? accent : const Color(0xFFF3F4F6);
    final textColor = isMe ? Colors.white : const Color(0xFF1B1C1E);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          color: textColor.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
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

  Widget _buildComposer(GroupModel group) {
    final isMember = _auth.currentUser != null &&
        group.memberIds.contains(_auth.currentUser!.uid);

    if (!isMember) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Join this group to participate in the conversation.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            TextButton(
              onPressed: () => _joinGroup(group),
              child: const Text('Join group'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_outlined),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Share updates with the group…',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;
    final group = _selectedGroup;
    final text = _messageController.text.trim();

    if (currentUser == null || group == null || text.isEmpty) return;

    try {
      final message = GroupMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: group.id,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? currentUser.email ?? 'Admin',
        content: text,
        timestamp: DateTime.now(),
      );

      await _dbService.sendGroupMessage(message);
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinGroup(GroupModel group) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (group.memberIds.contains(user.uid)) return;

    try {
      await _dbService.addGroupMembers(group.id, [user.uid]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not join group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMembersSheet(GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<UserModel>>(
            future: _fetchMembers(group.memberIds),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final members = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isAdmin = group.adminIds.contains(member.uid);
                        final isCreator = group.creatorId == member.uid;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32),
                            child: Text(
                              _initialFor(member),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            member.displayName ?? member.email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(member.email),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              if (isCreator)
                                Chip(
                                  label: const Text('Owner'),
                                  backgroundColor:
                                      Colors.blue.withOpacity(0.1),
                                  labelStyle:
                                      const TextStyle(color: Colors.blue),
                                ),
                              if (isAdmin && !isCreator)
                                Chip(
                                  label: const Text('Admin'),
                                  backgroundColor:
                                      const Color(0xFF2E7D32).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAddMembersDialog() {
    final group = _selectedGroup;
    final currentUser = _auth.currentUser;
    if (group == null || currentUser == null) return;

    final selected = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add members'),
              content: SizedBox(
                width: 420,
                height: 420,
                child: StreamBuilder<List<UserModel>>(
                  stream: _dbService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final available = snapshot.data!
                        .where((user) => !group.memberIds.contains(user.uid))
                        .toList();

                    if (available.isEmpty) {
                      return const Center(
                        child: Text('Everyone is already part of this group.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: available.length,
                      itemBuilder: (context, index) {
                        final user = available[index];
                        final isChecked = selected.contains(user.uid);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(user.displayName ?? user.email),
                          subtitle: Text(user.email),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(user.uid);
                              } else {
                                selected.remove(user.uid);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          await _dbService.addGroupMembers(
                            group.id,
                            selected.toList(),
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selected.length} member(s) added successfully',
                              ),
                            ),
                          );
                        },
                  child: const Text('Add members'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final selected = <String>{currentUser.uid};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create new group'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Short description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add members',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: StreamBuilder<List<UserModel>>(
                        stream: _dbService.getAllUsers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final users = snapshot.data!
                              .where((user) => user.uid != currentUser.uid)
                              .toList();

                          if (users.isEmpty) {
                            return const Center(
                              child: Text('No other users found'),
                            );
                          }

                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final isChecked = selected.contains(user.uid);
                              return CheckboxListTile(
                                value: isChecked,
                                title: Text(user.displayName ?? user.email),
                                subtitle: Text(user.email),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selected.add(user.uid);
                                    } else {
                                      selected.remove(user.uid);
                                    }
                                  });
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty
                      ? null
                      : () async {
                          final group = GroupModel(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            creatorId: currentUser.uid,
                            memberIds: selected.toList(),
                            adminIds: [currentUser.uid],
                            createdAt: DateTime.now(),
                            imageUrl: null,
                          );

                          await _dbService.createGroup(group);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group created successfully'),
                            ),
                          );
                        },
                  child: const Text('Create group'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<UserModel>> _fetchMembers(List<String> memberIds) async {
    final futures = memberIds.map(_dbService.getUser);
    final result = await Future.wait(futures);
    return result.whereType<UserModel>().toList();
  }

  String _initialFor(UserModel user) {
    final source = (user.displayName ?? user.email).trim();
    if (source.isEmpty) return '?';
    final firstCodeUnit = source.codeUnitAt(0);
    return String.fromCharCode(firstCodeUnit).toUpperCase();
  }

  void _syncSelectedGroup(List<GroupModel> groups) {
    GroupModel? nextSelection;
    if (groups.isEmpty) {
      nextSelection = null;
    } else if (_selectedGroup == null) {
      nextSelection = groups.first;
    } else {
      nextSelection = groups.firstWhere(
        (group) => group.id == _selectedGroup!.id,
        orElse: () => groups.first,
      );
    }

    if ((_selectedGroup == null && nextSelection == null) ||
        (_selectedGroup != null &&
            nextSelection != null &&
            _selectedGroup!.id == nextSelection.id)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedGroup = nextSelection;
      });
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

