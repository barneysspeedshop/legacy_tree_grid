import 'package:flutter/material.dart';
import 'unified_data_grid.dart';
export 'unified_data_grid.dart'
    show DataColumnDef, FilterType, ItemToMap, IsItemDeleted;

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
  final void Function(Map<String, dynamic> rowData)? onRowDoubleTap;
  final bool showCheckboxColumn;
  final bool showDeletedToggle;
  final bool showDeleted;
  final ValueChanged<bool?>? onShowDeletedChanged;
  final bool allowFiltering;
  final bool allowColumnResize;
  final String? initialSortColumnId;
  final bool initialSortAscending;
  final bool isTree;
  final String? parentIdKey;
  final Widget? treeIconExpanded;
  final Widget? treeIconCollapsed;
  final Set<String>? initialExpandedRowIds;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final String? selectedRowId; // Re-added field
  final void Function(String draggedRowId, String? targetRowId, bool isAfter)? onReorder;
  final void Function(String draggedRowId, String targetParentRowId)? onNest;
  final List<WidgetBuilder>? footerLeadingWidgets;
  final bool showFooter;
  final double scale;
  final double dataRowHeight;
  final double headerHeight;
  final double? filterRowHeight;
  final bool showFilterCellBorder;
  final TableBorder? border;
  final bool useAvailableWidthDistribution;

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
    this.onRowDoubleTap,
    this.showCheckboxColumn = false,
    this.showDeletedToggle = false,
    this.showDeleted = false,
    this.onShowDeletedChanged,
    this.allowFiltering = true,
    this.scale = 1.0,
    this.dataRowHeight = 25.0,
    this.allowColumnResize = true,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.selectedRowId, // Keep for backward compatibility
    this.isTree = false,
    this.parentIdKey,
    this.treeIconExpanded,
    this.treeIconCollapsed,
    this.initialExpandedRowIds,
    this.selectedRowIds,
    this.onSelectionChanged,
    this.onReorder,
    this.onNest,
    this.footerLeadingWidgets,
    this.showFooter = true,
    this.headerHeight = 56.0,
    this.filterRowHeight,
    this.showFilterCellBorder = true,
    this.border,
    this.useAvailableWidthDistribution = false,
  }) : assert(
         (fetchData != null && data == null) ||
             (fetchData == null && data != null),
         'Either `fetchData` or `data` must be provided, but not both.',
       ),
       assert(
         !showDeletedToggle || isDeleted != null,
         'The `isDeleted` function must be provided if `showDeletedToggle` is true.',
       ),
       assert(
         !isTree || parentIdKey != null,
         'If `isTree` is true, `parentIdKey` must be provided.',
       );

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

  void expandRow(String rowId) => _gridKey.currentState?.expandRow(rowId);
  void collapseRow(String rowId) => _gridKey.currentState?.collapseRow(rowId);
  void setRowExpansion(String rowId, bool expanded) => _gridKey.currentState?.setRowExpansion(rowId, expanded);

  /// Public method to get the current grid view state.
  GridViewState? getCurrentViewState() {
    return _gridKey.currentState?.getCurrentViewState();
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
      onAdd: widget.onAdd, // UnifiedDataGrid handles formatting
      onDelete: widget.onDelete,
      onRowTap: widget.onRowTap,
      onRowDoubleTap: widget.onRowDoubleTap,
      showCheckboxColumn: widget.showCheckboxColumn,
      allowFiltering: widget.allowFiltering,
      allowColumnResize: widget.allowColumnResize,
      initialSortColumnId: widget.initialSortColumnId,
      initialSortAscending: widget.initialSortAscending,
      // Client-specific properties
      showDeletedToggle: widget.showDeletedToggle,
      showDeleted: widget.showDeleted,
      onShowDeletedChanged: widget.onShowDeletedChanged,
      isDeleted: widget.isDeleted,
      selectedRowIds: widget.selectedRowIds,
      selectedRowId: widget.selectedRowIds == null
          ? widget.selectedRowId
          : null,
      onReorder: widget.onReorder,
      onNest: widget.onNest,
      // Tree & Selection properties
      isTree: widget.isTree,
      parentIdKey: widget.parentIdKey,
      treeIconExpanded: widget.treeIconExpanded,
      treeIconCollapsed: widget.treeIconCollapsed,
      initialExpandedRowIds: widget.initialExpandedRowIds,
      onSelectionChanged: widget.onSelectionChanged,
      footerLeadingWidgets: widget.footerLeadingWidgets,
      showFooter: widget.showFooter,
      scale: widget.scale,
      dataRowHeight: widget.dataRowHeight,
      headerHeight: widget.headerHeight,
      filterRowHeight: widget.filterRowHeight,
      showFilterCellBorder: widget.showFilterCellBorder,
      border: widget.border,
      useAvailableWidthDistribution: widget.useAvailableWidthDistribution,
    );
  }
}
