import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../services/api.dart';
import '../../theme/palette.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_chip.dart';
import 'application_detail_screen.dart';

enum _Filter { all, inProgress, attention, completed }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ApplicationSummary>? _applications;
  String? _error;
  _Filter _filter = _Filter.all;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _load(quiet: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _applications = null;
        _error = null;
      });
    }
    try {
      final items = await ApiClient.instance.listApplications();
      if (!mounted) return;
      setState(() {
        _applications = items.reversed.toList(); // newest first
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!quiet || _applications == null) _error = e.toString();
      });
    }
  }

  List<ApplicationSummary> get _visible {
    final items = _applications ?? const [];
    return switch (_filter) {
      _Filter.all => items,
      _Filter.inProgress =>
        items.where((a) => a.status == 'IN_PROGRESS').toList(),
      _Filter.attention =>
        items.where((a) => a.status == 'PAUSED_AWAITING_USER').toList(),
      _Filter.completed => items.where((a) => a.status == 'COMPLETED').toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.surface,
      appBar: AppBar(
        backgroundColor: Palette.surface,
        title: const Text('Review queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh the queue',
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', _Filter.all),
                    const SizedBox(width: 8),
                    _filterChip('In progress', _Filter.inProgress),
                    const SizedBox(width: 8),
                    _filterChip('Needs attention', _Filter.attention),
                    const SizedBox(width: 8),
                    _filterChip('Completed', _Filter.completed),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _Filter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
      labelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: selected ? Palette.primaryText : Palette.muted,
      ),
      selectedColor: Palette.primaryTint,
      backgroundColor: Palette.bg,
      side: BorderSide(color: selected ? Colors.transparent : Palette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildList() {
    final text = Theme.of(context).textTheme;

    if (_error != null && _applications == null) {
      return _CenteredNote(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load the queue',
        message: _error!,
        action: OutlinedButton(
          onPressed: _load,
          child: const Text('Try again'),
        ),
      );
    }

    if (_applications == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const Skeleton(
          height: 86,
          radius: BorderRadius.all(Radius.circular(16)),
        ),
      );
    }

    final items = _visible;
    if (items.isEmpty) {
      return _CenteredNote(
        icon: Icons.inbox_outlined,
        title: _filter == _Filter.all
            ? 'No applications yet'
            : 'Nothing here right now',
        message: _filter == _Filter.all
            ? 'New KYC submissions appear here automatically as customers apply.'
            : 'Applications matching this filter will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(quiet: true),
      color: Palette.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: Palette.bg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ApplicationDetailScreen(applicationId: item.id),
                  ),
                );
                _load(quiet: true);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Application ${item.shortId}',
                            style: text.titleSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Palette.muted,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusChip.status(item.status),
                        const SizedBox(width: 8),
                        StatusChip.risk(item.riskLevel),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _CenteredNote({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Palette.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Palette.muted, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: text.bodySmall),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
