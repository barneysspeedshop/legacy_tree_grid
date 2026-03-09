import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/src/widgets/unified_data_grid.dart';
export 'package:legacy_tree_grid/src/widgets/unified_data_grid.dart'
    show DataColumnDef, FilterType, ItemToMap;
export 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart'
    show DataGridFetchOptions;
export 'package:legacy_tree_grid/src/models/paginated_data_response.dart'
    show PaginatedDataResponse;

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
  final void Function(Map<String, dynamic> rowData)? onRowDoubleTap;
  final bool showCheckboxColumn;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final List<WidgetBuilder>? footerLeadingWidgets;
  final bool allowColumnResize;
  final String? initialSortColumnId;
  final bool initialSortAscending;
  final bool isUndeleteMode;
  final bool? serverShowDeletedValue;
  final ValueChanged<bool>? onServerShowDeletedChanged;
  final double dataRowHeight;
  final double? filterRowHeight;
  final double headerHeight;
  final bool allowFiltering;
  final bool showFilterCellBorder;
  final TableBorder? border;
  final Widget? treeIconExpanded;
  final Widget? treeIconCollapsed;
  final bool isTree;
  final String? parentIdKey;
  final dynamic rootValue;
  final Set<String>? initialExpandedRowIds;
  final String? isExpandedKey;
  final void Function(String rowId, bool isExpanded)? onRowToggle;
  final double scale;
  final bool useAvailableWidthDistribution;

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
    this.onRowDoubleTap,
    this.showCheckboxColumn = false,
    this.selectedRowIds,
    this.onSelectionChanged,
    this.footerLeadingWidgets,
    this.allowColumnResize = true,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.isUndeleteMode = false,
    this.serverShowDeletedValue,
    this.onServerShowDeletedChanged,
    this.dataRowHeight = 56.0,
    this.filterRowHeight,
    this.headerHeight = 56.0,
    this.allowFiltering = true,
    this.showFilterCellBorder = true,
    this.border,
    this.treeIconExpanded,
    this.treeIconCollapsed,
    this.isTree = false,
    this.parentIdKey,
    this.rootValue,
    this.initialExpandedRowIds,
    this.isExpandedKey,
    this.onRowToggle,
    this.scale = 1.0,
    this.useAvailableWidthDistribution = false,
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
      onRowDoubleTap: widget.onRowDoubleTap,
      showCheckboxColumn: widget.showCheckboxColumn,
      selectedRowIds: widget.selectedRowIds,
      onSelectionChanged: widget.onSelectionChanged,
      footerLeadingWidgets: widget.footerLeadingWidgets,
      allowColumnResize: widget.allowColumnResize,
      initialSortColumnId: widget.initialSortColumnId,
      initialSortAscending: widget.initialSortAscending,
      isUndeleteMode: widget.isUndeleteMode,
      serverShowDeletedValue: widget.serverShowDeletedValue,
      onServerShowDeletedChanged: widget.onServerShowDeletedChanged,
      dataRowHeight: widget.dataRowHeight,
      filterRowHeight: widget.filterRowHeight,
      headerHeight: widget.headerHeight,
      allowFiltering: widget.allowFiltering,
      showFilterCellBorder: widget.showFilterCellBorder,
      border: widget.border,
      treeIconExpanded: widget.treeIconExpanded,
      treeIconCollapsed: widget.treeIconCollapsed,
      isTree: widget.isTree,
      parentIdKey: widget.parentIdKey,
      rootValue: widget.rootValue,
      initialExpandedRowIds: widget.initialExpandedRowIds,
      isExpandedKey: widget.isExpandedKey,
      onRowToggle: widget.onRowToggle,
      scale: widget.scale,
      useAvailableWidthDistribution: widget.useAvailableWidthDistribution,
    );
  }
}
