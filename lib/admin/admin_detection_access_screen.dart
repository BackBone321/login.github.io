import 'package:flutter/material.dart';

import '../models/detection_access_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AdminDetectionAccessScreen extends StatefulWidget {
  const AdminDetectionAccessScreen({super.key});

  @override
  State<AdminDetectionAccessScreen> createState() =>
      _AdminDetectionAccessScreenState();
}

class _AdminDetectionAccessScreenState
    extends State<AdminDetectionAccessScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _userSearchController = TextEditingController();

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
      types: ['insect', 'insects', 'pest', 'pests', 'bug', 'bugs'],
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
      types: [
        'plant_health',
        'health_plant',
        'plant',
        'plants',
        'crop',
        'crops',
      ],
    ),
  ];

  @override
  void dispose() {
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
        title: const Text('Detection access control'),
        backgroundColor: Colors.white,
        foregroundColor: deepGreen,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'View summary',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: _showAccessSummary,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildAccessManager(),
        ),
      ),
    );
  }

  Widget _buildAccessManager() {
    final accent = const Color(0xFF1B4332);
    final surface = const Color(0xFFF5F7FB);

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
              const Icon(
                Icons.manage_accounts_outlined,
                color: Color(0xFF1B4332),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Manage who can view shared detections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Search guardians, enable access, and scope which detection streams they can see.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search users by name or email',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: surface,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final access = accessMap[user.uid];
                      final hasAccess = access?.canAccess ?? false;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
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
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.displayName ?? user.email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatAllowedTypes(access),
                                    style: TextStyle(
                                      color: hasAccess
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
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
                                      fontSize: 10,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 0,
                                  ),
                                  labelPadding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: hasAccess
                                      ? const Color(
                                          0xFF2E7D32,
                                        ).withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.12),
                                ),
                                const SizedBox(height: 2),
                                TextButton(
                                  onPressed: () =>
                                      _openAccessSheet(user, access),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_outlined,
                                        size: 14,
                                        color: hasAccess
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasAccess ? 'Manage' : 'Grant',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: hasAccess
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                selection.clear();
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

  Future<void> _showAccessSummary() async {
    final records = await _dbService.getDetectionAccessList().first;
    final granted = records.where((r) => r.canAccess).toList();
    final userMap = <String, UserModel?>{};
    for (final record in granted) {
      userMap[record.userId] = await _dbService.getUser(record.userId);
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final primaryGreen = const Color(0xFF1B4332);
        if (granted.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open, size: 40, color: Colors.grey[500]),
                const SizedBox(height: 12),
                Text(
                  'No users currently have detection access.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    'Users with detection access',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: granted.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final record = granted[index];
                    final user = userMap[record.userId];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        child: Icon(Icons.person, color: primaryGreen),
                      ),
                      title: Text(
                        user?.displayName ?? user?.email ?? 'Unknown',
                      ),
                      subtitle: Text(
                        _formatAllowedTypes(record),
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        user?.email ?? record.userId,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
