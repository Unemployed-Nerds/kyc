import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/kyc_models.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'apply/details_screen.dart';
import 'manager/dashboard_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.primaryDeep,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'K',
                                style: TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: 22,
                                  color: Palette.primaryDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'KYCFlow',
                              style: TextStyle(
                                fontFamily: kSerif,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Verify your identity.\nOpen your account.',
                          style: text.displaySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 40,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Three steps, about three minutes. Your details stay '
                          'encrypted and are used only for identity verification.',
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.5,
                            color: Palette.onDarkMuted,
                          ),
                        ),
                        const SizedBox(height: 36),
                        const _StepRow(
                          number: '1',
                          label: 'Your details',
                          detail: 'Name and date of birth',
                        ),
                        const _StepRow(
                          number: '2',
                          label: 'Your ID document',
                          detail: 'Passport, licence, or national ID',
                        ),
                        const _StepRow(
                          number: '3',
                          label: 'A live selfie',
                          detail: 'Quick camera check that you are you',
                          last: true,
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Palette.primaryDeep,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailsScreen(draft: ApplicationDraft()),
                              ),
                            );
                          },
                          child: const Text('Start verification'),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Palette.onDarkMuted,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Branch staff: open the review queue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  final String detail;
  final bool last;

  const _StepRow({
    required this.number,
    required this.label,
    required this.detail,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 20),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Palette.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
