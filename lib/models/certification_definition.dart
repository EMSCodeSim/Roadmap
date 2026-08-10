enum CertificationCategory {
  firefighting,
  hazmat,
  driverOperator,
  officer,
  instructor,
  prevention,
  ems,
  incidentCommand,
  specialOperations,
  other,
}

class CertificationDefinition {
  final String id;
  final String displayName;
  final String? shortName;
  final CertificationCategory category;
  final String description;
  final List<String> aliases;
  final List<String> prerequisiteCertificationIds;
  final List<String> recommendedPrerequisiteIds;
  final bool typicallyExpires;
  final int? typicalRenewalYears;
  final bool stateDependent;
  final bool nationalCredential;
  final List<String> issuingOrganizations;
  final List<String> relatedCareerGoalIds;
  final List<String> resourceIds;
  final List<String> searchKeywords;

  // Renewal info (non-universal guidance).
  final String? renewalDescription;
  final String? continuingEducationNotes;
  final List<String> renewalResourceIds;

  const CertificationDefinition({
    required this.id,
    required this.displayName,
    required this.shortName,
    required this.category,
    required this.description,
    required this.aliases,
    required this.prerequisiteCertificationIds,
    required this.recommendedPrerequisiteIds,
    required this.typicallyExpires,
    required this.typicalRenewalYears,
    required this.stateDependent,
    required this.nationalCredential,
    required this.issuingOrganizations,
    required this.relatedCareerGoalIds,
    required this.resourceIds,
    required this.searchKeywords,
    required this.renewalDescription,
    required this.continuingEducationNotes,
    required this.renewalResourceIds,
  });
}
