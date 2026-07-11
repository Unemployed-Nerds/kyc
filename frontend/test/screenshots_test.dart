// Visual regression / design-review screenshots.
//
// Generate with:  flutter test --update-goldens test/screenshots_test.dart
// PNGs land in test/goldens/.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/models/kyc_models.dart';
import 'package:frontend/screens/apply/details_screen.dart';
import 'package:frontend/screens/apply/document_screen.dart';
import 'package:frontend/screens/apply/processing_screen.dart';
import 'package:frontend/screens/apply/result_screen.dart';
import 'package:frontend/screens/manager/application_detail_screen.dart';
import 'package:frontend/screens/manager/dashboard_screen.dart';
import 'package:frontend/screens/welcome_screen.dart';
import 'package:frontend/theme/app_theme.dart';

const _appId = '5f3c9b2a-1d4e-4f6a-9c8b-7e2d1a0f4b3c';

Map<String, dynamic> _context({bool full = true}) => {
  'customer_data': {
    'first_name': 'Priya',
    'last_name': 'Sharma',
    'dob': '1993-04-18',
  },
  'files': const {},
  if (full) ...{
    'DocumentAgent': {'status': 'APPROVED', 'quality_score': 0.94},
    'SelfieAgent': {'status': 'APPROVED', 'reason': 'Single clear face.'},
    'OCRAgent': {
      'extracted_data': {
        'first_name': 'Priya',
        'last_name': 'Sharma',
        'dob': '1993-04-18',
        'document_number': 'DOC48291',
      },
      'confidence': 0.97,
    },
    'FaceMatchAgent': {'status': 'MATCH', 'confidence': 0.91},
    'ValidationAgent': {'status': 'MATCH', 'discrepancies': []},
    'AMLAgent': {'status': 'CLEAR'},
    'SanctionsAgent': {'status': 'PASS'},
    'PEPAgent': {'status': 'MATCH', 'classification': 'MEDIUM'},
    'RiskAssessmentAgent': {'risk_score': 20, 'risk_level': 'MEDIUM'},
    'DecisionAgent': {
      'decision': 'ESCALATE',
      'explanation':
          'Escalated for manual review due to medium risk indicators.',
    },
  },
};

http.Client _mockApi() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/api/kyc/applications') {
      return http.Response(
        jsonEncode([
          {
            'application_id': _appId,
            'status': 'COMPLETED',
            'risk_level': 'MEDIUM',
            'document_path': null,
          },
          {
            'application_id': 'a1b2c3d4-0000-1111-2222-333344445555',
            'status': 'IN_PROGRESS',
            'risk_level': 'PENDING',
            'document_path': null,
          },
          {
            'application_id': 'deadbeef-9999-8888-7777-666655554444',
            'status': 'PAUSED_AWAITING_USER',
            'risk_level': 'PENDING',
            'document_path': null,
          },
          {
            'application_id': 'cafef00d-1234-5678-9abc-def012345678',
            'status': 'COMPLETED',
            'risk_level': 'LOW',
            'document_path': null,
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.endsWith('/status')) {
      final partial = path.contains('a1b2c3d4');
      return http.Response(
        jsonEncode({
          'application_id': _appId,
          'status': partial ? 'IN_PROGRESS' : 'COMPLETED',
          'completed_agents': partial
              ? ['DocumentAgent', 'SelfieAgent', 'OCRAgent']
              : [
                  'DocumentAgent',
                  'SelfieAgent',
                  'OCRAgent',
                  'FaceMatchAgent',
                  'ValidationAgent',
                  'AMLAgent',
                  'SanctionsAgent',
                  'PEPAgent',
                  'RiskAssessmentAgent',
                  'DecisionAgent',
                ],
          'failed_agents': [],
          'decision': partial ? null : 'ESCALATE',
          'context': _context(full: !partial),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('{}', 404);
  });
}

/// Load every font in the FontManifest (app fonts + MaterialIcons) so
/// goldens render real glyphs instead of placeholder boxes.
Future<void> _loadFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = (entry['family'] as String).split('/').last;
    final loader = FontLoader(family);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light(),
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    Widget home,
    String name, {
    Duration settle = const Duration(milliseconds: 600),
    int pumps = 6,
  }) async {
    tester.view.physicalSize = const Size(1179, 2556); // iPhone-class
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(home));
    for (var i = 0; i < pumps; i++) {
      await tester.pump(settle ~/ pumps);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
    // Tear the screen down so its timers cancel before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('welcome', (tester) async {
    await shoot(tester, const WelcomeScreen(), 'welcome');
  });

  testWidgets('details', (tester) async {
    await shoot(tester, DetailsScreen(draft: ApplicationDraft()), 'details');
  });

  testWidgets('document', (tester) async {
    await shoot(tester, DocumentScreen(draft: ApplicationDraft()), 'document');
  });

  testWidgets('processing in progress', (tester) async {
    await http.runWithClient(() async {
      await shoot(
        tester,
        const ProcessingScreen(
          applicationId: 'a1b2c3d4-0000-1111-2222-333344445555',
        ),
        'processing',
      );
    }, _mockApi);
  });

  testWidgets('result approved', (tester) async {
    final status = ApplicationStatus(
      id: _appId,
      status: 'COMPLETED',
      completedAgents: const [],
      failedAgents: const [],
      decision: 'APPROVE',
      context: _context(),
    );
    await shoot(tester, ResultScreen(status: status), 'result_approved');
  });

  testWidgets('result escalated', (tester) async {
    final status = ApplicationStatus(
      id: _appId,
      status: 'COMPLETED',
      completedAgents: const [],
      failedAgents: const [],
      decision: 'ESCALATE',
      context: _context(),
    );
    await shoot(tester, ResultScreen(status: status), 'result_escalated');
  });

  testWidgets('dashboard', (tester) async {
    await http.runWithClient(() async {
      await shoot(tester, const DashboardScreen(), 'dashboard');
    }, _mockApi);
  });

  testWidgets('application detail', (tester) async {
    await http.runWithClient(() async {
      await shoot(
        tester,
        const ApplicationDetailScreen(applicationId: _appId),
        'detail',
      );
    }, _mockApi);
  });
}
