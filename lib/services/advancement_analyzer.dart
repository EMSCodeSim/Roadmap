import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/state/app_state.dart';

enum AdvancementActionKind {
  chooseGoal,
  workRoadmap,
  documentRequirement,
  buildCompetency,
  maintainMomentum,
}

class AdvancementRecommendation {
  final AdvancementActionKind kind;
  final String title;
  final String reason;
  final String actionLabel;
  final String? requirementId;
  final String? competencyId;

  const AdvancementRecommendation({
    required this.kind,
    required this.title,
    required this.reason,
    required this.actionLabel,
    this.requirementId,
    this.competencyId,
  });
}

class TaskBookEvidenceProgress {
  final int completed;
  final int total;

  const TaskBookEvidenceProgress({required this.completed, required this.total});

  double get percent => total <= 0 ? 0 : (completed / total).clamp(0.0, 1.0).toDouble();
}

class RequirementEvidenceStatus {
  final RoadmapRequirement roadmapItem;
  final List<CareerRecord> records;
  final TaskBookEvidenceProgress? taskBookProgress;

  const RequirementEvidenceStatus({
    required this.roadmapItem,
    required this.records,
    required this.taskBookProgress,
  });

  Requirement get requirement => roadmapItem.requirement;
  bool get isComplete => roadmapItem.isComplete;
  bool get hasEvidence => records.isNotEmpty;

  bool get evidenceExpected => switch (requirement.type) {
        RequirementType.certification => false,
        RequirementType.trainingCourse => true,
        RequirementType.taskBook => true,
        RequirementType.experience => true,
        RequirementType.numericProgress => true,
        RequirementType.course => true,
        RequirementType.promotionalTest => true,
        RequirementType.practical => true,
        RequirementType.interview => true,
        RequirementType.education => true,
        RequirementType.custom => true,
      };

  String get statusLabel {
    if (requirement.type == RequirementType.taskBook && taskBookProgress != null) {
      return '${taskBookProgress!.completed}/${taskBookProgress!.total} task-book items';
    }
    if (isComplete && hasEvidence) return 'Complete + evidence';
    if (isComplete) return 'Complete';
    if (hasEvidence) return 'Evidence started';
    return 'Needs attention';
  }
}

class AdvancementCompetency {
  final String id;
  final String title;
  final String description;
  final String capturePrompt;
  final int targetExamples;
  final CareerRecordType suggestedType;
  final List<CareerRecord> matchedRecords;

  const AdvancementCompetency({
    required this.id,
    required this.title,
    required this.description,
    required this.capturePrompt,
    required this.targetExamples,
    required this.suggestedType,
    required this.matchedRecords,
  });

  int get exampleCount => matchedRecords.length;
  double get progress => targetExamples <= 0 ? 1 : (exampleCount / targetExamples).clamp(0.0, 1.0).toDouble();
  bool get supported => exampleCount >= targetExamples;
}

class AdvancementAnalysis {
  final String? goalTitle;
  final int readinessScore;
  final String readinessLabel;
  final double roadmapProgress;
  final double evidenceProgress;
  final double competencyProgress;
  final int completedRequirements;
  final int totalRequirements;
  final int evidenceCovered;
  final int evidenceExpected;
  final int supportedCompetencies;
  final int totalCompetencies;
  final int storyReadyCount;
  final List<RequirementEvidenceStatus> requirementStatuses;
  final List<RequirementEvidenceStatus> evidenceGaps;
  final List<AdvancementCompetency> competencies;
  final List<CareerRecord> promotionStories;
  final AdvancementRecommendation recommendation;

  const AdvancementAnalysis({
    required this.goalTitle,
    required this.readinessScore,
    required this.readinessLabel,
    required this.roadmapProgress,
    required this.evidenceProgress,
    required this.competencyProgress,
    required this.completedRequirements,
    required this.totalRequirements,
    required this.evidenceCovered,
    required this.evidenceExpected,
    required this.supportedCompetencies,
    required this.totalCompetencies,
    required this.storyReadyCount,
    required this.requirementStatuses,
    required this.evidenceGaps,
    required this.competencies,
    required this.promotionStories,
    required this.recommendation,
  });
}

