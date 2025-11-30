import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final AuditService _auditService = AuditService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedSeverity = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFFF5F7FB);
    final deepGreen = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Security audit trail',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              if (_searchController.text.isEmpty &&
                  _selectedSeverity == 'all') {
                return;
              }
              setState(() {
                _searchController.clear();
                _selectedSeverity = 'all';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                _buildSeverityRow(deepGreen),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by actor, action, entity…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<AuditLogModel>>(
              stream: _auditService.streamLogs(
                limit: 200,
                severity: _selectedSeverity == 'all' ? null : _selectedSeverity,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = _applySearch(snapshot.data ?? []);
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'No audit records match your filters.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemBuilder: (context, index) =>
                      _buildLogCard(logs[index], deepGreen),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: logs.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityRow(Color accent) {
    const filters = [
      'all',
      AuditSeverity.info,
      AuditSeverity.warning,
      AuditSeverity.critical,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters
          .map(
            (value) => ChoiceChip(
              label: Text(value.toUpperCase()),
              selected: _selectedSeverity == value,
              labelStyle: TextStyle(
                color: _selectedSeverity == value ? Colors.white : accent,
              ),
              selectedColor: accent,
              backgroundColor: const Color(0xFFE8F5E9),
              onSelected: (_) {
                setState(() {
                  _selectedSeverity = value;
                });
              },
            ),
          )
          .toList(),
    );
  }

  List<AuditLogModel> _applySearch(List<AuditLogModel> logs) {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return logs;
    return logs.where((log) {
      final descriptionMatch = (log.description ?? '').toLowerCase().contains(
        term,
      );
      final actionMatch = log.action.toLowerCase().contains(term);
      final actorMatch = log.actorEmail.toLowerCase().contains(term);
      final metadataMatch =
          log.metadata?.entries.any(
            (entry) => '${entry.key}: ${_stringify(entry.value)}'
                .toLowerCase()
                .contains(term),
          ) ??
          false;
      return descriptionMatch || actionMatch || actorMatch || metadataMatch;
    }).toList();
  }

  Widget _buildLogCard(AuditLogModel log, Color accent) {
    final severityColor = _severityColor(log.severity);
    final shadow = Colors.black.withOpacity(0.04);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.description ?? log.action,
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  log.severity.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: severityColor.withOpacity(0.12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Action ${log.action} • ${_formatTimestamp(log.timestamp)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _metaPill(
                icon: Icons.badge_outlined,
                label: log.actorEmail,
                color: accent,
              ),
              if (log.entityType.isNotEmpty)
                _metaPill(
                  icon: Icons.layers_outlined,
                  label: log.entityType,
                  color: Colors.indigo,
                ),
              _metaPill(
                icon: Icons.schedule_outlined,
                label: _relativeTime(log.timestamp),
                color: Colors.teal,
              ),
            ],
          ),
          if (log.metadata != null && log.metadata!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Context',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: log.metadata!.entries.take(4).map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${entry.key}: ${_stringify(entry.value)}',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case AuditSeverity.critical:
        return const Color(0xFFD32F2F);
      case AuditSeverity.warning:
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _stringify(dynamic value) {
    if (value == null) return '—';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Timestamp) return _formatTimestamp(value.toDate());
    if (value is DateTime) return _formatTimestamp(value);
    if (value is Map || value is List) {
      return value.toString();
    }
    return value.toString();
  }
}
