// Keep topic labels aligned with the website EMS continuing education sheet.
const Map<String, List<String>> emsCeCategories = {
  'Airway': ['Airway Management', 'Supraglottic Airways', 'CPAP / Respiratory Support', 'Airway Pharmacology', 'Capnography'],
  'Cardiology': ['Acute Coronary Syndrome', 'Cardiac Arrest Management', 'ECG Interpretation', 'Cardiac Dysrhythmias', 'Post-ROSC Care', 'Cardiac Medications'],
  'Trauma': ['Head / Brain Injury', 'Chest Trauma', 'Abdominal Trauma', 'Spinal Injuries', 'Hemorrhage Control', 'Shock Management', 'Musculoskeletal Trauma'],
  'Medical': ['Respiratory Emergencies', 'Diabetic Emergencies', 'Neurologic Emergencies', 'Sepsis', 'Allergic Reactions / Anaphylaxis', 'Toxicology / Overdose', 'Environmental Emergencies', 'Infectious Disease', 'Behavioral Emergencies'],
  'Operations': ['EMS Safety', 'Ambulance Operations', 'Crew Resource Management', 'Mass Casualty Incidents', 'Incident Command', 'Documentation / Legal', 'Communications'],
  'Pediatric / Obstetrics': ['Normal Childbirth', 'Obstetric Emergencies', 'Neonatal Resuscitation', 'Pregnancy Complications', 'Pediatric Assessment', 'Pediatric Respiratory Emergencies', 'Pediatric Medical Emergencies', 'Pediatric Trauma'],
  'Local / State': ['Protocol Updates', 'Equipment Training', 'Medication Updates', 'Regional EMS Updates', 'Agency Policies', 'Quality Improvement', 'Scenario Training'],
  'Individual': ['General EMS Continuing Education', 'Specialty EMS Training', 'Professional Development'],
};

String emsCeCreditSummary(Map<String, double> credits) {
  final entries = credits.entries.where((entry) => entry.value > 0).toList();
  if (entries.isEmpty) return '';
  return 'EMS CE CREDIT BREAKDOWN\n${entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)} hours').join('\n')}';
}
