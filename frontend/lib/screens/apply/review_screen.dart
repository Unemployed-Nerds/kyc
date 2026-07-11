import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../services/api.dart';
import '../../theme/palette.dart';
import '../../widgets/flow_scaffold.dart';
import 'processing_screen.dart';

class ReviewScreen extends StatefulWidget {
  final ApplicationDraft draft;

  const ReviewScreen({super.key, required this.draft});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    final draft = widget.draft;
    if (draft.document == null || draft.selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A document photo and a selfie are both needed before submitting.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await ApiClient.instance.submitApplication(
        firstName: draft.firstName,
        lastName: draft.lastName,
        dob: draft.dobIso,
        document: draft.document!,
        selfie: draft.selfie!,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProcessingScreen(applicationId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final text = Theme.of(context).textTheme;
    return FlowScaffold(
      step: 4,
      totalSteps: 4,
      title: 'Check and submit',
      subtitle:
          'Make sure everything matches your document. You can go back to change any step.',
      action: FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Submit for verification'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Palette.surface,
              border: Border.all(color: Palette.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(
                  text,
                  'Name',
                  '${draft.firstName} ${draft.lastName}'.trim(),
                ),
                const Divider(height: 24),
                _row(text, 'Date of birth', draft.dobIso),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _photoCard(
                  text,
                  'ID document',
                  draft.document,
                  Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _photoCard(
                  text,
                  'Live selfie',
                  draft.selfie,
                  Icons.face_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: Palette.muted,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By submitting, you consent to your details and photos '
                  'being checked against identity and compliance records '
                  'for account opening.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Palette.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(TextTheme text, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: text.labelMedium)),
        Expanded(child: Text(value, style: text.bodyMedium)),
      ],
    );
  }

  Widget _photoCard(TextTheme text, String label, File? file, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: file != null
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: Palette.surface,
                    child: Icon(icon, color: Palette.muted, size: 32),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: text.labelMedium),
      ],
    );
  }
}
