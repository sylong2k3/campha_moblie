/// Envelope thật của server: `{message, status, data, metadata?}` khi thành
/// công (KHÔNG có field `success`). Lỗi thì có `{success:false, message,
/// errors:[]}` nhưng dio đã ném [DioException] cho các response lỗi nên
/// [ApiResponse] chỉ cần parse nhánh thành công.
class ApiResponse<T> {
  const ApiResponse({required this.data, this.message, this.pagination});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromData,
  ) {
    return ApiResponse<T>(
      data: fromData(json['data']),
      message: json['message'] as String?,
      pagination: json['metadata'] == null
          ? null
          : Pagination.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  final T data;
  final String? message;
  final Pagination? pagination;
}

class Pagination {
  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;
}
