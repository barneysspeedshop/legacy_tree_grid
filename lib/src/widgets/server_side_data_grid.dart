import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/src/widgets/unified_data_grid.dart';
export 'package:legacy_tree_grid/src/widgets/unified_data_grid.dart' show DataColumnDef, FilterType, ItemToMap;
export 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart' show DataGridFetchOptions;
export 'package:legacy_tree_grid/src/models/paginated_data_response.dart' show PaginatedDataResponse;

/// A function that fetches a paginated list of data from the server.
typedef FetchDataCallback<T> = ServerFetchDataCallback<T>;

/// A data grid that handles server-side fetching, filtering, sorting, and pagination.
///
/// This is now a wrapper around [UnifiedDataGrid] configured for server-side operations,
/// preserving the original API for backward compatibility.
class ServerSideDataGrid<T> extends StatefulWidget {
  final FetchDataCallback<T> fetchData;
  final List<DataColumnDef> columnDefs;
  final ItemToMap<T> toMap;
  final String rowIdKey;
  final int pageSize;
  final DataColumnDef? idColumnDef;
  final VoidCallback? onAdd;
  final Future<void> Function(Set<String> selectedIds)? onDelete;
  final void Function(Map<String, dynamic> rowData)? onRowTap;
  final bool showCheckboxColumn;
  final List<WidgetBuilder>? footerLeadingWidgets;
  final bool allowColumnResize;
  final String? initialSortColumnId;
  final bool initialSortAscending;
  final bool isUndeleteMode;
  final bool? serverShowDeletedValue;
  final ValueChanged<bool>? onServerShowDeletedChanged;

  const ServerSideDataGrid({
    super.key,
    required this.fetchData,
    required this.columnDefs,
    required this.toMap,
    required this.rowIdKey,
    this.pageSize = 25,
    this.idColumnDef,
    this.onAdd,
    this.onDelete,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.footerLeadingWidgets,
    this.allowColumnResize = true,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.isUndeleteMode = false,
    this.serverShowDeletedValue,
    this.onServerShowDeletedChanged,
  });

  @override
  ServerSideDataGridState<T> createState() => ServerSideDataGridState<T>();
}

/// The state for [ServerSideDataGrid].
///
/// This state class is exposed to allow external widgets to call methods like [refresh]
/// via a [GlobalKey]. It acts as a proxy to the underlying [UnifiedDataGrid].
class ServerSideDataGridState<T> extends State<ServerSideDataGrid<T>> {
  final GlobalKey<UnifiedDataGridState<T>> _gridKey = GlobalKey();

  /// Public method to allow external widgets to trigger a data refresh.
  Future<void> refresh() async {
    await _gridKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDataGrid<T>(
      key: _gridKey,
      mode: DataGridMode.server,
      serverFetch: widget.fetchData,
      columnDefs: widget.columnDefs,
      toMap: widget.toMap,
      rowIdKey: widget.rowIdKey,
      pageSize: widget.pageSize,
      idColumnDef: widget.idColumnDef,
      onAdd: widget.onAdd,
      onDelete: widget.onDelete,
      onRowTap: widget.onRowTap,
      showCheckboxColumn: widget.showCheckboxColumn,
      footerLeadingWidgets: widget.footerLeadingWidgets,
      allowColumnResize: widget.allowColumnResize,
      initialSortColumnId: widget.initialSortColumnId,
      initialSortAscending: widget.initialSortAscending,
      isUndeleteMode: widget.isUndeleteMode,
      serverShowDeletedValue: widget.serverShowDeletedValue,
      onServerShowDeletedChanged: widget.onServerShowDeletedChanged,
    );
  }
}