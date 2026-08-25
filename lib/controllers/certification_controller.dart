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
      ..addEntries(
        certifications.map((c) {
          final normalized = _normalizeHeldCertification(c);
          return MapEntry(normalized.id, normalized);
        }),
      );
    await _persist();
    notifyListeners();
  }

  Future<void> upsert(Certification cert) async {
    final normalized = _normalizeHeldCertification(
      cert.copyWith(updatedAt: DateTime.now()),
    );
    _certsById[normalized.id] = normalized;
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

      final direct = _definitionIdForName(cert.name);
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

  Certification _normalizeHeldCertification(Certification cert) {
    final existing = cert.certificationDefinitionId?.trim();
    if (existing != null && existing.isNotEmpty) return cert;

    final mapped = _definitionIdForName(cert.name);
    if (mapped == null) return cert;
    return cert.copyWith(
      certificationDefinitionId: mapped,
      updatedAt: DateTime.now(),
    );
  }

  String? _definitionIdForName(String userText) {
    final direct = FireOpsCatalog.matchCertificationDefinitionId(userText);
    if (direct != null) return direct;

    // Conservative compatibility aliases for common real-world shorthand.
    // These are intentionally exact after normalization so we do not silently
    // convert an unrelated credential into a career-road requirement.
    final norm = FireOpsCatalog.normalizeCertificationText(userText);
    return switch (norm) {
      'fire 1' || 'fire i' || 'firefighter one' || 'fire fighter one' =>
        'firefighter_1',
      'fire 2' || 'fire ii' || 'firefighter two' || 'fire fighter two' =>
        'firefighter_2',
      'driver operator pumper' || 'driver operator pump' || 'do pumper' =>
        'driver_operator_pumper',
      'fire officer one' || 'officer one' => 'fire_officer_1',
      'fire officer two' || 'officer two' => 'fire_officer_2',
      'fire instructor one' || 'instructor one' => 'fire_instructor_1',
      _ => null,
    };
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
