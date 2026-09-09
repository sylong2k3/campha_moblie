class FloodRun {
  const FloodRun({
    required this.id,
    required this.name,
    required this.periodText,
    required this.status,
    this.summary = const {},
  });
  final int id;
  final String name;
  final String periodText;
  final String status;
  final Map<String, double> summary;

  factory FloodRun.fromJson(Map<String, dynamic> json) {
    final id = _id(json['id']);
    final metadata = _map(json['result_metadata'] ?? json['resultMetadata']);
    final periods =
        json['analysis_periods'] ??
        _map(json['period'])['analysis'] ??
        metadata['analysisPeriods'] ??
        const [];
    if (periods is! List) {
      throw const FormatException('Invalid analysis periods');
    }
    final periodText = periods
        .map((p) {
          final period = _map(p);
          return '${period['start'] ?? ''} – ${period['end'] ?? ''}';
        })
        .join(', ');
    final stats = _map(metadata['areaStats']);
    final summary = <String, double>{};
    for (final entry in {
      'Diện tích ngập (ha)':
          metadata['totalFloodAreaHa'] ?? stats['floodExtentAreaHa'],
      'Dân cư ảnh hưởng':
          metadata['affectedPopulation'] ?? stats['populationAffected'],
      'Cây trồng ảnh hưởng (ha)':
          metadata['affectedCroplandHa'] ?? stats['cropAffectedAreaHa'],
      'Xây dựng ảnh hưởng (ha)':
          metadata['affectedBuiltHa'] ?? stats['builtAffectedAreaHa'],
    }.entries) {
      final value = double.tryParse('${entry.value}');
      if (value != null && value.isFinite) summary[entry.key] = value;
    }
    return FloodRun(
      id: id,
      name: json['name']?.toString() ?? 'Kỳ giám sát #$id',
      periodText: periodText,
      status: json['status']?.toString() ?? '',
      summary: summary,
    );
  }
}

class FloodArtifact {
  const FloodArtifact({
    required this.id,
    required this.analysisRunId,
    required this.code,
    required this.labelVi,
    required this.isPublic,
    this.registryLayerId,
    this.module = 'trend',
    this.description = '',
  });
  final int id;
  final int analysisRunId;
  final String code;
  final String labelVi;
  final bool isPublic;
  final String? registryLayerId;
  final String module;
  final String description;

  String get group => switch (code) {
    'flood_extent' => 'Ngập lụt',
    'pop_affected' || 'crop_affected' || 'built_affected' => 'Ảnh hưởng',
    'pond_to_built' ||
    'drainage_sensitive' ||
    'encroachment_alert' => 'Tiêu thoát nước',
    _ => 'Kiểm tra chất lượng',
  };

  factory FloodArtifact.fromJson(Map<String, dynamic> json) {
    final metadata = _map(json['metadata']);
    final registryId = json['registryLayerId']?.toString();
    final parsedId = int.tryParse(registryId ?? '');
    return FloodArtifact(
      id: _id(json['id']),
      analysisRunId: _id(json['analysisRunId']),
      code: json['code']?.toString() ?? '',
      labelVi:
          _map(metadata['label'])['vi']?.toString() ??
          json['code']?.toString() ??
          '',
      isPublic: json['isPublic'] == true,
      registryLayerId: parsedId != null && parsedId > 0 ? registryId : null,
      module: json['module']?.toString() ?? '',
      description: metadata['description']?.toString() ?? '',
    );
  }
}

class FloodHydrologyLegend {
  const FloodHydrologyLegend({
    required this.code,
    required this.label,
    required this.entries,
    this.module = 'trend',
  });
  final String code;
  final String label;
  final String module;
  final List<({String color, String label})> entries;

  factory FloodHydrologyLegend.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'] ?? const [];
    if (entries is! List) throw const FormatException('Invalid flood legend');
    return FloodHydrologyLegend(
      code: json['code']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      label: _map(json['label'])['vi']?.toString() ?? '',
      entries: entries
          .map((raw) {
            final e = _map(raw);
            return (
              color: e['color']?.toString() ?? '',
              label:
                  _map(e['label'])['vi']?.toString() ??
                  e['value']?.toString() ??
                  '',
            );
          })
          .toList(growable: false),
    );
  }
}

int _id(dynamic value) {
  final id = int.tryParse('$value');
  if (id == null || id <= 0) throw const FormatException('Invalid flood ID');
  return id;
}

Map<String, dynamic> _map(dynamic value) {
  if (value == null) return const {};
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected flood object');
}
