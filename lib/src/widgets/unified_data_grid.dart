import 'dart:async';
import 'package:legacy_tree_grid/src/models/data_grid_footer_data.dart';
import 'package:legacy_tree_grid/src/models/grid_view_state.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
export 'package:legacy_tree_grid/src/models/grid_view_state.dart';
import 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart';
export 'package:legacy_tree_grid/src/models/data_grid_fetch_options.dart';
import 'package:legacy_tree_grid/src/models/paginated_data_response.dart';
export 'package:legacy_tree_grid/src/models/paginated_data_response.dart';
import 'package:legacy_tree_grid/src/widgets/custom_data_table.dart';
export 'package:legacy_tree_grid/src/widgets/custom_data_table.dart';
import 'package:legacy_tree_grid/src/widgets/data_grid_footer.dart';
export 'package:legacy_tree_grid/src/widgets/custom_data_table.dart'
    show DataColumnDef, FilterType;

/// A function that converts a model of type T to a map for the data table.
typedef ItemToMap<T> = Map<String, dynamic> Function(T item);

/// A function that checks if a model of type T is marked as deleted.
typedef IsItemDeleted<T> = bool Function(T item);

/// A function that fetches a paginated list of data from the server.
typedef ServerFetchDataCallback<T> =
    Future<PaginatedDataResponse<T>> Function(DataGridFetchOptions options);

/// A function that builds a custom footer widget for the data grid.
/// It provides [DataGridFooterData] which contains all the necessary state
/// and callbacks for the footer to interact with the grid.
typedef DataGridFooterBuilder = Widget Function(DataGridFooterData footerData);

/// A function that fetches the entire list of data from a source for client-side processing.
typedef ClientFetchDataCallback<T> = Future<List<T>> Function();

/// Enum to determine the operational mode of the data grid.
enum DataGridMode {
  /// The grid handles all filtering, sorting, and pagination in the client.
  client,

  /// The grid sends filtering, sorting, and pagination options to the server.
  server,
}

/// A unified, reusable data grid widget that supports both client-side and
/// server-side data operations.
class UnifiedDataGrid<T> extends StatefulWidget {
  /// The operational mode of the grid.
  final DataGridMode mode;

  // --- Data Sources (provide one based on mode) ---

  /// [Client-side] A static list of data to display. The grid will update if this list changes.
  /// Use with `mode = DataGridMode.client`.
  final List<T>? clientData;

  /// [Client-side] A function that fetches the entire list of data from a source.
  /// Use with `mode = DataGridMode.client`.
  final ClientFetchDataCallback<T>? clientFetch;

  /// [Server-side] A function that fetches a page of data from a remote source.
  /// Use with `mode = DataGridMode.server`.
  final ServerFetchDataCallback<T>? serverFetch;

  // --- Core Configuration ---

  /// Definitions for the columns to be displayed.
  final List<DataColumnDef> columnDefs;

  /// A function to convert an item of type T into a map for rendering.
  final ItemToMap<T> toMap;

  /// The key in the map from [toMap] that uniquely identifies a row.
  final String rowIdKey;

  /// The number of items to display per page.
  final int pageSize;

  /// An optional definition for the ID column. If provided, its visibility
  /// will be controlled by the global "Show UUIDs" setting.
  final DataColumnDef? idColumnDef;

  // --- Optional Features & Callbacks ---

  /// An optional callback triggered when the "Add" button is pressed.
  /// If null, the button is not shown.
  final VoidCallback? onAdd;

  /// An optional callback triggered when the "Delete" or "Undelete" button is pressed.
  /// It receives a set of the selected row IDs. The grid will refresh its data after this future completes.
  /// If null, the button is not shown.
  final Future<void> Function(Set<String> selectedIds)? onDelete;

  /// A callback triggered when a row is tapped.
  final void Function(Map<String, dynamic> rowData)? onRowTap;

  /// Whether to show the checkbox column for row selection.
  /// Defaults to `false`.
  final bool showCheckboxColumn;

  /// [Client-side] Whether to show the "Show Deleted" toggle in the footer.
  /// If true, [isDeleted] must be provided.
  /// Defaults to `false`.
  final bool showDeletedToggle;

  /// [Client-side] A function that determines if an item is considered "deleted".
  /// Required if [showDeletedToggle] is true.
  final IsItemDeleted<T>? isDeleted;

  /// [Server-side] The current value for the "Show Deleted" toggle.
  /// Use with `mode = DataGridMode.server`. Providing this value will show the toggle.
  final bool? serverShowDeletedValue;

  /// [Server-side] A callback triggered when the "Show Deleted" toggle is changed.
  /// Required if [serverShowDeletedValue] is provided.
  final ValueChanged<bool>? onServerShowDeletedChanged;

  /// Whether to show the filter row below the header.
  /// Defaults to `true`.
  final bool allowFiltering;

  /// A list of widgets to display at the start of the data grid footer.
  /// Useful for adding custom filters or actions.
  final List<WidgetBuilder>? footerLeadingWidgets;

  /// An optional builder to create a custom footer.
  /// If provided, it overrides the default [DataGridFooter].
  final DataGridFooterBuilder? footerBuilder;

