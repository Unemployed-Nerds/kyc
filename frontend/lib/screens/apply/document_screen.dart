import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/kyc_models.dart';
import '../../theme/palette.dart';
import '../../widgets/flow_scaffold.dart';
import 'liveness_screen.dart';

class DocumentScreen extends StatefulWidget {
  final ApplicationDraft draft;

  const DocumentScreen({super.key, required this.draft});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final _picker = ImagePicker();
  File? _document;

  @override
  void initState() {
    super.initState();
    _document = widget.draft.document;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 92,
      );
      if (file != null) setState(() => _document = File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not open the camera. Allow camera access in Settings and try again.'
                : 'Could not open your photos. Allow photo access in Settings and try again.',
          ),
        ),
      );
    }
  }

  void _continue() {
    widget.draft.document = _document;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LivenessScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FlowScaffold(
      step: 2,
      totalSteps: 4,
      title: 'Your ID document',
      subtitle:
          'Photograph the front of a passport, driving licence, or national ID card.',
      action: FilledButton(
        onPressed: _document == null ? null : _continue,
        child: const Text('Continue'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_document == null) ...[
            _PickTile(
              icon: Icons.photo_camera_outlined,
              title: 'Take a photo',
              subtitle: 'Use your camera to capture the document',
              onTap: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _PickTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              subtitle: 'Upload an existing photo of the document',
              onTap: () => _pick(ImageSource.gallery),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.file(_document!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Replace'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Text('For a clear capture', style: text.titleSmall),
          const SizedBox(height: 12),
          const _Tip('Lay the document flat with all four corners visible'),
          const _Tip('Avoid glare from lights or windows'),
          const _Tip('Make sure the text is sharp and readable'),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Palette.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Palette.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Palette.primaryText, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String label;

  const _Tip(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: Palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
