/// A generic class that represents a paginated response from an API.
///
/// It contains the data for the current page along with pagination metadata.
/// This structure is based on the Spring Data JPA pageable response format.
class PaginatedDataResponse<T> {
  /// The list of items for the current page.
  final List<T> content;

  /// The total number of records across all pages.
  final int totalElements;

  /// The total number of pages available.
  final int totalPages;

  /// Whether this is the last page.
  final bool last;

  /// Whether this is the first page.
  final bool first;

  /// The number of records per page.
  final int size;

  /// The current page number (0-indexed).
  final int number;

  /// The number of elements in the current page.
  final int numberOfElements;

  /// Whether the current page is empty.
  final bool empty;

  PaginatedDataResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
    required this.size,
    required this.number,
    required this.numberOfElements,
    required this.empty,
  });

  factory PaginatedDataResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final contentList = json['content'] as List;
    final items = contentList.map((itemJson) => fromJsonT(itemJson)).toList();

    return PaginatedDataResponse<T>(
      content: items,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
      size: json['size'] as int,
      number: json['number'] as int,
      numberOfElements: json['numberOfElements'] as int,
      empty: json['empty'] as bool,
    );
  }

  /// Creates an empty PaginatedDataResponse.
  ///
  /// Useful for initializing the data grid or handling error states where
  /// no data can be displayed.
  /// [page] is the 1-indexed page number from the grid options.
  factory PaginatedDataResponse.empty({
    required int pageSize,
    required int page,
  }) {
    return PaginatedDataResponse(
      content: [],
      totalElements: 0,
      totalPages: 1,
      last: true,
      first: true,
      size: pageSize,
      number: page - 1, // Convert 1-indexed page to 0-indexed number
      numberOfElements: 0,
      empty: true,
    );
  }
}