  /// Whether to allow users to resize columns by dragging the header dividers.
  /// Defaults to `true`.
  final bool allowColumnResize;

  /// The ID of the column to sort by initially.
  final String? initialSortColumnId;

  /// The initial sort direction. Defaults to `true` (ascending).
  final bool initialSortAscending;

  /// Whether to allow users to sort columns by clicking on the header.
  /// Defaults to `true`.
  final bool allowSorting;

  /// Whether the delete button should be in "undelete" mode (different icon and text).
  /// This is determined by `_showDeleted` in client mode.
  final bool isUndeleteMode;

  /// Whether to show the footer with pagination and action controls.
  /// Defaults to `true`.
  final bool showFooter;

  /// Whether to show the "Include Children" checkbox in the footer when in tree mode.
  /// Defaults to `true`.
  final bool allowIncludeChildrenInFilterToggle;

  // --- Tree Grid Properties ---

  /// If `true`, the grid will operate in tree mode, rendering hierarchical data.
  final bool isTree;

  /// The key in the data map that identifies the parent of a node.
  /// This is required if `isTree` is `true`.
  final String? parentIdKey;

  /// The value in the parent ID field that indicates a node is a root-level node.
  /// Defaults to `null`.
  final dynamic rootValue;

  /// A set of row IDs that should be initially expanded when the grid is in tree mode.
  final Set<String>? initialExpandedRowIds;

  /// Optional key to control expansion state via data.
  final String? isExpandedKey;

  /// A callback function that is invoked when a row's expansion state is toggled in tree mode.
  final void Function(String rowId, bool isExpanded)? onRowToggle;

  /// An optional color for the row hover effect.
  final Color? rowHoverColor;

  /// An optional initial state for the grid, allowing for saved views to be loaded.
  /// If provided, it will override other initial settings like `initialSortColumnId`.
  final GridViewState? initialViewState;

  /// The height of the header row.
  /// Defaults to 56.0.
  final double headerHeight;

  /// An optional builder to dynamically determine the height of each row.
  /// If not provided, `dataRowHeight` from `CustomDataTable` is used.
  final double Function(Map<String, dynamic> rowData)? rowHeightBuilder;

  final List<WidgetBuilder>? headerTrailingWidgets;

  /// An optional scroll controller for the grid's primary scroll view.
  final ScrollController? scrollController;

  /// An optional ID of a row to be programmatically selected.
  final String? selectedRowId;

  const UnifiedDataGrid({
    super.key,
    required this.mode,
    // Data sources
    this.clientData,
    this.clientFetch,
    this.serverFetch,
    // Core config
    required this.columnDefs,
    required this.toMap,
    required this.rowIdKey,
    this.pageSize = 25,
    this.idColumnDef,
    // Optional features
    this.onAdd,
    this.onDelete,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.showDeletedToggle = false,
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
    this.showFooter = true,
    this.allowIncludeChildrenInFilterToggle = true,
    // Tree grid
    this.isTree = false,
    this.parentIdKey,
    this.rootValue,
    this.initialExpandedRowIds,
    this.onRowToggle,
    this.isExpandedKey, // Add this
    this.rowHoverColor,
    this.headerHeight = 56.0,
    this.initialViewState,
    this.rowHeightBuilder,
    this.headerTrailingWidgets,
    this.scrollController,
    this.selectedRowId,
  }) : assert(
         (mode == DataGridMode.client &&
                 (clientData != null || clientFetch != null)) ||
             (mode == DataGridMode.server && serverFetch != null),
         'Provide a data source that matches the selected mode.',
       ),
       assert(
         mode == DataGridMode.client
             ? (clientData == null || clientFetch == null)
             : true,
         'In client mode, either `clientData` or `clientFetch` can be provided, but not both.',
       ),
       assert(
         !showDeletedToggle || isDeleted != null,
         'The `isDeleted` function must be provided if `showDeletedToggle` is true.',
       ),
       assert(
         (serverShowDeletedValue == null) ==
             (onServerShowDeletedChanged == null),
         'In server mode, `serverShowDeletedValue` and `onServerShowDeletedChanged` must be provided together.',
       );

  @override
  State<UnifiedDataGrid<T>> createState() => UnifiedDataGridState<T>();
}

class UnifiedDataGridState<T> extends State<UnifiedDataGrid<T>> {
  // --- Common State ---
  late final ScrollController _gridScrollController;
  bool _isLoading = true;
  Set<String> _selectedRowIds = {};
  int _currentPage = 1;
  String? _sortColumnId;
  bool _sortAscending = true;
  final Map<String, TextEditingController> _filterControllers = {};
  List<double> _columnWidths = [];
  final Map<String, String> _filterValues = {};
  List<String>? _columnOrder;

  // --- Client-Mode State ---
  List<T> _allData = [];
  List<Map<String, dynamic>> _treeData = [];
  late bool _showDeleted;
  late Set<String> _expandedRowIds;
  bool _includeChildrenInFilter = true;

  // --- Server-Mode State ---
  PaginatedDataResponse<T>? _paginatedData;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _gridScrollController =
        widget.scrollController ??
        ScrollController(debugLabel: 'UnifiedDataGrid');

