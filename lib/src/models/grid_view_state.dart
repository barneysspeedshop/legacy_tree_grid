import 'dart:convert';

/// A data class that represents the serializable state of the [UnifiedDataGrid].
///
/// This class encapsulates various UI and data-related states of the grid,
/// such as column widths, column order, sorting, and filtering. It is designed
/// to be easily converted to and from JSON, allowing developers to save and
/// load custom grid layouts and views.
class GridViewState {
  /// A map where the key is the column ID and the value is the column's width.
  final Map<String, double> columnWidths;

  /// An ordered list of column IDs, representing the display order of columns.
  final List<String> columnOrder;

  /// A map of active filters, where the key is the column ID and the value is
  /// the filter string.
  final Map<String, String> filters;

  /// The ID of the column currently being sorted.
  final String? sortColumnId;

  /// The direction of the current sort. `true` for ascending, `false` for descending.
  final bool sortAscending;

  const GridViewState({
    required this.columnWidths,
    required this.columnOrder,
    required this.filters,
    this.sortColumnId,
    this.sortAscending = true,
  });

  /// Creates a [GridViewState] instance from a JSON map.
  factory GridViewState.fromJson(Map<String, dynamic> json) {
    return GridViewState(
      columnWidths: (json['columnWidths'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      columnOrder: List<String>.from(json['columnOrder'] as List),
      filters: Map<String, String>.from(json['filters'] as Map),
      sortColumnId: json['sortColumnId'] as String?,
      sortAscending: json['sortAscending'] as bool? ?? true,
    );
  }

  /// Converts the [GridViewState] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'columnWidths': columnWidths,
      'columnOrder': columnOrder,
      'filters': filters,
      'sortColumnId': sortColumnId,
      'sortAscending': sortAscending,
    };
  }

  /// Converts the [GridViewState] instance to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Creates a [GridViewState] instance from a JSON string.
  factory GridViewState.fromJsonString(String jsonString) {
    return GridViewState.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}