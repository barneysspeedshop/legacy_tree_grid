import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/unified_data_grid.dart';
export 'unified_data_grid.dart' show DataColumnDef, FilterType, ItemToMap, IsItemDeleted;

/// A reusable data grid widget that handles fetching, client-side filtering,
/// sorting, and pagination for a list of data.
///
/// This is a wrapper around [UnifiedDataGrid] configured for client-side operations,
/// preserving the original API for backward compatibility.
class ClientSideDataGrid<T> extends StatefulWidget {
  /// A function that fetches the entire list of data from a source.
  /// Either this or [data] must be provided.
  final Future<List<T>> Function()? fetchData;
  /// A static list of data to display. The grid will update if this list changes.
  /// Either this or [fetchData] must be provided.
  final List<T>? data;
  final List<DataColumnDef> columnDefs;
  final ItemToMap<T> toMap;
  final String rowIdKey;
  /// A function that determines if an item is considered "deleted".
  /// Required if [showDeletedToggle] is true.
  final IsItemDeleted<T>? isDeleted;
  final int pageSize;
  final DataColumnDef? idColumnDef;
  final VoidCallback? onAdd;
  final Future<void> Function(Set<String> selectedIds)? onDelete;
  final void Function(Map<String, dynamic> rowData)? onRowTap;
  final bool showCheckboxColumn;
  final bool showDeletedToggle;
  final bool allowFiltering;
  final bool allowColumnResize;
  final String? initialSortColumnId;
  final bool initialSortAscending;

  const ClientSideDataGrid({
    super.key,
    this.fetchData,
    this.data,
    required this.columnDefs,
    required this.toMap,
    required this.rowIdKey,
    this.pageSize = 25,
    this.idColumnDef,
    this.isDeleted,
    this.onAdd,
    this.onDelete,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.showDeletedToggle = false,
    this.allowFiltering = true,
    this.allowColumnResize = true,
    this.initialSortColumnId,
    this.initialSortAscending = true,
  })  : assert((fetchData != null && data == null) || (fetchData == null && data != null),
            'Either `fetchData` or `data` must be provided, but not both.'),
        assert(!showDeletedToggle || isDeleted != null,
            'The `isDeleted` function must be provided if `showDeletedToggle` is true.');

  @override
  ClientSideDataGridState<T> createState() => ClientSideDataGridState<T>();
}

/// The state for [ClientSideDataGrid].
///
/// This state class is exposed to allow external widgets to call methods like [refresh]
/// via a [GlobalKey]. It acts as a proxy to the underlying [UnifiedDataGrid].
class ClientSideDataGridState<T> extends State<ClientSideDataGrid<T>> {
  final GlobalKey<UnifiedDataGridState<T>> _gridKey = GlobalKey();

  /// Public method to allow external widgets to trigger a data refresh.
  /// This is only effective if the grid was provided with a `fetchData` function.
  Future<void> refresh() async {
    await _gridKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDataGrid<T>(
      key: _gridKey,
      mode: DataGridMode.client,
      clientData: widget.data,
      clientFetch: widget.fetchData,
      columnDefs: widget.columnDefs,
      toMap: widget.toMap,
      rowIdKey: widget.rowIdKey,
      pageSize: widget.pageSize,
      idColumnDef: widget.idColumnDef,
      onAdd: widget.onAdd,
      onDelete: widget.onDelete,
      onRowTap: widget.onRowTap,
      showCheckboxColumn: widget.showCheckboxColumn,
      allowFiltering: widget.allowFiltering,
      allowColumnResize: widget.allowColumnResize,
      initialSortColumnId: widget.initialSortColumnId,
      initialSortAscending: widget.initialSortAscending,
      // Client-specific properties
      showDeletedToggle: widget.showDeletedToggle,
      isDeleted: widget.isDeleted,
    );
  }
}