class AdvancementAnalyzer {
  const AdvancementAnalyzer._();

  static AdvancementAnalysis analyze({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final roadmap = app.roadmap;
    final goal = app.selectedGoal;

    final requirementStatuses = <RequirementEvidenceStatus>[];
    if (roadmap != null) {
      for (final item in roadmap.included) {
        final linked = records.where((record) => record.relatedRequirementId == item.requirement.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final rawTaskBook = app.taskBookProgressFor(goalId: roadmap.goal.id, requirementId: item.requirement.id);
        final taskBook = rawTaskBook == null
            ? null
            : TaskBookEvidenceProgress(completed: rawTaskBook.$1, total: rawTaskBook.$2);
        requirementStatuses.add(
          RequirementEvidenceStatus(
            roadmapItem: item,
            records: linked,
            taskBookProgress: taskBook,
          ),
        );
      }
    }

    final expected = requirementStatuses.where((e) => e.evidenceExpected).toList();
    final covered = expected.where((e) => e.hasEvidence).length;
    final evidenceProgress = expected.isEmpty
        ? (goal == null ? 0.0 : (records.any((e) => e.relatedGoalId == goal.id) ? 1.0 : 0.0))
        : covered / expected.length;

    final competencies = _buildCompetencies(records);
    final competencyProgress = competencies.isEmpty
        ? 0.0
        : competencies.fold<double>(0, (sum, item) => sum + item.progress) / competencies.length;
    final supportedCompetencies = competencies.where((e) => e.supported).length;

    final promotionStories = records.where(_isPromotionStoryCandidate).toList()
      ..sort((a, b) {
        if (a.highlight != b.highlight) return a.highlight ? -1 : 1;
        final aReady = _isStoryReady(a);
        final bReady = _isStoryReady(b);
        if (aReady != bReady) return aReady ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    final storyReadyCount = records.where(_isStoryReady).length;
    final storyProgress = (storyReadyCount / 5).clamp(0.0, 1.0).toDouble();

    final roadmapProgress = roadmap?.percentComplete ?? 0.0;
    final score = goal == null
        ? 0
        : ((roadmapProgress * 0.55 + evidenceProgress * 0.20 + competencyProgress * 0.20 + storyProgress * 0.05) * 100).round();

    final evidenceGaps = expected.where((status) => !status.hasEvidence).toList()
      ..sort(_compareEvidenceGaps);

    final recommendation = _recommend(
      roadmap: roadmap,
      requirementStatuses: requirementStatuses,
      evidenceGaps: evidenceGaps,
      competencies: competencies,
      storyReadyCount: storyReadyCount,
    );

    return AdvancementAnalysis(
      goalTitle: goal?.title,
      readinessScore: score,
      readinessLabel: _readinessLabel(score, hasGoal: goal != null),
      roadmapProgress: roadmapProgress,
      evidenceProgress: evidenceProgress,
      competencyProgress: competencyProgress,
      completedRequirements: roadmap?.completedCount ?? 0,
      totalRequirements: roadmap?.totalCount ?? 0,
      evidenceCovered: covered,
      evidenceExpected: expected.length,
      supportedCompetencies: supportedCompetencies,
      totalCompetencies: competencies.length,
      storyReadyCount: storyReadyCount,
      requirementStatuses: requirementStatuses,
      evidenceGaps: evidenceGaps,
      competencies: competencies,
      promotionStories: promotionStories.take(8).toList(),
      recommendation: recommendation,
    );
  }

  static String buildPromotionBrief({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final analysis = analyze(app: app, records: records);
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('PROFESSIONAL ADVANCEMENT BRIEF');
    buffer.writeln('Generated ${_formatDate(now)}');
    buffer.writeln('Target: ${analysis.goalTitle ?? 'No advancement target selected'}');
    if (analysis.goalTitle != null) {
      buffer.writeln('Advancement profile readiness: ${analysis.readinessScore}% — ${analysis.readinessLabel}');
      buffer.writeln('Roadmap: ${analysis.completedRequirements}/${analysis.totalRequirements} requirements complete');
      buffer.writeln('Evidence coverage: ${analysis.evidenceCovered}/${analysis.evidenceExpected} evidence-worthy requirements documented');
      buffer.writeln('Promotion competencies: ${analysis.supportedCompetencies}/${analysis.totalCompetencies} supported');
      buffer.writeln('Interview-ready career stories: ${analysis.storyReadyCount}');
    }
    buffer.writeln();

    buffer.writeln('BEST NEXT MOVE');
    buffer.writeln('${analysis.recommendation.title} — ${analysis.recommendation.reason}');
    buffer.writeln();

    buffer.writeln('CURRENT CREDENTIALS');
    final currentCerts = app.certifications.where((cert) => cert.status != CertificationStatus.expired).toList();
    if (currentCerts.isEmpty) {
      buffer.writeln('- No current certifications recorded.');
    } else {
      for (final cert in currentCerts.take(20)) {
        final expiration = cert.doesNotExpire || cert.expirationDate == null
            ? 'no expiration recorded'
            : 'expires ${_formatDate(cert.expirationDate!)}';
        buffer.writeln('- ${app.certificationDisplayName(cert)} — $expiration');
      }
    }
    buffer.writeln();

    buffer.writeln('PROMOTION COMPETENCY MAP');
    for (final competency in analysis.competencies) {
      buffer.writeln('- ${competency.title}: ${competency.exampleCount}/${competency.targetExamples} examples${competency.supported ? ' — supported' : ' — build more evidence'}');
    }
    buffer.writeln();

    buffer.writeln('EVIDENCE GAPS');
    if (analysis.evidenceGaps.isEmpty) {
      buffer.writeln('- No current roadmap evidence gaps identified.');
    } else {
      for (final gap in analysis.evidenceGaps.take(12)) {
        buffer.writeln('- ${gap.requirement.name}: ${gap.isComplete ? 'requirement complete, but no supporting career example is linked' : 'requirement not complete and no supporting career example is linked'}');
      }
    }
    buffer.writeln();

    buffer.writeln('PROMOTION STORY BANK');
    if (analysis.promotionStories.isEmpty) {
      buffer.writeln('- Add leadership, project, teaching, operational, and achievement records with context and results.');
    } else {
      for (final story in analysis.promotionStories) {
        final parts = <String>[];
        if ((story.roleOrAssignment ?? '').trim().isNotEmpty) parts.add(story.roleOrAssignment!.trim());
        if ((story.summary ?? '').trim().isNotEmpty) parts.add(story.summary!.trim());
        if ((story.impact ?? '').trim().isNotEmpty) parts.add('Result: ${story.impact!.trim()}');
        buffer.writeln('- ${_formatDate(story.date)} | ${story.title}${parts.isEmpty ? '' : ' — ${parts.join(' | ')}'}');
      }
    }

    buffer.writeln();
    buffer.writeln('This is a personal preparation aid, not an official determination of promotional eligibility. Verify requirements and evidence against your department, state, credentialing body, and official task book.');
    return buffer.toString().trim();
  }

  static AdvancementRecommendation _recommend({
    required Roadmap? roadmap,
    required List<RequirementEvidenceStatus> requirementStatuses,
    required List<RequirementEvidenceStatus> evidenceGaps,
    required List<AdvancementCompetency> competencies,
    required int storyReadyCount,
  }) {
    if (roadmap == null) {
      return const AdvancementRecommendation(
        kind: AdvancementActionKind.chooseGoal,
        title: 'Choose your next position',
        reason: 'The app can only prioritize certifications, experience, and career evidence after you select an advancement target.',
        actionLabel: 'Choose roadmap',
      );
    }

    final criticalMissing = requirementStatuses.where((status) {
      if (status.isComplete) return false;
      final priority = status.requirement.priority;
      return priority == RequirementPriority.core || priority == RequirementPriority.state;
    }).toList()
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));

    if (criticalMissing.isNotEmpty) {
      final next = criticalMissing.first;
      return AdvancementRecommendation(
        kind: AdvancementActionKind.workRoadmap,
        title: 'Complete ${next.requirement.name}',
        reason: 'This is a core advancement requirement and should take priority over optional portfolio-building work.',
        actionLabel: 'Open roadmap',
        requirementId: next.requirement.id,
      );
    }

    final taskBookGap = _firstOrNull(evidenceGaps.where((status) => status.requirement.type == RequirementType.taskBook));
    if (taskBookGap != null) {
      return AdvancementRecommendation(
        kind: AdvancementActionKind.documentRequirement,
        title: 'Build evidence for ${taskBookGap.requirement.name}',
        reason: 'Your path includes task-book work, but no career evidence is linked here yet. Capture examples as you complete them so they are useful years later.',
        actionLabel: 'Document evidence',
        requirementId: taskBookGap.requirement.id,
      );
    }

    final priorityEvidenceGap = _firstOrNull(evidenceGaps.where((status) => !status.isComplete)) ?? _firstOrNull(evidenceGaps);
    if (priorityEvidenceGap != null) {
      return AdvancementRecommendation(
        kind: AdvancementActionKind.documentRequirement,
        title: 'Document ${priorityEvidenceGap.requirement.name}',
        reason: priorityEvidenceGap.isComplete
            ? 'The requirement is complete, but your long-term promotion file has no linked example or proof to help you recall it later.'
            : 'You can strengthen this roadmap item by recording the work, context, and result while it is still fresh.',
        actionLabel: 'Add evidence',
        requirementId: priorityEvidenceGap.requirement.id,
      );
    }

    final remaining = requirementStatuses.where((status) => !status.isComplete).toList()
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    if (remaining.isNotEmpty) {
      return AdvancementRecommendation(
        kind: AdvancementActionKind.workRoadmap,
        title: 'Advance ${remaining.first.requirement.name}',
        reason: 'Your core prerequisites are in good shape. This is the next unfinished roadmap item to move forward.',
        actionLabel: 'Open roadmap',
        requirementId: remaining.first.requirement.id,
      );
    }

    final weakCompetencies = competencies.where((item) => !item.supported).toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    if (weakCompetencies.isNotEmpty) {
      final competency = weakCompetencies.first;
      return AdvancementRecommendation(
        kind: AdvancementActionKind.buildCompetency,
        title: 'Build a ${competency.title.toLowerCase()} example',
        reason: competency.capturePrompt,
        actionLabel: 'Capture an example',
        competencyId: competency.id,
      );
    }

    if (storyReadyCount < 5) {
      return const AdvancementRecommendation(
        kind: AdvancementActionKind.buildCompetency,
        title: 'Strengthen your promotion story bank',
        reason: 'Your roadmap is strong. Add a few detailed examples with your role, actions, and measurable result so interview preparation is easier later.',
        actionLabel: 'Add career story',
        competencyId: 'leadership',
      );
    }

    return const AdvancementRecommendation(
      kind: AdvancementActionKind.maintainMomentum,
      title: 'Maintain your advancement file',
      reason: 'Your roadmap and evidence profile are well developed. Keep certifications current and add strong examples after meaningful assignments, projects, training, and calls.',
      actionLabel: 'Open Career Vault',
    );
  }

  static List<AdvancementCompetency> _buildCompetencies(List<CareerRecord> records) {
    const definitions = <_CompetencyDefinition>[
      _CompetencyDefinition(
        id: 'leadership',
        title: 'Leadership & crew direction',
        description: 'Leading people, setting expectations, making decisions, and taking responsibility for outcomes.',
        capturePrompt: 'Document at least two situations where you led a crew, made a difficult decision, coached performance, or took responsibility for an outcome.',
        targetExamples: 2,
        suggestedType: CareerRecordType.leadership,
        directTypes: {CareerRecordType.leadership},
        keywords: {'acting officer', 'crew lead', 'supervis', 'command', 'leadership', 'led crew', 'team lead'},
      ),
      _CompetencyDefinition(
        id: 'crew_development',
        title: 'Training & crew development',
        description: 'Teaching, mentoring, coaching, precepting, and improving team capability.',
        capturePrompt: 'Add examples where you planned or delivered training, mentored a member, precepted a student, or helped someone improve performance.',
        targetExamples: 2,
        suggestedType: CareerRecordType.teaching,
        directTypes: {CareerRecordType.teaching},
        keywords: {'mentor', 'coach', 'instructor', 'precept', 'company drill', 'crew training', 'lesson', 'teach'},
      ),
      _CompetencyDefinition(
        id: 'operations',
        title: 'Operational decision-making',
        description: 'Applying technical knowledge under pressure and making sound operational choices.',
        capturePrompt: 'Capture operational examples that show size-up, prioritization, tactics, patient-care decisions, command decisions, or adapting when conditions changed.',
        targetExamples: 2,
        suggestedType: CareerRecordType.operationalExperience,
        directTypes: {CareerRecordType.operationalExperience, CareerRecordType.taskBookEvidence},
        keywords: {'size-up', 'strategy', 'tactic', 'incident command', 'decision', 'first due', 'fireground', 'scene management'},
      ),
      _CompetencyDefinition(
        id: 'safety',
        title: 'Safety & risk management',
        description: 'Recognizing hazards, managing risk, improving safety, and protecting crews and the public.',
        capturePrompt: 'Add an example where you identified a hazard, changed a plan for safety, improved accountability, addressed a near miss, or reduced operational risk.',
        targetExamples: 1,
        suggestedType: CareerRecordType.leadership,
        directTypes: {},
        keywords: {'safety', 'risk', 'near miss', 'accountability', 'mayday', 'rehab', 'air management', 'hazard', 'exposure'},
      ),
      _CompetencyDefinition(
        id: 'communication',
        title: 'Communication & public service',
        description: 'Clear briefings, difficult conversations, presentations, customer service, and interagency communication.',
        capturePrompt: 'Document a situation where communication changed the outcome: a crew briefing, presentation, difficult family/public interaction, handoff, or interagency coordination.',
        targetExamples: 1,
        suggestedType: CareerRecordType.leadership,
        directTypes: {},
        keywords: {'communication', 'briefing', 'presentation', 'public', 'customer', 'family', 'handoff', 'interagency', 'community outreach'},
      ),
      _CompetencyDefinition(
        id: 'problem_solving',
        title: 'Conflict & problem-solving',
        description: 'Handling personnel issues, operational problems, conflict, complaints, and obstacles constructively.',
        capturePrompt: 'Add a specific example of a conflict, performance issue, complaint, resource problem, or unexpected obstacle and what you did to resolve it.',
        targetExamples: 1,
        suggestedType: CareerRecordType.leadership,
        directTypes: {},
        keywords: {'conflict', 'problem', 'complaint', 'corrective', 'performance issue', 'difficult conversation', 'resolve', 'resolution', 'obstacle'},
      ),
      _CompetencyDefinition(
        id: 'projects',
        title: 'Projects & administration',
        description: 'Committees, policies, quality improvement, scheduling, budgeting, planning, and organizational work.',
        capturePrompt: 'Document a project or committee contribution that shows planning, follow-through, policy/SOP work, quality improvement, scheduling, budgeting, or measurable organizational impact.',
        targetExamples: 1,
        suggestedType: CareerRecordType.project,
        directTypes: {CareerRecordType.project},
        keywords: {'committee', 'policy', 'sop', 'quality improvement', 'qi', 'budget', 'schedule', 'inventory', 'project', 'program'},
      ),
      _CompetencyDefinition(
        id: 'technical',
        title: 'Technical proficiency',
        description: 'Maintaining hands-on competence and documenting repeated practice in role-relevant skills.',
        capturePrompt: 'Keep logging meaningful skill repetitions and task-book work so your technical growth is visible over time.',
        targetExamples: 3,
        suggestedType: CareerRecordType.skill,
        directTypes: {CareerRecordType.skill, CareerRecordType.taskBookEvidence},
        keywords: {'skill', 'pump', 'hose', 'ladder', 'forcible', 'search', 'airway', 'iv ', 'driver', 'apparatus', 'hazmat', 'rescue'},
      ),
    ];

    return definitions.map((definition) {
      final matches = records.where((record) => _recordMatches(record, definition)).toList()
        ..sort((a, b) {
          if (a.highlight != b.highlight) return a.highlight ? -1 : 1;
          return b.date.compareTo(a.date);
        });
      return AdvancementCompetency(
        id: definition.id,
        title: definition.title,
        description: definition.description,
        capturePrompt: definition.capturePrompt,
        targetExamples: definition.targetExamples,
        suggestedType: definition.suggestedType,
        matchedRecords: matches,
      );
    }).toList();
  }

  static bool _recordMatches(CareerRecord record, _CompetencyDefinition definition) {
    if (definition.directTypes.contains(record.type)) return true;
    final text = <String>[
      record.title,
      record.category,
      record.roleOrAssignment ?? '',
      record.summary ?? '',
      record.impact ?? '',
      ...record.tags,
    ].join(' ').toLowerCase();
    return definition.keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  static bool _isPromotionStoryCandidate(CareerRecord record) {
    return record.highlight ||
        record.type == CareerRecordType.leadership ||
        record.type == CareerRecordType.achievement ||
        record.type == CareerRecordType.project ||
        record.type == CareerRecordType.teaching ||
        record.type == CareerRecordType.operationalExperience ||
        record.type == CareerRecordType.taskBookEvidence;
  }

  static bool _isStoryReady(CareerRecord record) {
    final hasContext = (record.summary ?? '').trim().isNotEmpty;
    final hasResult = (record.impact ?? '').trim().isNotEmpty;
    final hasRole = (record.roleOrAssignment ?? '').trim().isNotEmpty;
    return _isPromotionStoryCandidate(record) && hasContext && hasResult && hasRole;
  }

  static int _compareEvidenceGaps(RequirementEvidenceStatus a, RequirementEvidenceStatus b) {
    int rank(RequirementEvidenceStatus status) {
      final requirement = status.requirement;
      if (!status.isComplete && (requirement.priority == RequirementPriority.core || requirement.priority == RequirementPriority.state)) return 0;
      if (requirement.type == RequirementType.taskBook) return 1;
      if (!status.isComplete && requirement.priority == RequirementPriority.department) return 2;
      if (!status.isComplete) return 3;
      return 4;
    }

    final tier = rank(a).compareTo(rank(b));
    if (tier != 0) return tier;
    return a.requirement.sortOrder.compareTo(b.requirement.sortOrder);
  }

  static String _readinessLabel(int score, {required bool hasGoal}) {
    if (!hasGoal) return 'Select a target';
    if (score >= 85) return 'Strong promotion file';
    if (score >= 70) return 'On track';
    if (score >= 50) return 'Building depth';
    return 'Foundation stage';
  }

  static String _formatDate(DateTime date) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static T? _firstOrNull<T>(Iterable<T> values) => values.isEmpty ? null : values.first;
}

class _CompetencyDefinition {
  final String id;
  final String title;
  final String description;
  final String capturePrompt;
  final int targetExamples;
  final CareerRecordType suggestedType;
  final Set<CareerRecordType> directTypes;
  final Set<String> keywords;

  const _CompetencyDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.capturePrompt,
    required this.targetExamples,
    required this.suggestedType,
    required this.directTypes,
    required this.keywords,
  });
}
