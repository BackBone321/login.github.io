import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

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
  bool _loggingSample = false;
  bool _cameraInitializing = false;
  bool _cameraDetecting = false;
  String? _cameraError;
  CameraController? _cameraController;
  _CowDetectionResult? _lastCowResult;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _cameraController?.dispose();
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
        actions: [
          TextButton.icon(
            onPressed: _loggingSample ? null : _logSampleDetection,
            icon: const Icon(Icons.pets),
            label: const Text('Log sample cow'),
          ),
          const SizedBox(width: 12),
        ],
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
              _buildCameraPanel(),
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
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
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
              ElevatedButton.icon(
                onPressed: _loggingSample ? null : _logSampleDetection,
                icon: _loggingSample
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.pets_outlined),
                label: Text(_loggingSample ? 'Logging...' : 'Log sample cow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: deepGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
              const Spacer(),
              IconButton(
                tooltip: 'Log sample cow',
                onPressed: _loggingSample ? null : _logSampleDetection,
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
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
                    (detection) => ['cow', 'mammal', 'mammals']
                        .contains(detection.type.toLowerCase()),
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
                      const Icon(Icons.sensors_off, color: Colors.grey, size: 48),
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
                        'Log a sample detection to test the pipeline.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final feedLength =
                  detections.length > 5 ? 5 : detections.length;
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

  Widget _buildCameraPanel() {
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
              const Icon(Icons.photo_camera_front_outlined,
                  color: Color(0xFF1B4332)),
              const SizedBox(width: 12),
              Text(
                'PC camera cow detection',
                style: TextStyle(
                  color: const Color(0xFF1B4332),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh camera list',
                onPressed: _cameraInitializing ? null : _initCamera,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: _cameraError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _cameraError!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : (_cameraController == null ||
                            !_cameraController!.value.isInitialized)
                        ? Center(
                            child: _cameraInitializing
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text('Waiting for camera permission...'),
                                    ],
                                  )
                                : const Text(
                                    'Camera unavailable. Ensure a webcam is connected.'),
                          )
                        : CameraPreview(_cameraController!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed:
                    _cameraDetecting ? null : () => _captureAndDetectCow(),
                icon: _cameraDetecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _cameraDetecting ? 'Analyzing frame...' : 'Detect cow now',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Use Chrome/Edge on HTTPS or localhost for webcam access.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (_lastCowResult != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_lastCowResult!.detected
                        ? Colors.green
                        : Colors.orange)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _lastCowResult!.detected ? Colors.green : Colors.orange,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastCowResult!.detected
                        ? 'Cow signature detected'
                        : 'No strong cow signature detected',
                    style: TextStyle(
                      color: _lastCowResult!.detected
                          ? Colors.green[700]
                          : Colors.orange[800],
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visual confidence: ${(100 * _lastCowResult!.score).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
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
                    label: Text(_sendingInvite ? 'Sending invite...' : 'Send invite'),
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

              final visibleInvites =
                  invites.length > 5 ? 5 : invites.length;
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

  Future<void> _initCamera() async {
    setState(() {
      _cameraInitializing = true;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError =
              'No cameras were detected. Connect a webcam and retry.';
        });
        return;
      }

      final preferred = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        preferred,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } on CameraException catch (_) {
        // Some webcams (especially on desktop/web) do not support toggling the torch.
        // Ignore and continue with preview to avoid surfacing a fatal error.
      }

      setState(() {
        _cameraController?.dispose();
        _cameraController = controller;
      });
    } catch (e) {
      setState(() {
        _cameraError =
            'Unable to access camera: $e.\nMake sure permissions are granted.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cameraInitializing = false;
        });
      }
    }
  }

  Future<void> _captureAndDetectCow() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraDetecting) {
      return;
    }

    setState(() => _cameraDetecting = true);

    try {
      final capture = await _cameraController!.takePicture();
      final bytes = await capture.readAsBytes();
      final result = await _analyzeCowFrame(bytes);

      if (result.detected) {
        final now = DateTime.now();
        final detection = DetectionModel(
          id: now.millisecondsSinceEpoch.toString(),
          userId: _auth.currentUser?.uid ?? 'admin',
          type: 'cow',
          description:
              'Camera detected cow-like patterns (${(result.score * 100).toStringAsFixed(1)}% confidence).',
          imageUrl: null,
          detectedAt: now,
          data: {
            'confidence': result.score,
            'source': 'pc_camera',
          },
        );
        await _dbService.createDetection(detection);
      }

      if (!mounted) return;
      setState(() {
        _lastCowResult = result;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.detected
                ? 'Cow detected via camera feed.'
                : 'No cow detected in the last frame.',
          ),
          backgroundColor: result.detected ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze camera frame: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cameraDetecting = false);
      }
    }
  }

  Future<_CowDetectionResult> _analyzeCowFrame(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const _CowDetectionResult(false, 0);
      }

      final image = decoded;
      final stepX = max(1, image.width ~/ 160);
      final stepY = max(1, image.height ~/ 120);
      var total = 0;
      var cowish = 0;

      for (var y = 0; y < image.height; y += stepY) {
        for (var x = 0; x < image.width; x += stepX) {
          final img.Pixel pixel = image.getPixel(x, y);
          final int r = pixel.r.toInt();
          final int g = pixel.g.toInt();
          final int b = pixel.b.toInt();
          if (_isCowColor(r, g, b)) {
            cowish++;
          }
          total++;
        }
      }

      final score = total == 0 ? 0.0 : cowish / total;
      final detected = score >= 0.18;
      return _CowDetectionResult(detected, score);
    } catch (_) {
      return const _CowDetectionResult(false, 0);
    }
  }

  bool _isCowColor(int r, int g, int b) {
    final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
    final maxRGB = [r, g, b].reduce(max);
    final minRGB = [r, g, b].reduce(min);
    final contrast = maxRGB - minRGB;

    final brownish =
        r > 90 && g > 60 && b < 120 && (r - g).abs() < 50 && r > b;
    final darkPatch = brightness < 70 && contrast < 90;
    final whitePatch = brightness > 190 && contrast < 60;

    return brownish || darkPatch || whitePatch;
  }

  Future<void> _logSampleDetection() async {
    if (_loggingSample) return;
    setState(() => _loggingSample = true);

    try {
      final now = DateTime.now();
      final detection = DetectionModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? 'admin',
        type: 'cow',
        description: 'Automated barn sensor detected a cow near the north gate.',
        imageUrl: null,
        detectedAt: now,
        data: {
          'confidence': 0.94,
          'location': 'North paddock',
          'heartRate': 68,
        },
      );

      await _dbService.createDetection(detection);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample cow detection logged.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log detection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingSample = false);
      }
    }
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
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
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
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CowDetectionResult {
  final bool detected;
  final double score;

  const _CowDetectionResult(this.detected, this.score);
}

