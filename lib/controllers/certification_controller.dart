import 'package:flutter/foundation.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/local_store.dart';

/// Owns and persists user certifications + matching/migration logic.
class CertificationController extends ChangeNotifier {
  CertificationController({LocalStore? store}) : _store = store ?? LocalStore();

  final LocalStore _store;

  Map<String, String> _certMatchConfirmations = <String, String>{};
  final List<PendingCertMatch> _pendingCertMatches = <PendingCertMatch>[];
  final Map<String, Certification> _certsById = <String, Certification>{};

  List<Certification> get certifications => _certsById.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<PendingCertMatch> get pendingCertMatches => List.unmodifiable(_pendingCertMatches);

  Certification? getById(String id) => _certsById[id];

  Future<void> bootstrap() async {
    final confirmationsRaw = await _store.loadCertificationMatchConfirmations();
    _certMatchConfirmations = confirmationsRaw
        .map((k, v) => MapEntry(k, (v as String?) ?? ''))
        .cast<String, String>();

    final certJsonList = await _store.loadCertifications();
    _certsById.clear();
    for (final m in certJsonList) {
      try {
        final cert = Certification.fromJson(m);
        if (cert.id.isNotEmpty) _certsById[cert.id] = cert;
      } catch (e) {
        debugPrint('Skipping invalid certification entry: $e');
      }
    }

    await _migrateCertifications();
    await _persist();
  }

  Future<void> replaceAll(List<Certification> certifications) async {
    _certsById
      ..clear()
      ..addEntries(certifications.map((c) {
        final normalized = _withResolvedDefinition(c);
        return MapEntry(normalized.id, normalized);
      }));
    await _persist();
    notifyListeners();
  }

  Future<void> upsert(Certification cert) async {
    final normalized = _withResolvedDefinition(cert);
    _certsById[cert.id] = normalized.copyWith(updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _certsById.remove(id);
    await _persist();
    notifyListeners();
  }

  Future<void> confirmMatch({required String userText, required String suggestedDefinitionId, required bool accepted}) async {
    final norm = FireOpsCatalog.normalizeCertificationText(userText);
    _certMatchConfirmations[norm] = accepted ? suggestedDefinitionId : '';
    await _store.saveCertificationMatchConfirmations(_certMatchConfirmations);

    if (accepted) {
      final id = suggestedDefinitionId;
      for (final k in _certsById.keys.toList()) {
        final c = _certsById[k]!;
        if (c.certificationDefinitionId == null && FireOpsCatalog.normalizeCertificationText(c.name) == norm) {
          _certsById[k] = c.copyWith(certificationDefinitionId: id, updatedAt: DateTime.now());
        }
      }
      await _persist();
    }

    _pendingCertMatches.removeWhere((m) => FireOpsCatalog.normalizeCertificationText(m.userText) == norm);
    notifyListeners();
  }

  String displayName(Certification c) {
    final defId = c.certificationDefinitionId;
    if (defId != null) {
      final def = FireOpsCatalog.certificationById()[defId];
      if (def != null) return def.displayName;
    }
    return c.name;
  }

  Future<void> _persist() async {
    await _store.saveCertifications(_certsById.values.map((e) => e.toJson()).toList());
  }

  Certification _withResolvedDefinition(Certification cert) {
    final existing = cert.certificationDefinitionId?.trim();
    if (existing != null && existing.isNotEmpty) return cert;

    final resolved = _resolveDefinitionId(cert.name);
    if (resolved == null) return cert;
    return cert.copyWith(
      certificationDefinitionId: resolved,
      updatedAt: DateTime.now(),
    );
  }

  String? _resolveDefinitionId(String userText) {
    final direct = FireOpsCatalog.matchCertificationDefinitionId(userText);
    if (direct != null) return direct;

    // Common firefighter shorthand used in departments and onboarding notes.
    // These map to stable catalog IDs so a credential the user already has
    // can never be offered again as the Roadmap's Next Best Step.
    final norm = FireOpsCatalog.normalizeCertificationText(userText);
    const commonAliases = <String, String>{
      'fire 1': 'firefighter_1',
      'fire i': 'firefighter_1',
      'firefighter one': 'firefighter_1',
      'fire 2': 'firefighter_2',
      'fire ii': 'firefighter_2',
      'firefighter two': 'firefighter_2',
      'driver operator pumper': 'driver_operator_pumper',
      'driver operator': 'driver_operator_pumper',
      'pump operator': 'driver_operator_pumper',
      'engineer pumper': 'driver_operator_pumper',
      'officer 1': 'fire_officer_1',
      'officer i': 'fire_officer_1',
      'instructor 1': 'fire_instructor_1',
      'instructor i': 'fire_instructor_1',
    };
    return commonAliases[norm];
  }

  Future<void> _migrateCertifications() async {
    _pendingCertMatches.clear();
    if (_certsById.isEmpty) return;

    final updated = <String, Certification>{};
    bool changed = false;

    for (final entry in _certsById.entries) {
      final cert = entry.value;
      if (cert.certificationDefinitionId != null && cert.certificationDefinitionId!.isNotEmpty) {
        updated[entry.key] = cert;
        continue;
      }

      final normalized = FireOpsCatalog.normalizeCertificationText(cert.name);
      final confirmed = _certMatchConfirmations[normalized];
      if (confirmed != null) {
        if (confirmed.isEmpty) {
          updated[entry.key] = cert; // user said "no match"
        } else {
          updated[entry.key] = cert.copyWith(certificationDefinitionId: confirmed, updatedAt: DateTime.now());
          changed = true;
        }
        continue;
      }

      final direct = _resolveDefinitionId(cert.name);
      if (direct != null) {
        updated[entry.key] = cert.copyWith(certificationDefinitionId: direct, updatedAt: DateTime.now());
        changed = true;
        continue;
      }

      final suggestion = _suggestDefinitionId(cert.name);
      if (suggestion != null) {
        _pendingCertMatches.add(PendingCertMatch(certId: cert.id, userText: cert.name, suggestedDefinitionId: suggestion));
      }
      updated[entry.key] = cert;
    }

    if (changed) {
      _certsById
        ..clear()
        ..addAll(updated);
    }
  }

  String? _suggestDefinitionId(String userText) {
    final norm = FireOpsCatalog.normalizeCertificationText(userText);
    if (norm.isEmpty) return null;

    final defs = FireOpsCatalog.certificationDefinitions();
    final matches = <String>[];
    for (final d in defs) {
      final aliasNorms = <String>{
        FireOpsCatalog.normalizeCertificationText(d.displayName),
        if (d.shortName != null) FireOpsCatalog.normalizeCertificationText(d.shortName!),
        ...d.aliases.map(FireOpsCatalog.normalizeCertificationText),
      };
      if (aliasNorms.any((a) => a == norm)) matches.add(d.id);
    }
    if (matches.length == 1) return matches.first;
    return null;
  }
}