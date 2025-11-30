import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/detection_model.dart';
import '../models/detection_access_model.dart';
import '../models/invite_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/email_service.dart';
import '../widgets/detection_card.dart';

class AdminAnimalDetectionScreen extends StatefulWidget {
  const AdminAnimalDetectionScreen({super.key});

  @override
  State<AdminAnimalDetectionScreen> createState() =>
      _AdminAnimalDetectionScreenState();
}

class _AdminAnimalDetectionScreenState
    extends State<AdminAnimalDetectionScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  final GlobalKey<FormState> _inviteFormKey = GlobalKey<FormState>();

  bool _sendingInvite = false;
  bool _shareDetections = true;

  static const List<_DetectionCategoryOption> _detectionCategories = [
    _DetectionCategoryOption(
      id: 'all',
      label: 'All detections',
      icon: Icons.public,
      types: ['all'],
    ),
    _DetectionCategoryOption(
      id: 'insects',
      label: 'Insects & pests',
      icon: Icons.bug_report_outlined,
      types: ['insect', 'insects', 'pest', 'pests'],
    ),
    _DetectionCategoryOption(
      id: 'animals',
      label: 'Animals & livestock',
      icon: Icons.pets_outlined,
      types: [
        'cow',
        'cows',
        'animal',
        'animals',
        'mammal',
        'mammals',
        'livestock',
      ],
    ),
    _DetectionCategoryOption(
      id: 'plants',
      label: 'Plant health',
      icon: Icons.local_florist_outlined,
      types: ['plant_health', 'health_plant', 'plant', 'plants'],
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = const Color(0xFFF5F7FB);
    final deepGreen = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Animal Detection Module'),
        backgroundColor: Colors.white,
        foregroundColor: deepGreen,
        elevation: 1,
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(deepGreen),
              const SizedBox(height: 20),
              _buildInsightRow(),
              const SizedBox(height: 24),
              _buildLiveFeed(),
              const SizedBox(height: 24),
              _buildInvitePanel(),
              const SizedBox(height: 24),
              _buildUserAccessManager(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Color deepGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Animal signals',
            style: TextStyle(color: Colors.white70, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track and simulate livestock detections.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Scrollable.ensureVisible(
                    _inviteFormKey.currentContext ?? context,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                icon: const Icon(Icons.mail),
                label: const Text(
                  'Invite collaborators',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white60),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow() {
    final tiles = [
      _InsightTile(
        icon: Icons.pets_outlined,
        title: 'Tracked animals',
        value: 'Cow herd',
        subtitle: 'Priority livestock',
        color: const Color(0xFF2E7D32),
      ),
      _InsightTile(
        icon: Icons.sensors,
        title: 'Detection type',
        value: 'Vision + IoT',
        subtitle: 'Edge device feed',
        color: const Color(0xFF00897B),
      ),
      _InsightTile(
        icon: Icons.lock_outline,
        title: 'Access',
        value: 'Invite only',
        subtitle: 'Admin approved',
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            children: [
              for (final tile in tiles)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: tile == tiles.last ? 0 : 16,
                    ),
                    child: tile,
                  ),
                ),
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: constraints.maxWidth >= 420
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: tile,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLiveFeed() {
    final accent = const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.live_tv, color: Color(0xFF1B4332)),
              const SizedBox(width: 8),
              Text(
                'Live animal detections',
                style: TextStyle(
                  color: const Color(0xFF1B4332),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<DetectionModel>>(
            stream: _dbService.getAllDetections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final detections = (snapshot.data ?? [])
                  .where(
                    (detection) => _matchesDetectionTags(detection.type, const [
                      'cow',
                      'cows',
                      'animal',
                      'animals',
                      'mammal',
                      'mammals',
                      'livestock',
                    ]),
                  )
                  .toList();

              if (detections.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sensors_off,
                        color: Colors.grey,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No animal detections yet',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Awaiting the first reading from field sensors.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final feedLength = detections.length > 5 ? 5 : detections.length;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: feedLength,
                itemBuilder: (context, index) {
                  final detection = detections[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == feedLength - 1 ? 0 : 12,
                    ),
                    child: DetectionCard(detection: detection),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvitePanel() {
    final accent = const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add, color: Color(0xFF1B4332)),
              const SizedBox(width: 12),
              Text(
                'Invite collaborators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _inviteFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'User email',
                    hintText: 'farmer@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _shareDetections,
                  onChanged: (value) {
                    setState(() => _shareDetections = value);
                  },
                  title: const Text('Share live detections'),
                  subtitle: const Text(
                    'Grant real-time detection access without waiting for approval',
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendingInvite ? null : _sendInvite,
                    icon: _sendingInvite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _sendingInvite ? 'Sending invite...' : 'Send invite',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent invites',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<InviteModel>>(
            stream: _dbService.getInvites(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final invites = snapshot.data!;
              if (invites.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No invites yet. Send one to grant access to detection feeds.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final visibleInvites = invites.length > 5 ? 5 : invites.length;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleInvites,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  final statusColor = invite.status == 'accepted'
                      ? Colors.green
                      : invite.isExpired
                      ? Colors.red
                      : accent;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(Icons.person_add, color: statusColor),
                    ),
                    title: Text(invite.email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code: ${invite.code} • Expires ${_formatDate(invite.expiresAt)}',
                        ),
                        if (invite.shareDetections)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Shares detection feed',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        invite.isExpired ? 'expired' : invite.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserAccessManager() {
    final accent = const Color(0xFF1B4332);
    final cardBackground = Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_accounts_outlined,
                color: Color(0xFF1B4332),
              ),
              const SizedBox(width: 12),
              Text(
                'Detection access control',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search users by name or email',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<UserModel>>(
            stream: _dbService.getAllUsers(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No users found in the system.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final users = userSnapshot.data!
                  .where((user) => !user.isAdmin && _matchesUserSearch(user))
                  .toList();

              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No users matched "${_userSearchController.text}".',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return StreamBuilder<List<DetectionAccessModel>>(
                stream: _dbService.getDetectionAccessList(),
                builder: (context, accessSnapshot) {
                  final accessMap = {
                    for (final record in accessSnapshot.data ?? [])
                      record.userId: record,
                  };

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final access = accessMap[user.uid];
                      final hasAccess = access?.canAccess ?? false;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: hasAccess
                              ? const Color(0xFF2E7D32).withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          child: Icon(
                            hasAccess
                                ? Icons.verified_user_outlined
                                : Icons.lock_outline,
                            color: hasAccess
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[700],
                          ),
                        ),
                        title: Text(
                          user.displayName ?? user.email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAllowedTypes(access),
                              style: TextStyle(
                                color: hasAccess
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Chip(
                              label: Text(
                                hasAccess ? 'Has access' : 'No access',
                                style: TextStyle(
                                  color: hasAccess
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: hasAccess
                                  ? const Color(0xFF2E7D32).withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.12),
                            ),
                            TextButton.icon(
                              onPressed: () => _openAccessSheet(user, access),
                              icon: const Icon(Icons.tune_outlined, size: 18),
                              label: Text(
                                hasAccess ? 'Manage access' : 'Grant access',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvite() async {
    if (!_inviteFormKey.currentState!.validate()) return;

    setState(() => _sendingInvite = true);
    final email = _emailController.text.trim();
    final note = _messageController.text.trim().isEmpty
        ? null
        : _messageController.text.trim();
    final adminName =
        _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Admin';

    try {
      final invite = await _dbService.createInvite(
        email,
        message: note,
        shareDetections: _shareDetections,
      );
      await EmailService.sendInviteEmail(
        invite.email,
        invite.code,
        invitedBy: adminName,
      );

      if (!mounted) return;
      _emailController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send invite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingInvite = false);
      }
    }
  }

  bool _matchesUserSearch(UserModel user) {
    final query = _userSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final haystack = '${user.displayName ?? ''} ${user.email}'.toLowerCase();
    return haystack.contains(query);
  }

  String _formatAllowedTypes(DetectionAccessModel? access) {
    if (access == null || !access.canAccess) {
      return 'Detections hidden';
    }
    final allowed = access.allowedTypes;
    if (allowed.isEmpty || allowed.contains('all')) {
      return 'All detections';
    }

    final labels = <String>{};
    for (final option in _detectionCategories.where((o) => o.id != 'all')) {
      if (option.types.any((type) => allowed.contains(type))) {
        labels.add(option.label);
      }
    }
    if (labels.isEmpty) {
      return 'Custom detection list';
    }
    return labels.join(', ');
  }

  Set<String> _initialSelection(DetectionAccessModel? access) {
    if (access == null || access.allowedTypes.contains('all')) {
      return {'all'};
    }
    final set = <String>{};
    for (final option in _detectionCategories.where((o) => o.id != 'all')) {
      if (option.types.any((type) => access.allowedTypes.contains(type))) {
        set.add(option.id);
      }
    }
    return set.isEmpty ? {'all'} : set;
  }

  List<String> _resolveAllowedTypesFromSelection(Set<String> selection) {
    if (selection.isEmpty || selection.contains('all')) {
      return ['all'];
    }
    final types = <String>{};
    for (final option in _detectionCategories) {
      if (selection.contains(option.id)) {
        types.addAll(option.types.map((type) => type.toLowerCase()));
      }
    }
    return types.isEmpty ? ['all'] : types.toList();
  }

  Future<void> _openAccessSheet(
    UserModel user,
    DetectionAccessModel? currentAccess,
  ) async {
    final rootContext = context;
    await showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      builder: (modalContext) {
        bool enableAccess = currentAccess?.canAccess ?? false;
        final selection = _initialSelection(currentAccess);
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage access for ${user.displayName ?? user.email}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: enableAccess,
                    onChanged: (value) =>
                        setModalState(() => enableAccess = value),
                    title: const Text('Allow detection access'),
                    subtitle: const Text(
                      'When enabled, the user can view detections you share.',
                    ),
                  ),
                  if (enableAccess) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Scope',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _detectionCategories.map((option) {
                        final isSelected = selection.contains(option.id);
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(option.label),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (value) {
                            setModalState(() {
                              if (option.id == 'all') {
                                selection..clear();
                                if (value) selection.add('all');
                              } else {
                                if (value) {
                                  selection.add(option.id);
                                  selection.remove('all');
                                } else {
                                  selection.remove(option.id);
                                  if (selection.isEmpty) {
                                    selection.add('all');
                                  }
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                await _dbService.setDetectionAccess(
                                  userId: user.uid,
                                  enabled: enableAccess,
                                  allowedTypes: enableAccess
                                      ? _resolveAllowedTypesFromSelection(
                                          selection,
                                        )
                                      : [],
                                );
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      enableAccess
                                          ? 'Granted detection access to ${user.displayName ?? user.email}'
                                          : 'Revoked detection access from ${user.displayName ?? user.email}',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => saving = false);
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update access: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        enableAccess ? 'Save access' : 'Disable access',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  bool _matchesDetectionTags(String detectionType, List<String> tags) {
    final normalized = detectionType.toLowerCase();
    for (final tag in tags) {
      if (normalized.contains(tag)) return true;
    }
    return false;
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionCategoryOption {
  final String id;
  final String label;
  final IconData icon;
  final List<String> types;

  const _DetectionCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.types,
  });
}
