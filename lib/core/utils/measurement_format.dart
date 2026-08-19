/// Tiện ích định dạng các số đo đạc (diện tích, độ dài).
/// Quy tắc đổi đơn vị: 10.000 m² = 1 ha.
String formatArea(double squareMeters) {
  if (squareMeters >= 10000) {
    return '${(squareMeters / 10000).toStringAsFixed(2)} ha';
  }
  return '${squareMeters.toStringAsFixed(0)} m²';
}
