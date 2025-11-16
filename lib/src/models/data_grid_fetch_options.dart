/// A data class that encapsulates the options for fetching data for a data grid.
///
library;
import 'dart:convert';

/// This is used to pass pagination, sorting, and filtering information from the
/// [ServerSideDataGrid] to the data fetching callback.
class DataGridFetchOptions {
  /// The page number to fetch (1-based).
  final int page;

  /// The number of records to fetch per page.
  final int pageSize;

  /// The ID of the column to sort by.
  final String? sortBy;

  /// The direction of the sort. `true` for ascending, `false` for descending.
  final bool sortAscending;

  /// A map of filters, where the key is the column ID and the value is the filter string.
  final Map<String, String> filters;

  const DataGridFetchOptions(
      {required this.page,
      required this.pageSize,
      this.sortBy,
      this.sortAscending = true,
      this.filters = const {}});

  DataGridFetchOptions copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? sortAscending,
    Map<String, String>? filters,
  }) {
    return DataGridFetchOptions(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      filters: filters ?? this.filters,
    );
  }

  /// Converts the fetch options into a map of query parameters suitable for the API.
  Map<String, dynamic> toQueryParameters({
    List<Map<String, dynamic>>? defaultFilter,
  }) {
    final Map<String, dynamic> params = {};

    // API is 1-based for page, 0-based for start
    params['page'] = page;
    params['start'] = (page - 1) * pageSize;
    params['size'] = pageSize;

    if (sortBy != null) {
      params['sort'] = '$sortBy,${sortAscending ? 'ASC' : 'DESC'}';
    }

    // Convert the simple Map<String, String> filters to the API's expected format.
    final List<Map<String, dynamic>> apiFilters = filters.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => {'property': e.key, 'value': e.value})
        .toList();

    final allFilters = [...(defaultFilter ?? []), ...apiFilters];

    if (allFilters.isNotEmpty) {
      params['filter'] = jsonEncode(allFilters);
    }
    return params;
  }
}