class ForestLegendClass {
  const ForestLegendClass({
    required this.classId,
    required this.nameVi,
    required this.color,
    this.areaHa,
    this.percent,
  });
  final int classId;
  final String nameVi;
  final String color;
  final double? areaHa;
  final double? percent;

  factory ForestLegendClass.fromJson(Map<String, dynamic> json) =>
      ForestLegendClass(
        classId: _integer(json['classId']),
        nameVi: json['nameVi']?.toString() ?? '',
        color: json['color']?.toString() ?? '',
        areaHa: _number(json['areaHa'] ?? json['ha']),
        percent: _number(json['percent']),
      );
}

class ForestSnapshot {
  const ForestSnapshot({
    required this.id,
    required this.year,
    required this.month,
    this.geoserverLayer,
    this.geeTileUrl,
    this.totalAreaHa,
    this.forestCoveragePct,
    this.legend = const [],
  });
  final int id;
  final int year;
  final int month;
  final String? geoserverLayer;
  final String? geeTileUrl;
  final double? totalAreaHa;
  final double? forestCoveragePct;
  final List<ForestLegendClass> legend;

  String get periodText => '${month.toString().padLeft(2, '0')}/$year';

  factory ForestSnapshot.fromJson(Map<String, dynamic> json) {
    final summary =
        json['provinceSummary'] ?? json['province_summary'] ?? const {};
    if (summary is! Map) {
      throw const FormatException('Invalid province summary');
    }
    final rawLegend = summary['legend'] ?? const [];
    if (rawLegend is! List) {
      throw const FormatException('Invalid forest legend');
    }
    final id = _integer(json['id']);
    final year = _integer(json['year']);
    final month = _integer(json['month']);
    if (id <= 0 || year < 1 || month < 1 || month > 12) {
      throw const FormatException('Invalid forest snapshot identity or period');
    }
    return ForestSnapshot(
      id: id,
      year: year,
      month: month,
      geoserverLayer: _text(json['geoserverLayer'] ?? json['geoserver_layer']),
      geeTileUrl: _text(json['geeTileUrl'] ?? json['gee_tile_url']),
      totalAreaHa: _number(summary['totalAreaHa'] ?? summary['totalHa']),
      forestCoveragePct: _number(
        summary['forestCoveragePct'] ?? summary['forestPercent'],
      ),
      legend: rawLegend
          .map(
            (e) =>
                ForestLegendClass.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(dynamic value) {
  final number = int.tryParse('$value');
  if (number == null) throw const FormatException('Expected integer');
  return number;
}

double? _number(dynamic value) {
  if (value == null) return null;
  final number = double.tryParse('$value');
  if (number == null || !number.isFinite) {
    throw const FormatException('Invalid number');
  }
  return number;
}
