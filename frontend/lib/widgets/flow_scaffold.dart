import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';

/// Scaffold for onboarding flow steps: back button, step progress,
/// scrollable body, and a bottom-pinned primary action.
class FlowScaffold extends StatelessWidget {
  final int step; // 1-based
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget action;
  final Color background;

  const FlowScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    required this.body,
    required this.action,
    this.background = Palette.bg,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          'Step $step of $totalSteps',
          style: text.labelMedium?.copyWith(color: Palette.muted),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _StepDots(step: step, total: totalSteps),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.headlineMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: text.bodyMedium?.copyWith(color: Palette.muted),
                      ),
                    ],
                    const SizedBox(height: 28),
                    body,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: action,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  final int total;

  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= total; i++) ...[
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: i == step ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i <= step ? Palette.primary : Palette.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (i < total) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
