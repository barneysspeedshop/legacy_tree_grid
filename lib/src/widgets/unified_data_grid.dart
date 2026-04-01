import 'dart:async';
import 'package:legacy_tree_grid/src/models/data_grid_footer_data.dart';
import 'package:legacy_tree_grid/src/models/grid_view_state.dart';
import 'package:flutter/material.dart';
export 'package:legacy_tree_grid/src/models/grid_view_state.dart';
import 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart';
export 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart';
import 'package:legacy_tree_grid/src/models/paginated_data_response.dart';
export 'package:legacy_tree_grid/src/models/paginated_data_response.dart';
import 'package:legacy_tree_grid/src/widgets/custom_data_table.dart';
export 'package:legacy_tree_grid/src/widgets/custom_data_table.dart';
import 'package:legacy_tree_grid/src/widgets/data_grid_footer.dart';
export 'package:legacy_tree_grid/src/widgets/custom_data_table.dart' show DataColumnDef, FilterType;

typedef ItemToMap<T> = Map<String, dynamic> Function(T item);
typedef IsItemDeleted<T> = bool Function(T item);
typedef ServerFetchDataCallback<T> = Future<PaginatedDataResponse<T>> Function(DataGridFetchOptions options);
typedef ClientFetchDataCallback<T> = Future<List<T>> Function();
typedef DataGridFooterBuilder = Widget Function(DataGridFooterData footerData);

enum DataGridMode { client, server }

class UnifiedDataGrid<T> extends StatefulWidget {
  final DataGridMode mode;
  final List<T>? clientData;
  final ClientFetchDataCallback<T>? clientFetch;
  final ServerFetchDataCallback<T>? serverFetch;
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
  final bool showDeletedToggle;
  final bool showDeleted;
  final ValueChanged<bool?>? onShowDeletedChanged;
  final IsItemDeleted<T>? isDeleted;
  final bool? serverShowDeletedValue;
  final ValueChanged<bool>? onServerShowDeletedChanged;
  final bool allowFiltering;
  final List<WidgetBuilder>? footerLeadingWidgets;
  final DataGridFooterBuilder? footerBuilder;
  final bool allowColumnResize;
  final String? initialSortColumnId;
  final bool initialSortAscending;
  final bool allowSorting;
  final bool isUndeleteMode;
  final TableBorder? border;
  final bool showFooter;
  final bool showFilterCellBorder;
  final bool allowIncludeChildrenInFilterToggle;
  final bool useAvailableWidthDistribution;
  final bool isTree;
  final String? parentIdKey;
  final dynamic rootValue;
  final Set<String>? initialExpandedRowIds;
  final String? isExpandedKey;
  final void Function(String rowId, bool isExpanded)? onRowToggle;
  final String? hasChildrenKey;
  final Widget? treeIconExpanded;
  final Widget? treeIconCollapsed;
  final Color? rowHoverColor;
  final GridViewState? initialViewState;
  final double headerHeight;
  final double? filterRowHeight;
  final double Function(Map<String, dynamic> rowData)? rowHeightBuilder;
  final List<WidgetBuilder>? headerTrailingWidgets;
  final ScrollController? scrollController;
  final String? selectedRowId;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final void Function(String draggedRowId, String? targetRowId, bool isAfter)? onReorder;
  final void Function(String draggedRowId, String targetParentRowId)? onNest;
  final double scale;
  final double dataRowHeight;

