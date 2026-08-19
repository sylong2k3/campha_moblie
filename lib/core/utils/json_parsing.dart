/// Parse số nguyên từ JSON có thể là `int` hoặc `String` — driver Postgres
/// `pg` serialize cột `bigint` thành chuỗi thay vì number.
int? parseIntFlexible(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
