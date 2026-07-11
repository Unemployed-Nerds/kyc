import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../services/api.dart';
import '../../theme/palette.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_chip.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  ApplicationStatus? _status;
  String? _error;
  bool _deciding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = null;
      _error = null;
    });
    try {
      final status = await ApiClient.instance.getStatus(widget.applicationId);
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _decide(String decision) async {
    final verb = decision == 'APPROVE' ? 'Approve' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$verb this application?'),
        content: Text(
          decision == 'APPROVE'
              ? 'The applicant will be verified and their account can be opened. '
                    'This overrides the automated decision.'
              : 'The applicant will be refused. This overrides the automated '
                    'decision and cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: decision == 'REJECT'
                ? FilledButton.styleFrom(
                    backgroundColor: Palette.danger,
                    minimumSize: const Size(0, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('$verb application'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deciding = true);
    try {
      await ApiClient.instance.reviewApplication(
        widget.applicationId,
        decision,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'APPROVE'
                ? 'Application approved.'
                : 'Application rejected.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  bool get _needsReview {
    final s = _status;
    if (s == null) return false;
    return s.decision == 'ESCALATE' || s.status == 'PAUSED_AWAITING_USER';
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          status == null ? 'Application' : 'Application ${status.shortId}',
        ),
      ),
      body: SafeArea(
        child: _error != null
            ? _errorView()
            : status == null
            ? _loadingView()
            : _detailView(status),
      ),
      bottomNavigationBar: _needsReview && !_deciding
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.dangerText,
                          side: const BorderSide(color: Palette.danger),
                        ),
                        onPressed: () => _decide('REJECT'),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.success,
                        ),
                        onPressed: () => _decide('APPROVE'),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _loadingView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Skeleton(height: 28, width: 220),
        SizedBox(height: 12),
        Skeleton(height: 24, width: 260),
        SizedBox(height: 24),
        Skeleton(height: 180, radius: BorderRadius.all(Radius.circular(16))),
        SizedBox(height: 16),
        Skeleton(height: 120, radius: BorderRadius.all(Radius.circular(16))),
        SizedBox(height: 16),
        Skeleton(height: 120, radius: BorderRadius.all(Radius.circular(16))),
      ],
    );
  }

  Widget _errorView() {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Palette.muted,
              size: 32,
            ),
            const SizedBox(height: 14),
            Text('Could not load this application', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center, style: text.bodySmall),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }

  Widget _detailView(ApplicationStatus status) {
    final text = Theme.of(context).textTheme;
    final ocr = status.agent('OCRAgent');
    final extracted = Map<String, dynamic>.from(
      ocr['extracted_data'] as Map? ?? const {},
    );
    final validation = status.agent('ValidationAgent');
    final discrepancies = List<dynamic>.from(
      validation['discrepancies'] as List? ?? const [],
    );
    final risk = status.agent('RiskAssessmentAgent');
    final decision = status.agent('DecisionAgent');
    final files = Map<String, dynamic>.from(
      status.context['files'] as Map? ?? const {},
    );
    final documentPath = files['document_path'] as String?;
    final selfiePath = files['selfie_path'] as String?;

    return RefreshIndicator(
      onRefresh: _load,
      color: Palette.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(status.applicantName, style: text.headlineMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip.status(status.status),
              StatusChip.risk((risk['risk_level'] ?? 'PENDING') as String),
              if (status.decision != null)
                StatusChip.decision(status.decision!),
            ],
          ),
          if (status.pauseReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Palette.warningTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: Palette.warningText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.pauseReason!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: Palette.warningText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (documentPath != null || selfiePath != null) ...[
            _SectionTitle('Submitted evidence'),
            Row(
              children: [
                if (documentPath != null)
                  Expanded(
                    child: _EvidenceImage(
                      label: 'ID document',
                      path: documentPath,
                    ),
                  ),
                if (documentPath != null && selfiePath != null)
                  const SizedBox(width: 12),
                if (selfiePath != null)
                  Expanded(
                    child: _EvidenceImage(label: 'Selfie', path: selfiePath),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle('Document checks'),
          _CheckCard(
            children: [
              _CheckRow(
                label: 'Document quality',
                passed: status.agent('DocumentAgent')['status'] == 'APPROVED',
                detail: _score(status.agent('DocumentAgent')['quality_score']),
              ),
              if (extracted.isNotEmpty) ...[
                const Divider(height: 20),
                _DataRow(
                  'Name on document',
                  '${extracted['first_name'] ?? ''} ${extracted['last_name'] ?? ''}'
                      .trim(),
                ),
                _DataRow('Date of birth', '${extracted['dob'] ?? '—'}'),
                _DataRow(
                  'Document number',
                  '${extracted['document_number'] ?? '—'}',
                ),
              ],
              const Divider(height: 20),
              _CheckRow(
                label: 'Details match document',
                passed: validation['status'] == 'MATCH',
                detail: discrepancies.isEmpty ? null : discrepancies.join(', '),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle('Identity'),
          _CheckCard(
            children: [
              _CheckRow(
                label: 'Live selfie accepted',
                passed: status.agent('SelfieAgent')['status'] == 'APPROVED',
                detail: status.agent('SelfieAgent')['reason'] as String?,
              ),
              const Divider(height: 20),
              _CheckRow(
                label: 'Face matches ID photo',
                passed: status.agent('FaceMatchAgent')['status'] == 'MATCH',
                detail: _score(
                  status.agent('FaceMatchAgent')['confidence'],
                  suffix: ' confidence',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle('Compliance screening'),
          _CheckCard(
            children: [
              _CheckRow(
                label: 'Anti-money laundering',
                passed: status.agent('AMLAgent')['status'] == 'CLEAR',
                failLabel: 'Potential match',
              ),
              const Divider(height: 20),
              _CheckRow(
                label: 'Sanctions lists',
                passed: status.agent('SanctionsAgent')['status'] == 'PASS',
                failLabel: 'Potential match',
              ),
              const Divider(height: 20),
              _CheckRow(
                label: 'Politically exposed person',
                passed: status.agent('PEPAgent')['status'] == 'CLEAR',
                failLabel:
                    'Match, ${status.agent('PEPAgent')['classification'] ?? ''} exposure',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (risk.isNotEmpty) ...[
            _SectionTitle('Risk'),
            _RiskCard(
              score: (risk['risk_score'] as num?)?.toInt() ?? 0,
              level: (risk['risk_level'] ?? 'PENDING') as String,
            ),
            const SizedBox(height: 16),
          ],
          if (decision.isNotEmpty) ...[
            _SectionTitle('Automated decision'),
            _CheckCard(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip.decision(
                      (decision['decision'] ?? 'ESCALATE') as String,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  (decision['explanation'] ?? '') as String,
                  style: text.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _score(dynamic value, {String suffix = ''}) {
    if (value is! num) return null;
    return '${(value * 100).round()}%$suffix';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final List<Widget> children;

  const _CheckCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border.all(color: Palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool passed;
  final String? detail;
  final String failLabel;

  const _CheckRow({
    required this.label,
    required this.passed,
    this.detail,
    this.failLabel = 'Did not pass',
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          passed ? Icons.check_circle_outline : Icons.error_outline,
          size: 19,
          color: passed ? Palette.successText : Palette.warningText,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.titleSmall),
              if (!passed || detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  passed ? detail! : (detail ?? failLabel),
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: text.labelMedium)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: text.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceImage extends StatelessWidget {
  final String label;
  final String path;

  const _EvidenceImage({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              ApiClient.instance.fileUrl(path),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(
                      color: Palette.surface,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
              errorBuilder: (_, _, _) => Container(
                color: Palette.surface,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Palette.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: text.labelMedium),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  final int score;
  final String level;

  const _RiskCard({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = switch (level) {
      'LOW' => Palette.success,
      'MEDIUM' => Palette.warning,
      'HIGH' => Palette.danger,
      _ => Palette.muted,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border.all(color: Palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Risk score', style: text.titleSmall),
              Text(
                '$score / 100',
                style: text.titleSmall?.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Palette.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