    _expandedRowIds = widget.initialExpandedRowIds ?? {};
    _showDeleted = false;
    _selectedRowIds = widget.selectedRowId != null
        ? {widget.selectedRowId!}
        : {};

    if (widget.initialViewState != null) {
      _applyInitialViewState(widget.initialViewState!);
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
    if (widget.scrollController == null) {
      _gridScrollController.dispose();
    }
    for (var controller in _filterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnifiedDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      if (oldWidget.scrollController == null) {
        _gridScrollController.dispose();
      }
      _gridScrollController = widget.scrollController ?? ScrollController();
    }

    if (widget.selectedRowId != oldWidget.selectedRowId) {
      setState(() {
        _selectedRowIds = widget.selectedRowId != null
            ? {widget.selectedRowId!}
            : {};
      });
    }
    if (widget.mode == DataGridMode.client) {
      if (widget.clientData != null &&
          !listEquals(widget.clientData, oldWidget.clientData)) {
        _setDataFromWidget();
      }
    } else {
      // For server mode, detect if external properties that affect the fetch have changed.
      if (widget.serverFetch != oldWidget.serverFetch) {
        _resetAndRefetchServer();
        return; // A new fetcher means a full reset, no other checks needed.
      }

      // If a server-side filter property changes, reset to page 1 and refetch.
      if (widget.serverShowDeletedValue != oldWidget.serverShowDeletedValue) {
        // We set the state for the page number and then trigger the fetch.
        setState(() => _currentPage = 1);
        _fetchDataFromServer(page: 1);
      }
    }
  }

  void _applyInitialViewState(GridViewState viewState) {
    _sortColumnId = viewState.sortColumnId;
    _sortAscending = viewState.sortAscending;
    _filterValues.addAll(viewState.filters);

    // The column widths will be applied later in CustomDataTable's LayoutBuilder
    // after the final column order is determined.
  }

  /// Returns the current visual state of the grid.
  ///
  /// This can be used to save the user's current view (column widths, order,
  /// filters, and sorting) for later restoration.
  GridViewState getCurrentViewState() {
    // It's generally not recommended to save scroll offset in view state
    // as data can change, making the offset invalid. But if needed, it could be
    // added here: 'scrollOffset: _gridScrollController.offset'.
    return GridViewState(
      columnWidths: Map.fromIterables(
        _getFinalColumnDefs().map((c) => c.id),
        _columnWidths,
      ),
      columnOrder: _getFinalColumnDefs().map((c) => c.id).toList(),
      filters: _filterValues,
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
    );
  }

  /// Exposes the grid's internal scroll controller.
  ScrollController get gridScrollController => _gridScrollController;

  /// Applies a given [GridViewState] to the grid, updating its sorting,
  /// filtering, column order, and widths.
  ///
  /// This method can be called externally via a [GlobalKey] to dynamically
  /// restore a previously saved view without rebuilding the entire widget.
  void applyViewState(GridViewState viewState) {
    setState(() {
      // Apply sorting
      _sortColumnId = viewState.sortColumnId;
      _sortAscending = viewState.sortAscending;

      // Apply filters
      _filterValues.clear();
      _filterValues.addAll(viewState.filters);
      for (final entry in _filterValues.entries) {
        _filterControllers[entry.key]?.text = entry.value;
      }

      // Apply column order and widths
      _columnOrder = viewState.columnOrder;
    });
  }
  // --- ==================== Data Handling Logic ==================== ---

  Future<void> refresh() async {
    if (widget.mode == DataGridMode.client) {
      await _refreshClientData();
    } else {
      await _fetchDataFromServer();
    }
  }

