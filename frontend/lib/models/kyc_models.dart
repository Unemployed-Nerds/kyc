import 'dart:io';

/// Mutable state carried through the onboarding flow.
class ApplicationDraft {
  String firstName = '';
  String lastName = '';
  DateTime? dob;
  File? document;
  File? selfie;

  String get dobIso => dob == null
      ? ''
      : '${dob!.year.toString().padLeft(4, '0')}-'
            '${dob!.month.toString().padLeft(2, '0')}-'
            '${dob!.day.toString().padLeft(2, '0')}';
}

class ApplicationSummary {
  final String id;
  final String status;
  final String riskLevel;
  final String? documentPath;

  ApplicationSummary({
    required this.id,
    required this.status,
    required this.riskLevel,
    this.documentPath,
  });

  factory ApplicationSummary.fromJson(Map<String, dynamic> json) =>
      ApplicationSummary(
        id: json['application_id'] as String,
        status: (json['status'] ?? 'UNKNOWN') as String,
        riskLevel: (json['risk_level'] ?? 'PENDING') as String,
        documentPath: json['document_path'] as String?,
      );

  String get shortId => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
}

class ApplicationStatus {
  final String id;
  final String status; // IN_PROGRESS | PAUSED_AWAITING_USER | COMPLETED
  final List<String> completedAgents;
  final List<String> failedAgents;
  final String? decision; // APPROVE | ESCALATE | REJECT
  final Map<String, dynamic> context;

  ApplicationStatus({
    required this.id,
    required this.status,
    required this.completedAgents,
    required this.failedAgents,
    this.decision,
    required this.context,
  });

  factory ApplicationStatus.fromJson(Map<String, dynamic> json) =>
      ApplicationStatus(
        id: json['application_id'] as String,
        status: (json['status'] ?? 'UNKNOWN') as String,
        completedAgents: List<String>.from(
          json['completed_agents'] as List? ?? const [],
        ),
        failedAgents: List<String>.from(
          json['failed_agents'] as List? ?? const [],
        ),
        decision: json['decision'] as String?,
        context: Map<String, dynamic>.from(json['context'] as Map? ?? const {}),
      );

  String get shortId => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;

  Map<String, dynamic> agent(String name) =>
      Map<String, dynamic>.from(context[name] as Map? ?? const {});

  String get applicantName {
    final data = Map<String, dynamic>.from(
      context['customer_data'] as Map? ?? const {},
    );
    final name = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'
        .trim();
    return name.isEmpty ? 'Unknown applicant' : name;
  }

  /// Why the workflow paused, taken from whichever gate agent rejected.
  String? get pauseReason {
    for (final name in const [
      'DocumentAgent',
      'SelfieAgent',
      'FaceMatchAgent',
    ]) {
      final result = agent(name);
      final status = result['status'];
      if (status == 'REJECTED' || status == 'MISMATCH') {
        return result['reason'] as String?;
      }
    }
    return null;
  }
}

/// One step of the verification pipeline, in the order the backend runs it.
class PipelineStage {
  final String agent;
  final String label;
  final String description;

  const PipelineStage(this.agent, this.label, this.description);

  static const all = <PipelineStage>[
    PipelineStage(
      'DocumentAgent',
      'Document quality',
      'Checking your ID photo is clear and complete',
    ),
    PipelineStage(
      'SelfieAgent',
      'Selfie quality',
      'Confirming a single, real face in your selfie',
    ),
    PipelineStage(
      'OCRAgent',
      'Reading your document',
      'Extracting name, date of birth, and document number',
    ),
    PipelineStage(
      'FaceMatchAgent',
      'Matching your face',
      'Comparing your selfie against the ID photo',
    ),
    PipelineStage(
      'ValidationAgent',
      'Cross-checking details',
      'Making sure your details match the document',
    ),
    PipelineStage(
      'AMLAgent',
      'AML screening',
      'Screening against anti-money-laundering watchlists',
    ),
    PipelineStage(
      'SanctionsAgent',
      'Sanctions screening',
      'Screening against international sanctions lists',
    ),
    PipelineStage(
      'PEPAgent',
      'PEP screening',
      'Checking politically exposed person registers',
    ),
    PipelineStage(
      'RiskAssessmentAgent',
      'Risk assessment',
      'Combining every check into a risk score',
    ),
    PipelineStage(
      'DecisionAgent',
      'Final decision',
      'Approving automatically or referring to a reviewer',
    ),
  ];
}
