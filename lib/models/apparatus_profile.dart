enum ApparatusKind { medic, engine, brush, tender, truck, rescue, command, custom }

extension ApparatusKindX on ApparatusKind {
  String get label => switch (this) {
        ApparatusKind.medic => 'Medic',
        ApparatusKind.engine => 'Engine',
        ApparatusKind.brush => 'Brush',
        ApparatusKind.tender => 'Tender',
        ApparatusKind.truck => 'Truck / Aerial',
        ApparatusKind.rescue => 'Rescue',
        ApparatusKind.command => 'Command',
        ApparatusKind.custom => 'Custom',
      };
}

class ApparatusProfile {
  final String id;
  final String name;
  final ApparatusKind kind;

  const ApparatusProfile({required this.id, required this.name, required this.kind});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kind': kind.name};

  factory ApparatusProfile.fromJson(Map<String, dynamic> json) {
    ApparatusKind kind = ApparatusKind.custom;
    try {
      kind = ApparatusKind.values.byName(json['kind'] as String? ?? 'custom');
    } catch (_) {}
    return ApparatusProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      kind: kind,
    );
  }
}