  // --- Client-Mode Data ---
  void _setDataFromWidget({bool clearSelection = true}) {
    setState(() {
      _isLoading = false;
      _allData = widget.clientData ?? [];

      // Sync expansion state if key is provided
      if (widget.isExpandedKey != null && widget.isTree) {
        for (var item in _allData) {
          final map = widget.toMap(item);
          final id = _extractValue(map, widget.rowIdKey).toString();
          final isExpanded = _extractValue(map, widget.isExpandedKey!);
          if (isExpanded == true) {
            _expandedRowIds.add(id);
          } else if (isExpanded == false) {
            _expandedRowIds.remove(id);
          }
        }
      }

      _currentPage = 1;
      if (clearSelection) {
        _selectedRowIds.clear();
      }
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
      if (mounted) {
        //show a snackbar message
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Server-Mode Data ---
  Future<void> _fetchDataFromServer({int? page}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _selectedRowIds.clear();
    });

    final options = DataGridFetchOptions(
      page: page ?? _currentPage,
      pageSize: widget.pageSize,
      sortBy: _sortColumnId,
      sortAscending: _sortAscending,
      filters: Map.of(_filterValues)..removeWhere((_, v) => v.trim().isEmpty),
    );

    try {
      final data = await widget.serverFetch!(options);
      if (mounted) {
        setState(() {
          _paginatedData = data;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      _handleFetchError(e, s);
    }
  }

  Future<void> _resetAndRefetchServer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _selectedRowIds.clear();
      _resetInternalFilters();
    });

    final options = DataGridFetchOptions(
      page: 1,
      pageSize: widget.pageSize,
      sortBy: _sortColumnId,
      sortAscending: _sortAscending,
      filters: const {},
    );

    try {
      final data = await widget.serverFetch!(options);
      if (mounted) {
        setState(() {
          _paginatedData = data;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      _handleFetchError(e, s);
    }
  }

  void _handleFetchError(Object e, StackTrace s) {
    debugPrint('Failed to load grid data: $e\n$s');
    if (mounted) {
      setState(() {
        // When a fetch fails, create an empty response for the *current* page.
        // This prevents the UI from jumping to page 1 and preserves context.
        // We create a "fictional" state where the current page is the last page.
        _paginatedData = PaginatedDataResponse(
          content: [],
          totalElements: (_currentPage - 1) * widget.pageSize,
          totalPages: _currentPage,
          last: true,
          first: _currentPage == 1,
          size: widget.pageSize,
          number: _currentPage - 1, // `number` is 0-indexed
          numberOfElements: 0,
          empty: true,
        );
        _isLoading = false;
      });
      // showTopSnackBar(context, message: 'Failed to load data: $e', isError: true);
    }
  }

  // --- ==================== Tree Data Processing =================== ---

  List<Map<String, dynamic>> _buildTree(List<T> sourceData) {
    final List<Map<String, dynamic>> mappedData = sourceData
        .map((item) => Map<String, dynamic>.from(widget.toMap(item)))
        .toList();
    final Map<String, List<Map<String, dynamic>>> childrenMap = {};
    final Map<String, Map<String, dynamic>> itemMap = {};

    for (final item in mappedData) {
      final id = _extractValue(item, widget.rowIdKey).toString();
      itemMap[id] = item;
      final parentId = _extractValue(item, widget.parentIdKey!)?.toString();
      childrenMap.putIfAbsent(parentId ?? 'root', () => []).add(item);
    }

    final List<Map<String, dynamic>> tree = [];

    void buildHierarchy(String? parentId, int level, bool parentVisible) {
      final children = childrenMap[parentId ?? 'root'] ?? [];

      // Sort children within their hierarchy level
      if (_sortColumnId != null) {
        children.sort((a, b) {
          dynamic valA = _extractValue(a, _sortColumnId!);
          dynamic valB = _extractValue(b, _sortColumnId!);
          if (valA == null && valB == null) return 0;
          if (valA == null) return 1;
          if (valB == null) return -1;
          int compare = valA is Comparable && valB is Comparable
              ? valA.compareTo(valB)
              : valA.toString().compareTo(valB.toString());
          return _sortAscending ? compare : -compare;
        });
      }

      for (final child in children) {
        final childId = _extractValue(child, widget.rowIdKey).toString();
        final isExpanded = _expandedRowIds.contains(childId);
        final isVisible = parentVisible;

        child['_indentationLevel'] = level;
        child['_isEffectivelyVisible'] = isVisible;
        child['leaf'] = (childrenMap[childId]?.isEmpty ?? true);
        child['expanded'] = isExpanded;

        tree.add(child);
        if (childrenMap.containsKey(childId)) {
          buildHierarchy(childId, level + 1, isVisible && isExpanded);
        }
      }
    }

    buildHierarchy(null, 0, true);
    return tree;
  }

  void _onToggleExpansion(String rowId) {
    if (!mounted) return;

    setState(() {
      bool isNowExpanded;
      if (_expandedRowIds.contains(rowId)) {
        _expandedRowIds.remove(rowId);
        isNowExpanded = false;
      } else {
        _expandedRowIds.add(rowId);
        isNowExpanded = true;
      }
      widget.onRowToggle?.call(rowId, isNowExpanded);
    });
  }

  /// Programmatically expands the row with the given [rowId].
  void expandRow(String rowId) {
    setRowExpansion(rowId, true);
  }

  /// Programmatically collapses the row with the given [rowId].
  void collapseRow(String rowId) {
    setRowExpansion(rowId, false);
  }

  /// Programmatically sets the expansion state of the row with the given [rowId].
  void setRowExpansion(String rowId, bool expanded) {
    if (!mounted) return;
    if (expanded == _expandedRowIds.contains(rowId)) return;

    setState(() {
      if (expanded) {
        _expandedRowIds.add(rowId);
      } else {
        _expandedRowIds.remove(rowId);
      }
      widget.onRowToggle?.call(rowId, expanded);
    });
  }

  // --- ==================== Event Handlers ==================== ---

  Future<void> _handleDelete() async {
    if (_selectedRowIds.isEmpty) {
      // showTopSnackBar(context, message: 'Please select one or more items.');
      return;
    }
    if (widget.onDelete != null) {
      await widget.onDelete!(_selectedRowIds);
      await refresh();
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
      if (widget.mode == DataGridMode.server) {
        _currentPage = 1;
        _fetchDataFromServer(page: 1);
      }
    });
  }

  void _onServerFilterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _currentPage != 1) {
        setState(() => _currentPage = 1);
      }
      _fetchDataFromServer(page: 1);
    });
  }