  const UnifiedDataGrid({
    super.key,
    required this.mode,
    this.clientData,
    this.clientFetch,
    this.serverFetch,
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
    this.showDeletedToggle = false,
    this.showDeleted = false,
    this.onShowDeletedChanged,
    this.isDeleted,
    this.serverShowDeletedValue,
    this.onServerShowDeletedChanged,
    this.allowFiltering = true,
    this.footerLeadingWidgets,
    this.footerBuilder,
    this.allowColumnResize = true,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.allowSorting = true,
    this.isUndeleteMode = false,
    this.border,
    this.showFooter = true,
    this.showFilterCellBorder = true,
    this.allowIncludeChildrenInFilterToggle = true,
    this.useAvailableWidthDistribution = false,
    this.isTree = false,
    this.parentIdKey,
    this.rootValue,
    this.initialExpandedRowIds,
    this.isExpandedKey,
    this.onRowToggle,
    this.hasChildrenKey,
    this.treeIconExpanded,
    this.treeIconCollapsed,
    this.rowHoverColor,
    this.initialViewState,
    this.headerHeight = 56.0,
    this.filterRowHeight,
    this.rowHeightBuilder,
    this.headerTrailingWidgets,
    this.scrollController,
    this.selectedRowId,
    this.selectedRowIds,
    this.onSelectionChanged,
    this.onReorder,
    this.onNest,
    this.scale = 1.0,
    this.dataRowHeight = 25.0,
  }) : assert(!showDeletedToggle || isDeleted != null),
       assert(mode == DataGridMode.client ? (clientData == null || clientFetch == null) : true);

  @override
  State<UnifiedDataGrid<T>> createState() => UnifiedDataGridState<T>();
}

class UnifiedDataGridState<T> extends State<UnifiedDataGrid<T>> {
  late ScrollController _gridScrollController;
  bool _isLoading = true;
  Set<String> _selectedRowIds = {};
  int _currentPage = 1;
  String? _sortColumnId;
  bool _sortAscending = true;
  final Map<String, TextEditingController> _filterControllers = {};
  final List<double> _columnWidths = [];
  final Map<String, String> _filterValues = {};
  List<String>? _columnOrder;
  List<T> _allData = [];
  late Set<String> _expandedRowIds;
  PaginatedDataResponse<T>? _paginatedData;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _gridScrollController = widget.scrollController ?? ScrollController(debugLabel: 'UnifiedDataGrid');
    _expandedRowIds = widget.initialExpandedRowIds != null ? Set.from(widget.initialExpandedRowIds!) : {};
    _selectedRowIds = widget.selectedRowIds != null ? Set.from(widget.selectedRowIds!) : (widget.selectedRowId != null ? {widget.selectedRowId!} : {});

    if (widget.initialViewState != null) {
      applyViewState(widget.initialViewState!);
      _columnOrder = widget.initialViewState!.columnOrder;
    } else {
      _sortColumnId = widget.initialSortColumnId;
      _sortAscending = widget.initialSortAscending;
    }

