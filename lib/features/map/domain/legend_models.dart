import 'package:flutter/material.dart';

import 'layer_model.dart';

/// Mục chú giải đơn theo chuẩn Mobile Map Layer Integration Guide (Mục 5.1).
class LegendEntry {
  const LegendEntry({required this.label, required this.colorHex, this.value});

  final String label;
  final String colorHex;
  final double? value;

  Color get color {
    final parsed = parseHexColor(colorHex);
    if (parsed != null) return parsed;
    final cleanHex = colorHex.replaceAll('#', '').replaceAll('0x', '').trim();
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } else if (cleanHex.length == 3) {
      final r = cleanHex[0] * 2;
      final g = cleanHex[1] * 2;
      final b = cleanHex[2] * 2;
      return Color(int.parse('FF$r$g$b', radix: 16));
    }
    return const Color(0xFF94A3B8);
  }

  factory LegendEntry.fromJson(dynamic json, [int index = 0]) {
    if (json is! Map) {
      return LegendEntry(label: 'Mục ${index + 1}', colorHex: '#94A3B8');
    }
    final rawLabel = json['label'] ?? json['name'] ?? 'Mục ${index + 1}';
    final labelStr = rawLabel is Map
        ? (rawLabel['vi'] ?? rawLabel['en'] ?? rawLabel['name'] ?? '')
              .toString()
        : rawLabel.toString();

    double? parseD(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v');

    final color =
        json['color'] ??
        json['fill'] ??
        json['hex'] ??
        json['colorHex'] ??
        '#94A3B8';

    return LegendEntry(
      label: labelStr.isNotEmpty ? labelStr : 'Mục ${index + 1}',
      colorHex: color.toString(),
      value: parseD(json['value']),
    );
  }
}

/// Nhóm chú giải của 1 layer hoặc 1 scenario theo chuẩn (Mục 4.2 & 5.1).
class LegendGroup {
  const LegendGroup({
    required this.id,
    required this.title,
    this.kind = 'class',
    this.unit,
    required this.entries,
  });

  final String id;
  final String title;
  final String kind; // 'class' hoặc 'continuous'
  final String? unit;
  final List<LegendEntry> entries;

  bool get isContinuous => kind.toLowerCase() == 'continuous';

  factory LegendGroup.fromRaw(String id, String title, dynamic legendRaw) {
    final list = <LegendEntry>[];
    var kind = 'class';
    String? unit;

    if (legendRaw is Map) {
      final map = Map<String, dynamic>.from(legendRaw);
      kind = map['kind']?.toString() ?? 'class';
      unit = map['unit']?.toString();
      final rawEntries = map['entries'] ?? map['items'];
      if (rawEntries is List) {
        for (var i = 0; i < rawEntries.length; i++) {
          list.add(LegendEntry.fromJson(rawEntries[i], i));
        }
      } else {
        // Hỗ trợ dạng key-value map: { "Mặt nước": "#0086FF", "Đất ở": "#FF9393" }
        for (final entry in map.entries) {
          final k = entry.key.toString();
          if (k == 'entries' || k == 'items' || k == 'kind' || k == 'unit') {
            continue;
          }
          final v = entry.value;
          if (v is String && (v.startsWith('#') || v.startsWith('0x'))) {
            list.add(LegendEntry(label: k, colorHex: v));
          }
        }
      }
    } else if (legendRaw is List) {
      for (var i = 0; i < legendRaw.length; i++) {
        list.add(LegendEntry.fromJson(legendRaw[i], i));
      }
    }

    return LegendGroup(
      id: id,
      title: title,
      kind: kind,
      unit: unit,
      entries: List.unmodifiable(list),
    );
  }
}

/// Cấu hình kiểu dáng hiển thị Mapbox từ Admin (Mục 3.1 & 5.1).
class MapboxStyleConfig {
  const MapboxStyleConfig({
    this.fillColor,
    this.fillOpacity,
    this.fillAntialias = true,
    this.strokeColor,
    this.strokeWidth,
    this.strokeOpacity,
    this.strokeDasharray,
    this.circleColor,
    this.circleRadius,
    this.circleStrokeColor,
    this.circleStrokeWidth,
    this.circleOpacity,
    this.rasterOpacity,
    this.opacity,
    this.visibleByDefault = false,
  });

  final String? fillColor;
  final double? fillOpacity;
  final bool fillAntialias;
  final String? strokeColor;
  final double? strokeWidth;
  final double? strokeOpacity;
  final List<double>? strokeDasharray;
  final String? circleColor;
  final double? circleRadius;
  final String? circleStrokeColor;
  final double? circleStrokeWidth;
  final double? circleOpacity;
  final double? rasterOpacity;
  final double? opacity;
  final bool visibleByDefault;

  factory MapboxStyleConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MapboxStyleConfig();
    double? parseD(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v');

    List<double>? parseDasharray(dynamic v) {
      final raw = v ?? json['stroke_dasharray'];
      if (raw is List && raw.length >= 2) {
        final res = <double>[];
        for (final item in raw) {
          final d = parseD(item);
          if (d != null) res.add(d);
        }
        if (res.length >= 2) return res;
      }
      return null;
    }

    return MapboxStyleConfig(
      fillColor:
          json['fillColor']?.toString() ?? json['fill_color']?.toString(),
      fillOpacity: parseD(json['fillOpacity'] ?? json['fill_opacity']),
      fillAntialias:
          json['fillAntialias'] == true ||
          json['fill_antialias'] == true ||
          (json['fillAntialias'] == null && json['fill_antialias'] == null),
      strokeColor:
          json['strokeColor']?.toString() ?? json['stroke_color']?.toString(),
      strokeWidth: parseD(json['strokeWidth'] ?? json['stroke_width']),
      strokeOpacity: parseD(json['strokeOpacity'] ?? json['stroke_opacity']),
      strokeDasharray: parseDasharray(json['strokeDasharray']),
      circleColor:
          json['circleColor']?.toString() ?? json['circle_color']?.toString(),
      circleRadius: parseD(json['circleRadius'] ?? json['circle_radius']),
      circleStrokeColor:
          json['circleStrokeColor']?.toString() ??
          json['circle_stroke_color']?.toString(),
      circleStrokeWidth: parseD(
        json['circleStrokeWidth'] ?? json['circle_stroke_width'],
      ),
      circleOpacity: parseD(json['circleOpacity'] ?? json['circle_opacity']),
      rasterOpacity: parseD(json['rasterOpacity'] ?? json['raster_opacity']),
      opacity: parseD(json['opacity']),
      visibleByDefault:
          json['visible_by_default'] == true ||
          json['visibleByDefault'] == true,
    );
  }
}