  void _clearFilters() {
    setState(() {
      for (var controller in _filterControllers.values) {
        controller.clear();
      }
      _filterValues.clear();
    });
    if (widget.mode == DataGridMode.server) {
      _resetAndRefetchServer();
    }
  }

  void _resetInternalFilters() {
    for (var controller in _filterControllers.values) {
      controller.clear();
    }
    _filterValues.clear();
  }

  void _onPageChanged(int newPage) {
    if (_currentPage == newPage) return;
    setState(() => _currentPage = newPage);
    if (widget.mode == DataGridMode.server) {
      _fetchDataFromServer(page: newPage);
    }
  }

  // --- ==================== Client-Side Filtering Logic ==================== ---

  List<T> _getProcessedClientData() {
    List<T> processedData = List.of(_allData);

    // 1. Filter by 'Show Deleted'
    if (widget.showDeletedToggle) {
      processedData = processedData
          .where((item) => widget.isDeleted!(item) == _showDeleted)
          .toList();
    }

    // 2. Filter by column values
    final activeFilters = Map.of(_filterValues)
      ..removeWhere((_, value) => value.trim().isEmpty);
    if (activeFilters.isNotEmpty) {
      final finalColumnDefs = List.of(widget.columnDefs);
      if (widget.idColumnDef != null) {
        finalColumnDefs.insert(0, widget.idColumnDef!);
      }

      if (widget.isTree) {
        final itemMap = {
          for (var item in processedData)
            _extractValue(widget.toMap(item), widget.rowIdKey).toString(): item,
        };
        final childrenMap = <String, List<T>>{};
        final parentMap = <String, T>{};

        for (final item in processedData) {
          final rowMap = widget.toMap(item);
          final id = _extractValue(rowMap, widget.rowIdKey).toString();
          final parentId = _extractValue(
            rowMap,
            widget.parentIdKey!,
          )?.toString();

          if (parentId != null) {
            childrenMap.putIfAbsent(parentId, () => []).add(item);
            if (itemMap.containsKey(parentId)) {
              parentMap[id] = itemMap[parentId] as T;
            }
          }
        }

        final Set<T> matchedItems = {};
        processedData
            .where((item) {
              final rowMap = widget.toMap(item);
              return activeFilters.entries.every((filterEntry) {
                final columnDef = finalColumnDefs.firstWhere(
                  (c) => c.id == filterEntry.key,
                );
                final cellValue = _extractValue(rowMap, filterEntry.key);
                if (cellValue == null) return false;
                switch (columnDef.filterType) {
                  case FilterType.string:
                    return cellValue.toString().toLowerCase().contains(
                      filterEntry.value.toLowerCase(),
                    );
                  case FilterType.numeric:
                    return _matchNumericFilter(cellValue, filterEntry.value);
                  case FilterType.date:
                    return _matchDateFilter(cellValue, filterEntry.value);
                  case FilterType.boolean:
                    return _matchBooleanFilter(cellValue, filterEntry.value);
                  case FilterType.list:
                    return cellValue.toString().toLowerCase() ==
                        filterEntry.value.toLowerCase();
                  case FilterType.none:
                    return true;
                }
              });
            })
            .forEach(matchedItems.add);

        if (_includeChildrenInFilter) {
          final Set<T> itemsToShow = {};
          for (final item in matchedItems) {
            itemsToShow.add(item);

            var current = item;
            while (true) {
              final currentId = _extractValue(
                widget.toMap(current),
                widget.rowIdKey,
              ).toString();
              final parent = parentMap[currentId];
              if (parent == null) break;
              itemsToShow.add(parent);
              current = parent;
            }

            final queue = [item];
            while (queue.isNotEmpty) {
              final currentItem = queue.removeAt(0);
              final currentId = _extractValue(
                widget.toMap(currentItem),
                widget.rowIdKey,
              ).toString();
              if (childrenMap.containsKey(currentId)) {
                for (final child in childrenMap[currentId]!) {
                  if (itemsToShow.add(child)) {
                    queue.add(child);
                  }
                }
              }
            }
          }
          processedData = itemsToShow.toList();
        } else {
          processedData = matchedItems.toList();
        }
      } else {
        processedData = processedData.where((item) {
          final rowMap = widget.toMap(item);
          return activeFilters.entries.every((filterEntry) {
            final columnDef = finalColumnDefs.firstWhere(
              (c) => c.id == filterEntry.key,
            );
            final cellValue = _extractValue(rowMap, filterEntry.key);
            if (cellValue == null) return false;
            switch (columnDef.filterType) {
              case FilterType.string:
                return cellValue.toString().toLowerCase().contains(
                  filterEntry.value.toLowerCase(),
                );
              case FilterType.numeric:
                return _matchNumericFilter(cellValue, filterEntry.value);
              case FilterType.date:
                return _matchDateFilter(cellValue, filterEntry.value);
              case FilterType.boolean:
                return _matchBooleanFilter(cellValue, filterEntry.value);
              case FilterType.list:
                return cellValue.toString().toLowerCase() ==
                    filterEntry.value.toLowerCase();
              case FilterType.none:
                return true;
            }
          });
        }).toList();
      }
    }

    // 3. Sort (for non-tree view only, tree sorting is handled in _buildTree)
    if (!widget.isTree && _sortColumnId != null) {
      processedData.sort((a, b) {
        dynamic valA = _extractValue(widget.toMap(a), _sortColumnId!);
        dynamic valB = _extractValue(widget.toMap(b), _sortColumnId!);
        if (valA == null && valB == null) return 0;
        if (valA == null) return 1;
        if (valB == null) return -1;
        int compare = valA is Comparable && valB is Comparable
            ? valA.compareTo(valB)
            : valA.toString().compareTo(valB.toString());
        return _sortAscending ? compare : -compare;
      });
    }

    return processedData;
  }

