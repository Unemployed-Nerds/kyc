import 'package:flutter/material.dart';

import '../theme/palette.dart';

enum ChipTone { neutral, brand, success, warning, danger, brass }

/// Tinted pill with a leading icon. Status is never conveyed by color alone.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ChipTone tone;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
  });

  /// Chip for a workflow status string from the backend.
  factory StatusChip.status(String status, {Key? key}) {
    return switch (status) {
      'COMPLETED' => StatusChip(
        key: key,
        label: 'Completed',
        icon: Icons.check_circle_outline,
        tone: ChipTone.success,
      ),
      'IN_PROGRESS' => StatusChip(
        key: key,
        label: 'In progress',
        icon: Icons.autorenew,
        tone: ChipTone.brand,
      ),
      'PAUSED_AWAITING_USER' => StatusChip(
        key: key,
        label: 'Needs attention',
        icon: Icons.error_outline,
        tone: ChipTone.warning,
      ),
      _ => StatusChip(
        key: key,
        label: status,
        icon: Icons.help_outline,
        tone: ChipTone.neutral,
      ),
    };
  }

  /// Chip for a risk level string (PENDING/LOW/MEDIUM/HIGH).
  factory StatusChip.risk(String level, {Key? key}) {
    return switch (level) {
      'LOW' => StatusChip(
        key: key,
        label: 'Low risk',
        icon: Icons.shield_outlined,
        tone: ChipTone.success,
      ),
      'MEDIUM' => StatusChip(
        key: key,
        label: 'Medium risk',
        icon: Icons.report_gmailerrorred,
        tone: ChipTone.warning,
      ),
      'HIGH' => StatusChip(
        key: key,
        label: 'High risk',
        icon: Icons.gpp_bad_outlined,
        tone: ChipTone.danger,
      ),
      _ => StatusChip(
        key: key,
        label: 'Risk pending',
        icon: Icons.hourglass_empty,
        tone: ChipTone.neutral,
      ),
    };
  }

  /// Chip for a final decision (APPROVE/ESCALATE/REJECT).
  factory StatusChip.decision(String decision, {Key? key}) {
    return switch (decision) {
      'APPROVE' => StatusChip(
        key: key,
        label: 'Approved',
        icon: Icons.verified_outlined,
        tone: ChipTone.success,
      ),
      'ESCALATE' => StatusChip(
        key: key,
        label: 'Manual review',
        icon: Icons.gavel_outlined,
        tone: ChipTone.brass,
      ),
      'REJECT' => StatusChip(
        key: key,
        label: 'Rejected',
        icon: Icons.block_outlined,
        tone: ChipTone.danger,
      ),
      _ => StatusChip(
        key: key,
        label: decision,
        icon: Icons.help_outline,
        tone: ChipTone.neutral,
      ),
    };
  }

  (Color, Color) get _colors => switch (tone) {
    ChipTone.neutral => (Palette.surface, Palette.muted),
    ChipTone.brand => (Palette.primaryTint, Palette.primaryText),
    ChipTone.success => (Palette.successTint, Palette.successText),
    ChipTone.warning => (Palette.warningTint, Palette.warningText),
    ChipTone.danger => (Palette.dangerTint, Palette.dangerText),
    ChipTone.brass => (Palette.brassTint, Palette.brassText),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
