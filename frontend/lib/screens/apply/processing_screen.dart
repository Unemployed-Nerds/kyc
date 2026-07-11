import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../services/api.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String applicationId;

  const ProcessingScreen({super.key, required this.applicationId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  Timer? _timer;
  ApplicationStatus? _status;
  int _failedPolls = 0;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await ApiClient.instance.getStatus(widget.applicationId);
      if (!mounted) return;
      _failedPolls = 0;
      setState(() => _status = status);
      if (status.status == 'COMPLETED' && status.decision != null) {
        _timer?.cancel();
        // Let the last check's tick render before the verdict.
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(status: status)),
        );
      }
    } catch (_) {
      // The very first polls can 404 while the workflow spins up.
      _failedPolls++;
      if (_failedPolls > 20 && mounted) {
        _timer?.cancel();
        setState(() {});
      }
    }
  }

  bool get _lostConnection => _failedPolls > 20;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = _status;
    final paused = status?.status == 'PAUSED_AWAITING_USER';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paused
                    ? 'We need another look'
                    : _lostConnection
                    ? 'Connection lost'
                    : 'Verifying your identity',
                style: text.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                paused
                    ? (status?.pauseReason ??
                          'One of the checks could not be completed automatically.')
                    : _lostConnection
                    ? 'We could not reach the verification service. Your application ID is ${widget.applicationId.substring(0, 8).toUpperCase()}.'
                    : 'Each check runs automatically. This usually takes under a minute.',
                style: text.bodyMedium?.copyWith(color: Palette.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _PipelineList(status: status),
                ),
              ),
              if (paused || _lostConnection) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Start over'),
                ),
                if (paused)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Or visit a branch with your ID and quote '
                        '${status!.shortId}.',
                        style: text.bodySmall,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineList extends StatelessWidget {
  final ApplicationStatus? status;

  const _PipelineList({required this.status});

  @override
  Widget build(BuildContext context) {
    final completed = status?.completedAgents.toSet() ?? const <String>{};
    final failed = status?.failedAgents.toSet() ?? const <String>{};
    // The first stage that has not completed is the one running now.
    final activeIndex = PipelineStage.all.indexWhere(
      (s) => !completed.contains(s.agent),
    );

    return Column(
      children: [
        for (final (i, stage) in PipelineStage.all.indexed)
          _StageRow(
            stage: stage,
            state: failed.contains(stage.agent)
                ? _StageState.failed
                : completed.contains(stage.agent)
                ? _StageState.done
                : i == activeIndex && status?.status == 'IN_PROGRESS'
                ? _StageState.active
                : _StageState.pending,
            isLast: i == PipelineStage.all.length - 1,
          ),
      ],
    );
  }
}

enum _StageState { pending, active, done, failed }

class _StageRow extends StatelessWidget {
  final PipelineStage stage;
  final _StageState state;
  final bool isLast;

  const _StageRow({
    required this.stage,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final duration = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    final labelColor = switch (state) {
      _StageState.pending => Palette.muted,
      _StageState.failed => Palette.dangerText,
      _ => Palette.ink,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _StageDot(state: state, duration: duration),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: state == _StageState.done
                          ? Palette.success.withValues(alpha: 0.35)
                          : Palette.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: text.titleSmall!.copyWith(color: labelColor),
                    child: Text(stage.label),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state == _StageState.failed
                        ? 'This check could not be completed'
                        : stage.description,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageDot extends StatefulWidget {
  final _StageState state;
  final Duration duration;

  const _StageDot({required this.state, required this.duration});

  @override
  State<_StageDot> createState() => _StageDotState();
}

class _StageDotState extends State<_StageDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _StageDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == _StageState.active && !reduceMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (widget.state) {
      _StageState.pending => (Palette.surface, Palette.muted, null),
      _StageState.active => (Palette.primaryTint, Palette.primaryText, null),
      _StageState.done => (
        Palette.successTint,
        Palette.successText,
        Icons.check,
      ),
      _StageState.failed => (
        Palette.dangerTint,
        Palette.dangerText,
        Icons.priority_high,
      ),
    };

    return AnimatedContainer(
      duration: widget.duration,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: widget.state == _StageState.pending
            ? Border.all(color: Palette.border)
            : null,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 15, color: fg)
          : widget.state == _StageState.active
          ? FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
