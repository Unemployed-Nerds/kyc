import 'package:flutter/material.dart';

import '../../models/kyc_models.dart';
import '../../theme/palette.dart';
import '../../widgets/flow_scaffold.dart';
import 'document_screen.dart';

class DetailsScreen extends StatefulWidget {
  final ApplicationDraft draft;

  const DetailsScreen({super.key, required this.draft});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.draft.firstName);
  late final _lastName = TextEditingController(text: widget.draft.lastName);
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _dob = widget.draft.dob;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date of birth',
      fieldLabelText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String get _dobLabel {
    if (_dob == null) return '';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${_dob!.day} ${months[_dob!.month - 1]} ${_dob!.year}';
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your date of birth to continue.')),
      );
      return;
    }
    widget.draft
      ..firstName = _firstName.text.trim()
      ..lastName = _lastName.text.trim()
      ..dob = _dob;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FlowScaffold(
      step: 1,
      totalSteps: 4,
      title: 'Your details',
      subtitle:
          'Enter your name exactly as it appears on the ID document you will upload next.',
      action: FilledButton(onPressed: _continue, child: const Text('Continue')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First name', style: text.labelMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Priya'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your first name'
                  : null,
            ),
            const SizedBox(height: 20),
            Text('Last name', style: text.labelMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'e.g. Sharma'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your last name'
                  : null,
            ),
            const SizedBox(height: 20),
            Text('Date of birth', style: text.labelMedium),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                child: Text(
                  _dob == null ? 'Select your date of birth' : _dobLabel,
                  style: text.bodyLarge?.copyWith(
                    color: _dob == null ? Palette.muted : Palette.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: Palette.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your information is sent over an encrypted connection '
                      'and reviewed only by our verification system.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
