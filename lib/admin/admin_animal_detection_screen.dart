import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/detection_model.dart';
import '../models/invite_model.dart';
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

  final GlobalKey<FormState> _inviteFormKey = GlobalKey<FormState>();

  bool _sendingInvite = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
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
                    (detection) => [
                      'cow',
                      'mammal',
                      'mammals',
                    ].contains(detection.type.toLowerCase()),
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
                    subtitle: Text(
                      'Code: ${invite.code} • Expires ${_formatDate(invite.expiresAt)}',
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
      final invite = await _dbService.createInvite(email, message: note);
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
