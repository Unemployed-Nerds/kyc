import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';

class ResultScreen extends StatefulWidget {
  final ApplicationStatus status;

  const ResultScreen({super.key, required this.status});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reduceMotion(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward();
      }
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final decision = widget.status.decision ?? 'ESCALATE';
    final explanation =
        widget.status.agent('DecisionAgent')['explanation'] as String?;

    final (icon, iconBg, iconFg, headline, message) = switch (decision) {
      'APPROVE' => (
        Icons.verified_outlined,
        Palette.successTint,
        Palette.successText,
        'You are verified.',
        'Your identity checks passed and your account can now be opened. '
            'A confirmation is on its way.',
      ),
      'REJECT' => (
        Icons.block_outlined,
        Palette.dangerTint,
        Palette.dangerText,
        'We could not verify you.',
        explanation ??
            'One or more identity checks did not pass. You can try again '
                'with clearer photos, or visit a branch with your original document.',
      ),
      _ => (
        Icons.gavel_outlined,
        Palette.brassTint,
        Palette.brassText,
        'A specialist will take it from here.',
        'Your application passed the automated checks but needs a quick '
            'human review. This usually completes within one business day.',
      ),
    };

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 38, color: iconFg),
        ),
        const SizedBox(height: 28),
        Text(headline, textAlign: TextAlign.center, style: text.displaySmall),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: Palette.muted),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Reference ${widget.status.shortId}',
            style: text.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _reveal,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.94, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _reveal,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: content,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(decision == 'REJECT' ? 'Back to start' : 'Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