  dynamic _extractValue(Map<String, dynamic> data, String path) {
    if (!path.contains('.')) return data[path];
    List<String> parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  bool _matchNumericFilter(dynamic cellValue, String filterValue) {
    final numValue = double.tryParse(cellValue.toString());
    if (numValue == null) return false;
    final operatorMatch = RegExp(
      r'^(>=|<=|>|<|=)?(.+)',
    ).firstMatch(filterValue);
    if (operatorMatch == null) return false;
    final operator = operatorMatch.group(1) ?? '=';
    final filterNum = double.tryParse(operatorMatch.group(2)!.trim());
    if (filterNum == null) return false;
    switch (operator) {
      case '>':
        return numValue > filterNum;
      case '<':
        return numValue < filterNum;
      case '>=':
        return numValue >= filterNum;
      case '<=':
        return numValue <= filterNum;
      default:
        return numValue == filterNum;
    }
  }

  bool _matchBooleanFilter(dynamic cellValue, String filterValue) {
    final lowerFilter = filterValue.toLowerCase().trim();
    final trueValues = {'true', 'yes', '1'};
    final falseValues = {'false', 'no', '0'};
    bool? filterAsBool;
    if (trueValues.contains(lowerFilter)) {
      filterAsBool = true;
    } else if (falseValues.contains(lowerFilter)) {
      filterAsBool = false;
    }
    if (filterAsBool == null) return false;
    bool cellAsBool;
    if (cellValue is bool) {
      cellAsBool = cellValue;
    } else {
      final lowerCell = cellValue.toString().toLowerCase();
      if (trueValues.contains(lowerCell)) {
        cellAsBool = true;
      } else if (falseValues.contains(lowerCell)) {
        cellAsBool = false;
      } else {
        return false;
      }
    }
    return cellAsBool == filterAsBool;
  }

  bool _matchDateFilter(dynamic cellValue, String filterValue) {
    DateTime? cellDate = (cellValue is DateTime)
        ? cellValue
        : DateTime.tryParse(cellValue.toString());
    if (cellDate == null) return false;
    final operatorMatch = RegExp(
      r'^(>=|<=|>|<|=)?(.+)',
    ).firstMatch(filterValue);
    if (operatorMatch == null) return false;
    final operator = operatorMatch.group(1) ?? '=';
    final dateString = operatorMatch.group(2)?.trim();
    final filterDate = dateString != null
        ? DateTime.tryParse(dateString)
        : null;
    if (filterDate == null) return false;
    final normalizedCellDate = DateTime(
      cellDate.year,
      cellDate.month,
      cellDate.day,
    );
    final normalizedFilterDate = DateTime(
      filterDate.year,
      filterDate.month,
      filterDate.day,
    );
    switch (operator) {
      case '>':
        return normalizedCellDate.isAfter(normalizedFilterDate);
      case '<':
        return normalizedCellDate.isBefore(normalizedFilterDate);
      case '>=':
        return normalizedCellDate.isAtSameMomentAs(normalizedFilterDate) ||
            normalizedCellDate.isAfter(normalizedFilterDate);
      case '<=':
        return normalizedCellDate.isAtSameMomentAs(normalizedFilterDate) ||
            normalizedCellDate.isBefore(normalizedFilterDate);
      default:
        return normalizedCellDate.isAtSameMomentAs(normalizedFilterDate);
    }
  }

  // --- ==================== UI Builders ==================== ---

  Widget _buildFilterRow(
    BuildContext context,
    List<DataColumnDef> columns,
    List<double> columnWidths,
  ) {
    final List<Widget> filterWidgets = [];
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      Widget filterWidget;

      switch (column.filterType) {
        case FilterType.none:
          filterWidget = const SizedBox.shrink();
          break;
        case FilterType.boolean:
        case FilterType.list:
          final isBool = column.filterType == FilterType.boolean;
          final List<DropdownMenuItem<String>> items = [
            const DropdownMenuItem<String>(value: 'all', child: Text('All')),
            if (isBool) ...[
              const DropdownMenuItem<String>(value: 'true', child: Text('Yes')),
              const DropdownMenuItem<String>(value: 'false', child: Text('No')),
            ] else
              ...column.filterOptions!.map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              ),
          ];
          filterWidget = DropdownButtonFormField<String>(
            initialValue: _filterValues[column.id]?.isEmpty ?? true
                ? 'all'
                : _filterValues[column.id],
            items: items,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _filterValues[column.id] = (value == 'all') ? '' : value;
                if (widget.mode == DataGridMode.server) {
                  _onServerFilterChanged();
                }
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          );
          break;
        case FilterType.string:
        case FilterType.numeric:
        case FilterType.date:
          if (!_filterControllers.containsKey(column.id)) {
            final controller = TextEditingController(
              text: _filterValues[column.id],
            );
            _filterControllers[column.id] = controller;
            controller.addListener(() {
              _filterValues[column.id] = controller.text;
              if (widget.mode == DataGridMode.client) {
                setState(() {}); // Live filter for client mode
              } else {
                _onServerFilterChanged();
              }
            });
          }
          final controller = _filterControllers[column.id]!;
          filterWidget = TextField(
            controller: controller,
            decoration: InputDecoration(
              hintStyle: const TextStyle(fontSize: 14),
              hintText: 'Filter...',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(width: 12.0),
                  Icon(Icons.search, size: 18),
                ],
              ),
              prefixIconConstraints: const BoxConstraints(minHeight: 36),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : SizedBox(
                      // Match the prefixIconConstraints
                      height: 36, // Match the prefixIconConstraints
                      child: IconButton(
                        padding: EdgeInsets.zero, // Remove default padding
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear Filter',
                        onPressed: () {
                          controller.clear();
                        },
                      ),
                    ),
            ),
          );
          break;
      }

      final cell = SizedBox(
        width: columnWidths[i],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: filterWidget,
        ),
      );

      filterWidgets.add(cell);

      // Add dividers between cells, just like the header and data rows.
      if (i < columns.length - 1) {
        final bool isDraggable =
            widget.allowColumnResize &&
            columns[i].resizable &&
            columns[i + 1].resizable;
        final divider = VerticalDivider(
          width: isDraggable ? 10.0 : 1.0,
          thickness: 1,
        );
        filterWidgets.add(divider);
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showCheckboxColumn) const SizedBox(width: 32.0),
          ...filterWidgets,
        ],
      ),
    );
  }

  List<DataColumnDef> _getFinalColumnDefs() {
    List<DataColumnDef> finalColumnDefs = List.of(widget.columnDefs);

    if (_columnOrder != null) {
      final defsMap = {for (var def in finalColumnDefs) def.id: def};
      final order = _columnOrder!;
      finalColumnDefs = order
          .map((id) => defsMap[id])
          .whereType<DataColumnDef>()
          .toList();
    }

    if (widget.idColumnDef != null) {
      finalColumnDefs.insert(0, widget.idColumnDef!);
    }
    return finalColumnDefs;
  }

  @override
  Widget build(BuildContext context) {
    final finalColumnDefs = _getFinalColumnDefs();

    // --- Data & UI Variables ---
    List<Map<String, dynamic>> displayRows = [];
    int totalRecords = 0;
    bool isFirstPage = true;
    bool isLastPage = true;

    // --- Data Processing Pipeline ---
    int totalPages;
    if (widget.mode == DataGridMode.client) {
      final processedData = _getProcessedClientData();

      if (widget.isTree) {
        // For tree view, build the hierarchy from the filtered/sorted data
        _treeData = _buildTree(processedData);
        // In tree mode, we don't paginate the main list.
        // The CustomDataTable will handle showing/hiding children.
        totalRecords = _treeData
            .where((row) => row['_indentationLevel'] == 0)
            .length;
        totalPages = 1; // Pagination is not really used in tree view
        _currentPage = 1;
        isFirstPage = true;
        isLastPage = true;
        displayRows = _treeData; // Pass the full tree to the data table
      } else {
        // For flat list, paginate the processed data
        totalRecords = processedData.length;
        totalPages = totalRecords > 0
            ? (totalRecords / widget.pageSize).ceil()
            : 1;
        if (_currentPage > totalPages) {
          _currentPage = totalPages > 0 ? totalPages : 1;
        }
        final paginatedData = processedData
            .skip((_currentPage - 1) * widget.pageSize)
            .take(widget.pageSize)
            .toList();
        displayRows = paginatedData.map(widget.toMap).toList();
        isFirstPage = _currentPage == 1;
        isLastPage = _currentPage == totalPages;
      }
    } else {
      // Server Mode
      final data = _paginatedData;
      List<T> serverData = data?.content ?? [];
      if (widget.isTree) {
        _treeData = _buildTree(serverData);
        displayRows = _treeData;
      } else {
        displayRows = serverData.map(widget.toMap).toList();
      }
      totalRecords = data?.totalElements ?? 0;
      totalPages = data?.totalPages ?? 1;
      isFirstPage = data?.first ?? true;
      isLastPage = data?.last ?? true;
    }

    final bool hasSelection = _selectedRowIds.isNotEmpty;
    final bool actualUndeleteMode = widget.mode == DataGridMode.client
        ? _showDeleted
        : widget.isUndeleteMode;

    // --- Determine "Show Deleted" state and callback for the footer ---
    bool? showDeletedValue;
    ValueChanged<bool?>? showDeletedChangedCallback;

    if (widget.mode == DataGridMode.client && widget.showDeletedToggle) {
      showDeletedValue = _showDeleted;
      showDeletedChangedCallback = (value) => setState(() {
        _showDeleted = value ?? false;
        _selectedRowIds.clear();
      });
    } else if (widget.mode == DataGridMode.server &&
        widget.serverShowDeletedValue != null) {
      showDeletedValue = widget.serverShowDeletedValue;
      showDeletedChangedCallback = (value) =>
          widget.onServerShowDeletedChanged?.call(value ?? false);
    }

    // --- Handle Initial Column Widths from ViewState ---
    List<double>? initialColumnWidths;
    // If a view state is being applied (either initially or dynamically),
    // we need to prepare the column widths in the correct order.
    if (_columnOrder != null) {
      final GridViewState? viewState = widget.initialViewState;
      final widthsMap = viewState?.columnWidths ?? {};

      // Ensure the widths are in the same order as the final columns.
      // Provide a fallback to the column's defined width if not in the map.
      initialColumnWidths = finalColumnDefs
          .map((c) => widthsMap[c.id] ?? c.width ?? c.minWidth)
          .toList();

      // When a new view is applied, we must reset the widths in CustomDataTable.
      // Setting _widthsInitialized to false in the child is not ideal, so we pass a key.
    }

    final mainContent = CustomDataTable(
      scrollController: _gridScrollController,
      headerHeight: widget.headerHeight,
      columns: finalColumnDefs,
      rowHeightBuilder: widget.rowHeightBuilder,
      headerTrailingWidgets: widget
          .headerTrailingWidgets, // Use displayRows for both tree and flat list
      rows: displayRows, // Use displayRows for both tree and flat list
      onRowTap: widget.onRowTap,
      onSort: widget.allowSorting ? _handleSort : null,
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
      showCheckboxColumn: widget.showCheckboxColumn,
      rowIdKey: widget.rowIdKey,
      rowHoverColor: widget.rowHoverColor,
      selectedRowIds: _selectedRowIds,
      onSelectionChanged: (newSelection) =>
          setState(() => _selectedRowIds = newSelection), // TODO: this is a bug
      allowFiltering: widget.allowFiltering,
      filterRowBuilder: widget.allowFiltering ? _buildFilterRow : null,
      allowColumnResize: widget.allowColumnResize,
      isTree: widget.isTree,
      onToggleExpansion: widget.isTree ? _onToggleExpansion : null,
      isExpandedKey: 'expanded',
      hasChildrenKey: 'leaf',
      indentationLevelKey: '_indentationLevel',
      isEffectivelyVisibleKey: '_isEffectivelyVisible',
      initialColumnWidths: initialColumnWidths,
      onColumnWidthsChanged: (newWidths) {
        if (mounted) {
          setState(() {
            _columnWidths = newWidths;
          });
        }
      },
    );

    return Column(
      children: [
        Expanded(
          child: _isLoading && _paginatedData == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    mainContent,
                    if (_isLoading && _paginatedData != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (widget.showFooter) ...[
          if (widget.footerBuilder != null)
            widget.footerBuilder!(
              DataGridFooterData(
                currentPage: _currentPage,
                pageSize: widget.pageSize,
                totalRecords: totalRecords,
                totalPages: totalPages,
                onRefresh: refresh,
                onFirstPage: !isFirstPage ? () => _onPageChanged(1) : null,
                onPreviousPage: !isFirstPage
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
                onNextPage: !isLastPage
                    ? () => _onPageChanged(_currentPage + 1)
                    : null,
                onLastPage: !isLastPage
                    ? () => _onPageChanged(totalPages)
                    : null,
                onAdd: widget.onAdd,
                onDelete: widget.onDelete != null && hasSelection
                    ? _handleDelete
                    : null,
                onClearFilters: _clearFilters,
                showDeleted: showDeletedValue,
                onShowDeletedChanged: showDeletedChangedCallback,
                isUndeleteMode: actualUndeleteMode,
              ),
            )
          else
            DataGridFooter(
              currentPage: _currentPage,
              pageSize: widget.pageSize,
              totalRecords: totalRecords,
              totalPages: totalPages,
              onRefresh: refresh,
              onFirstPage: !isFirstPage ? () => _onPageChanged(1) : null,
              onPreviousPage: !isFirstPage
                  ? () => _onPageChanged(_currentPage - 1)
                  : null,
              onNextPage: !isLastPage
                  ? () => _onPageChanged(_currentPage + 1)
                  : null,
              onLastPage: !isLastPage ? () => _onPageChanged(totalPages) : null,
              onAdd: widget.onAdd,
              onDelete: widget.onDelete != null && hasSelection
                  ? _handleDelete
                  : null,
              onClearFilters: _clearFilters,
              showDeleted: showDeletedValue,
              onShowDeletedChanged: showDeletedChangedCallback,
              isUndeleteMode: actualUndeleteMode,
              leadingWidgets: widget.footerLeadingWidgets,
              includeChildrenInFilter:
                  widget.isTree && widget.allowIncludeChildrenInFilterToggle
                  ? _includeChildrenInFilter
                  : null,
              onIncludeChildrenInFilterChanged:
                  widget.isTree && widget.allowIncludeChildrenInFilterToggle
                  ? (value) => setState(() {
                      _includeChildrenInFilter = value ?? false;
                    })
                  : null,
            ),
        ],
      ],
    );
  }
}