    if (widget.mode == DataGridMode.client) {
      if (widget.clientFetch != null) {
        _refreshClientData();
      } else {
        _setDataFromWidget(clearSelection: false);
      }
    } else {
      _fetchDataFromServer();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.scrollController == null) _gridScrollController.dispose();
    for (var controller in _filterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnifiedDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      if (oldWidget.scrollController == null) _gridScrollController.dispose();
      _gridScrollController = widget.scrollController ?? ScrollController();
    }
    if (widget.selectedRowId != oldWidget.selectedRowId) {
      setState(() => _selectedRowIds = widget.selectedRowId != null ? {widget.selectedRowId!} : {});
    }
    if (widget.selectedRowIds != oldWidget.selectedRowIds) {
      setState(() => _selectedRowIds = widget.selectedRowIds != null ? Set.from(widget.selectedRowIds!) : {});
    }
    if (widget.mode == DataGridMode.client && widget.clientData != null) {
      _setDataFromWidget(clearSelection: false);
    }
  }

  void applyViewState(GridViewState viewState) {
    setState(() {
      _sortColumnId = viewState.sortColumnId;
      _sortAscending = viewState.sortAscending;
      _filterValues.clear();
      _filterValues.addAll(viewState.filters);
      // Update controllers if they exist
      for (var entry in _filterValues.entries) {
        if (_filterControllers.containsKey(entry.key)) {
          _filterControllers[entry.key]!.text = entry.value;
        }
      }
      if (widget.mode == DataGridMode.server) _fetchDataFromServer(page: 1);
    });
  }

  GridViewState getCurrentViewState() {
    final defs = _getFinalColumnDefs();
    final widths = _columnWidths.length == defs.length ? _columnWidths : List.filled(defs.length, 0.0);
    return GridViewState(
      columnWidths: Map.fromIterables(defs.map((c) => c.id), widths),
      columnOrder: defs.map((c) => c.id).toList(),
      filters: _filterValues,
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
    );
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (widget.mode == DataGridMode.client) {
      await _refreshClientData();
    } else {
      await _fetchDataFromServer(showLoading: showLoading);
    }
  }

  void _setDataFromWidget({bool clearSelection = true}) {
    setState(() {
      _isLoading = false;
      _allData = widget.clientData ?? [];
      _currentPage = 1;
      if (clearSelection) _selectedRowIds.clear();
    });
  }

  Future<void> _refreshClientData() async {
    if (widget.clientFetch == null) return;
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _selectedRowIds.clear();
    });
    try {
      final data = await widget.clientFetch!();
      if (mounted) {
        setState(() {
          _allData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDataFromServer({int? page, bool showLoading = true}) async {
    if (!mounted || widget.serverFetch == null) return;
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _selectedRowIds.clear();
      });
    }
    final options = DataGridFetchOptions(
      page: page ?? _currentPage,
      pageSize: widget.pageSize,
      sortBy: _sortColumnId,
      sortAscending: _sortAscending,
      filters: Map.of(_filterValues)..removeWhere((_, v) => v.trim().isEmpty),
      expandedRowIds: Set.unmodifiable(_expandedRowIds),
    );
    try {
      final data = await widget.serverFetch!(options);
      if (mounted) {
        setState(() {
          _paginatedData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSort(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = true;
      }
      if (widget.mode == DataGridMode.server) _fetchDataFromServer(page: 1);
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      if (widget.mode == DataGridMode.server) _fetchDataFromServer(page: page);
    });
  }

  void _updateSelection(Set<String> newSelection) {
    setState(() => _selectedRowIds = newSelection);
    widget.onSelectionChanged?.call(newSelection);
  }

  void _handleColumnWidthsChanged(List<double> newWidths) {
    _columnWidths.clear();
    _columnWidths.addAll(newWidths);
  }

  void expandRow(String rowId) => _onToggleExpansion(rowId, true);
  void collapseRow(String rowId) => _onToggleExpansion(rowId, false);
  void setRowExpansion(String rowId, bool expanded) => _onToggleExpansion(rowId, expanded);

  void _onToggleExpansion(String rowId, [bool? expanded]) {
    setState(() {
      final isCurrentlyExpanded = _expandedRowIds.contains(rowId);
      final newValue = expanded ?? !isCurrentlyExpanded;
      if (newValue) {
        _expandedRowIds.add(rowId);
      } else {
        _expandedRowIds.remove(rowId);
      }
    });

    if (widget.mode == DataGridMode.server) {
      refresh(showLoading: false);
    }

    widget.onRowToggle?.call(rowId, _expandedRowIds.contains(rowId));
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (widget.onReorder == null) return;
    final rows = _getDisplayRows();
    final visibleRows = widget.isTree ? rows.where((r) => r['_isEffectivelyVisible'] == true).toList() : rows;

    if (oldIndex < 0 || oldIndex >= visibleRows.length) return;
    final draggedId = visibleRows[oldIndex][widget.rowIdKey].toString();

    String? targetId;
    bool isAfter = false;

    if (newIndex < visibleRows.length) {
      if (newIndex > oldIndex) {
        // Moving down: dropped after the item that is currently at newIndex - 1 in visibleRows
        targetId = visibleRows[newIndex - 1][widget.rowIdKey].toString();
        isAfter = true;
      } else {
        // Moving up: dropped before the item currently at newIndex
        targetId = visibleRows[newIndex][widget.rowIdKey].toString();
        isAfter = false;
      }
    } else {
      // Dropped at the very end
      targetId = visibleRows.last[widget.rowIdKey].toString();
      isAfter = true;
    }

    widget.onReorder!.call(draggedId, targetId, isAfter);

    if (widget.mode == DataGridMode.server) {
      refresh(showLoading: false);
    }
  }

  void _handleNest(String draggedId, String targetParentId) {
    widget.onNest?.call(draggedId, targetParentId);
    if (widget.mode == DataGridMode.server) {
      refresh(showLoading: false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete != null) {
      await widget.onDelete!(_selectedRowIds);
      refresh();
    }
  }

  List<DataColumnDef> _getFinalColumnDefs() {
    List<DataColumnDef> defs = List.of(widget.columnDefs);
    if (_columnOrder != null) {
      final map = {for (var d in defs) d.id: d};
      defs = _columnOrder!.map((id) => map[id]).whereType<DataColumnDef>().toList();
      for (var d in widget.columnDefs) {
        if (!defs.contains(d)) defs.add(d);
      }
    }
    if (widget.idColumnDef != null) defs.insert(0, widget.idColumnDef!);
    return defs;
  }

  List<Map<String, dynamic>> _getProcessedClientData() {
    List<T> processed = List.from(_allData);
    final activeFilters = Map.from(_filterValues)..removeWhere((_, v) => v.trim().isEmpty);

    if (activeFilters.isNotEmpty) {
      processed = processed.where((item) {
        final row = widget.toMap(item);
        return activeFilters.entries.every((e) {
          final val = _extractValue(row, e.key)?.toString().toLowerCase() ?? '';
          return val.contains(e.value.toLowerCase());
        });
      }).toList();
    }

    if (!widget.isTree && _sortColumnId != null) {
      processed.sort((a, b) {
        dynamic valA = _extractValue(widget.toMap(a), _sortColumnId!);
        dynamic valB = _extractValue(widget.toMap(b), _sortColumnId!);
        if (valA == null || valB == null) return 0;
        int comp = valA is Comparable ? valA.compareTo(valB) : valA.toString().compareTo(valB.toString());
        return _sortAscending ? comp : -comp;
      });
    }
    return processed.map(widget.toMap).toList();
  }

  List<Map<String, dynamic>> _getDisplayRows() {
    if (widget.mode == DataGridMode.client) {
      final processed = _getProcessedClientData();
      if (widget.isTree) {
        return _buildTree(processed);
      } else {
        return processed.skip((_currentPage - 1) * widget.pageSize).take(widget.pageSize).toList();
      }
    } else {
      final data = _paginatedData?.content.map(widget.toMap).toList() ?? [];
      return widget.isTree ? _buildTree(data) : data;
    }
  }

  List<Map<String, dynamic>> _buildTree(List<Map<String, dynamic>> flatData) {
    if (widget.parentIdKey == null) return flatData;
    List<Map<String, dynamic>> tree = [];
    void addChildren(dynamic parentId, int level, bool parentVisible) {
      final children = flatData.where((d) => d[widget.parentIdKey] == parentId).toList();
      for (var child in children) {
        final id = child[widget.rowIdKey].toString();
        // For server-side, favor the server-provided hasChildren flag if available.
        final serverHasChildren = child[widget.hasChildrenKey ?? 'hasChildren'];
        final hasChildren = serverHasChildren is bool ? serverHasChildren : flatData.any((d) => d[widget.parentIdKey] == id);
        final expanded = _expandedRowIds.contains(id);
        
        child['_indentationLevel'] = level;
        child[widget.isExpandedKey ?? 'expanded'] = expanded;
        child[widget.hasChildrenKey ?? 'hasChildren'] = hasChildren;
        child['_isEffectivelyVisible'] = parentVisible;
        
        tree.add(child);
        addChildren(id, level + 1, parentVisible && expanded);
      }
    }

    addChildren(widget.rootValue, 0, true);
    return tree;
  }

  dynamic _extractValue(Map<String, dynamic> data, String path) {
    if (!path.contains('.')) return data[path];
    List<String> parts = path.split('.');
    dynamic current = data;
    for (var p in parts) {
      if (current is Map) {
        current = current[p];
      } else {
        return null;
      }
    }
    return current;
  }

  Widget _buildFilterRow(BuildContext context, List<DataColumnDef> columns, List<double> columnWidths) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(columns.length, (index) {
        final col = columns[index];
        final width = columnWidths[index];

        if (!_filterControllers.containsKey(col.id)) {
          _filterControllers[col.id] = TextEditingController(text: _filterValues[col.id]);
        }
        final controller = _filterControllers[col.id]!;

        Widget filterWidget;
        if (col.filterType == FilterType.none) {
          filterWidget = const SizedBox.shrink();
        } else {
          filterWidget = Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0 * widget.scale, vertical: 2.0 * widget.scale),
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 12.0 * widget.scale),
              decoration: InputDecoration(
                hintText: 'Filter ${col.caption}...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8 * widget.scale, horizontal: 4 * widget.scale),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _filterValues[col.id] = value;
                    if (widget.mode == DataGridMode.server) {
                      _fetchDataFromServer(page: 1);
                    }
                  });
                });
              },
            ),
          );
        }

        return Row(
          children: [
            SizedBox(width: width, child: filterWidget),
            VerticalDivider(
              width: (widget.allowColumnResize && index < columns.length - 1 && col.resizable && columns[index + 1].resizable) ? 10.0 : 1.0,
              thickness: 0.5,
              color: widget.border?.verticalInside.color ?? Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ],
        );
      }).expand((w) => [w.children[0], w.children[1]]).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _getDisplayRows();
    final visibleRows = widget.isTree ? rows.where((r) => r['_isEffectivelyVisible'] == true).toList() : rows;

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomDataTable(
                  scrollController: _gridScrollController,
                  columns: _getFinalColumnDefs(),
                  rows: visibleRows,
                  rowIdKey: widget.rowIdKey,
                  dataRowHeight: widget.dataRowHeight,
                  headerHeight: widget.headerHeight,
                  filterRowHeight: widget.filterRowHeight,
                  rowHeightBuilder: widget.rowHeightBuilder,
                  border: widget.border,
                  allowFiltering: widget.allowFiltering,
                  filterRowBuilder: _buildFilterRow,
                  onRowTap: widget.onRowTap,
                  onRowDoubleTap: widget.onRowDoubleTap,
                  onSort: widget.allowSorting ? _handleSort : null,
                  sortColumnId: _sortColumnId,
                  sortAscending: _sortAscending,
                  showCheckboxColumn: widget.showCheckboxColumn,
                  selectedRowIds: _selectedRowIds,
                  onSelectionChanged: _updateSelection,
                  isTree: widget.isTree,
                  onToggleExpansion: _onToggleExpansion,
                  allowColumnResize: widget.allowColumnResize,
                  onColumnWidthsChanged: _handleColumnWidthsChanged,
                  headerTrailingWidgets: widget.headerTrailingWidgets,
                  rowHoverColor: widget.rowHoverColor,
                  useAvailableWidthDistribution: widget.useAvailableWidthDistribution,
                  treeIconCollapsed: widget.treeIconCollapsed,
                  treeIconExpanded: widget.treeIconExpanded,
                  onReorder: widget.onReorder != null ? (oldIdx, newIdx) => _handleReorder(oldIdx, newIdx) : null,
                  onNest: _handleNest,
                  indentationLevelKey: '_indentationLevel',
                  isEffectivelyVisibleKey: '_isEffectivelyVisible',
                  isExpandedKey: widget.isExpandedKey ?? 'expanded',
                  hasChildrenKey: widget.hasChildrenKey ?? 'hasChildren',
                  scale: widget.scale,
                ),
        ),
        if (widget.showFooter)
          DataGridFooter(
            currentPage: _currentPage,
            pageSize: widget.pageSize,
            totalRecords: widget.mode == DataGridMode.client ? _allData.length : (_paginatedData?.totalElements ?? 0),
            totalPages: widget.mode == DataGridMode.client ? (_allData.length / widget.pageSize).ceil() : (_paginatedData?.totalPages ?? 1),
            onPageChanged: _onPageChanged,
            onRefresh: refresh,
            onAdd: widget.onAdd,
            onDelete: widget.onDelete != null && _selectedRowIds.isNotEmpty ? _handleDelete : null,
          ),
      ],
    );
  }
}
