import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/src/utils/color_utils.dart';
import 'package:legacy_tree_grid/src/models/data_column_def.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart';
export 'package:legacy_tree_grid/src/models/data_column_def.dart';

/// Extracts a value from a map, supporting nested paths.
dynamic _extractValue(Map<String, dynamic> data, String path) {
  if (!path.contains('.')) {
    return data[path];
  }

  List<String> parts = path.split('.');
  dynamic current = data;
  for (final part in parts) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null; // Path does not exist
    }
  }
  return current;
}

/// Converts a [TextAlign] to a [MainAxisAlignment] for use in a [Row].
MainAxisAlignment _textAlignToMainAxisAlignment(TextAlign textAlign) {
  switch (textAlign) {
    case TextAlign.left:
    case TextAlign.start:
      return MainAxisAlignment.start;
    case TextAlign.right:
    case TextAlign.end:
      return MainAxisAlignment.end;
    case TextAlign.center:
      return MainAxisAlignment.center;
    case TextAlign.justify:
      return MainAxisAlignment.spaceBetween;
  }
}

/// Converts a [TextAlign] to an [Alignment] for use in an [Align] widget.
Alignment _textAlignToAlignment(TextAlign textAlign) {
  switch (textAlign) {
    case TextAlign.left:
      return Alignment.centerLeft;
    case TextAlign.right:
      return Alignment.centerRight;
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.end:
      return Alignment.centerRight;
    default:
      return Alignment.centerLeft;
  }
}

class CustomDataTable extends StatefulWidget {
  final List<DataColumnDef> columns;
  final List<Map<String, dynamic>> rows;
  final double dataRowHeight;
  final double? filterRowHeight;
  final double headerHeight;
  final void Function(Map<String, dynamic> rowData)? onRowTap;
  final void Function(Map<String, dynamic> rowData)? onRowDoubleTap;
  final void Function(String columnId)? onSort;
  final String? sortColumnId;
  final bool sortAscending;
  // --- Selection Properties ---
  final bool showCheckboxColumn;
  final String? rowIdKey;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  // --- Tree Grid Properties ---
  final bool isTree;
  final Function(String rowId)? onToggleExpansion;
  final String isExpandedKey;
  final String hasChildrenKey;
  final String indentationLevelKey;
  final String isEffectivelyVisibleKey;
  // --- Custom Rendering Properties ---
  final double scale;
  final Widget Function(BuildContext context, List<DataColumnDef> columns)? headerRowBuilder;
  final Widget Function(BuildContext context, List<DataColumnDef> columns, List<double> columnWidths)? filterRowBuilder;
  final Widget Function(BuildContext context, Map<String, dynamic> rowData, List<DataColumnDef> columns)? rowBuilder;
  final double Function(Map<String, dynamic> rowData)? rowHeightBuilder;

  /// The border to display between rows and columns.
  final TableBorder? border;

  /// Whether to show the filter row beneath the header.
  final bool allowFiltering;

  /// Whether to allow users to resize columns by dragging the header dividers.
  final bool allowColumnResize;

  /// A list of widgets to display at the end of the header row.
  final List<WidgetBuilder>? headerTrailingWidgets;

  /// An optional color for the row hover effect.
  final Color? rowHoverColor;

  /// A list of initial widths for the columns.
  final List<double>? initialColumnWidths;

  /// A callback that is fired when the user resizes a column.
  final Function(List<double> newWidths)? onColumnWidthsChanged;

  /// An optional scroll controller for the vertical scroll view.
  final ScrollController? scrollController;

  /// If `true`, distributes any extra horizontal space to the column marked as `isNameColumn`.
  final bool useAvailableWidthDistribution;

  /// An optional widget to display for an ascending sort indicator.
  final Widget? sortIconAscending;

  /// An optional widget to display for a descending sort indicator.
  final Widget? sortIconDescending;

  /// An optional widget to display for a collapsed tree node.
  final Widget? treeIconCollapsed;

  /// An optional widget to display for an expanded tree node.
  final Widget? treeIconExpanded;

  /// An optional callback when a row is reordered.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// An optional callback when a row is dropped INTO another row to become its child.
  final void Function(String draggedRowId, String targetParentRowId)? onNest;

  /// The message to display when there are no rows in the table.
  final String noDataMessage;

  final ValueChanged<bool?>? onHeaderCheckboxChanged;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.onRowDoubleTap,
    this.dataRowHeight = 25.0,
    this.filterRowHeight,
    this.headerHeight = 56.0,
    this.onSort,
    this.sortColumnId,
    this.sortAscending = true,
    this.showCheckboxColumn = false,
    this.rowIdKey,
    this.selectedRowIds,
    this.onSelectionChanged,
    this.isTree = false,
    this.onToggleExpansion,
    this.isExpandedKey = 'expanded',
    this.hasChildrenKey = 'hasChildren',
    this.indentationLevelKey = '_indentationLevel',
    this.isEffectivelyVisibleKey = '_isEffectivelyVisible',
    this.scale = 1.0,
    this.headerRowBuilder,
    this.filterRowBuilder,
    this.rowBuilder,
    this.border,
    this.allowFiltering = false,
    this.allowColumnResize = false,
    this.rowHoverColor,
    this.initialColumnWidths,
    this.onColumnWidthsChanged,
    this.scrollController,
    this.useAvailableWidthDistribution = false,
    this.sortIconAscending,
    this.sortIconDescending,
    this.treeIconCollapsed,
    this.treeIconExpanded,
    this.rowHeightBuilder,
    this.headerTrailingWidgets,
    this.onReorder,
    this.onNest,
    this.noDataMessage = 'No records found',
    this.onHeaderCheckboxChanged,
  }) : assert(
         !showCheckboxColumn || (rowIdKey != null && selectedRowIds != null && onSelectionChanged != null),
         'If showCheckboxColumn is true, rowIdKey, selectedRowIds, and onSelectionChanged must be provided.',
       ),
       assert(!isTree || (rowIdKey != null && onToggleExpansion != null), 'If isTree is true, rowIdKey and onToggleExpansion must be provided.');

  static Widget buildStatusCell(BuildContext context, dynamic rawValue, String displayValue, double scale) {
    final theme = Theme.of(context);
    final defaultRowTextColor = theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    Color? cellBackgroundColor;
    Color? cellTextColor = defaultRowTextColor;

    if (rawValue is Map<String, dynamic>) {
      if (rawValue.containsKey('color')) {
        cellBackgroundColor = parseColorHex(rawValue['color'] as String?, Colors.transparent);
      }
      if (rawValue.containsKey('textColor')) {
        final textColorHex = rawValue['textColor'] as String?;
        cellTextColor = textColorHex == '0' ? Colors.black : parseColorHex(textColorHex, defaultRowTextColor);
      }
    }

    final textWidget = Text(
      displayValue,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: cellTextColor, fontSize: 12.0 * scale),
    );

    if (cellBackgroundColor != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3.0 * scale),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 2.0 * scale),
          decoration: BoxDecoration(color: cellBackgroundColor, borderRadius: BorderRadius.circular(2.0)),
          child: textWidget,
        ),
      );
    }
    return textWidget;
  }

  @override
  State<CustomDataTable> createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  late List<double> _columnWidths;
  String? _hoveredRowId;
  String? _selectedRowId;
  bool _widthsInitialized = false;
  BoxConstraints? _lastConstraints;
  double? _lastScale;
  late final ScrollController _scrollController;

  static const double _checkboxColumnWidth = 32.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    if (widget.initialColumnWidths != null) {
      _columnWidths = List.from(widget.initialColumnWidths!);
      _widthsInitialized = true;
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.columns.length != oldWidget.columns.length || widget.initialColumnWidths != oldWidget.initialColumnWidths) {
      setState(() {
        _widthsInitialized = false;
        if (widget.initialColumnWidths != null) {
          _columnWidths = List.from(widget.initialColumnWidths!);
          _widthsInitialized = true;
        }
      });
    }
  }

  void _initializeColumnWidths(BoxConstraints constraints) {
    if (widget.columns.isEmpty) {
      setState(() {
        _columnWidths = [];
        _widthsInitialized = true;
      });
      return;
    }

    final int columnCount = widget.columns.length;
    List<double> calculatedWidths = List.filled(columnCount, 0.0);
    List<bool> isWidthFixed = List.filled(columnCount, false);

    double dividerTotalWidth = (widget.showCheckboxColumn ? 1.0 : 0.0) + 1.0;
    if (widget.columns.length > 1) {
      dividerTotalWidth += widget.columns
          .sublist(0, widget.columns.length - 1)
          .asMap()
          .entries
          .map((entry) {
            final int index = entry.key;
            final bool isDraggable = widget.allowColumnResize && widget.columns[index].resizable && widget.columns[index + 1].resizable;
            return isDraggable ? 10.0 : 1.0;
          })
          .reduce((a, b) => a + b);
    }

    double totalAvailableWidth = constraints.maxWidth - (widget.showCheckboxColumn ? _checkboxColumnWidth : 0) - dividerTotalWidth;
    if (totalAvailableWidth < 0) totalAvailableWidth = 0;

    double remainingWidth = totalAvailableWidth;
    double totalFlex = 0.0;

    for (int i = 0; i < columnCount; i++) {
      final col = widget.columns[i];
      if (col.width != null) {
        double width = col.width! * widget.scale;
        double minWidth = col.minWidth * widget.scale;
        if (width < minWidth) width = minWidth;
        calculatedWidths[i] = width;
        isWidthFixed[i] = true;
        remainingWidth -= width;
      } else {
        totalFlex += (col.flex ?? 1).toDouble();
      }
    }

    if (totalFlex > 0) {
      bool constraintsViolated = true;
      while (constraintsViolated && totalFlex > 0) {
        constraintsViolated = false;
        double widthPerFlex = remainingWidth / totalFlex;

        for (int i = 0; i < columnCount; i++) {
          if (!isWidthFixed[i]) {
            final col = widget.columns[i];
            double flexWidth = (col.flex ?? 1) * widthPerFlex;
            double min = col.minWidth * widget.scale;
            double? max = col.maxWidth != null ? col.maxWidth! * widget.scale : null;

            if (flexWidth < min) {
              calculatedWidths[i] = min;
              isWidthFixed[i] = true;
              remainingWidth -= min;
              totalFlex -= (col.flex ?? 1);
              constraintsViolated = true;
              break; // Restart calculation with updated remaining and flex
            } else if (max != null && flexWidth > max) {
              calculatedWidths[i] = max;
              isWidthFixed[i] = true;
              remainingWidth -= max;
              totalFlex -= (col.flex ?? 1);
              constraintsViolated = true;
              break; // Restart calculation
            } else {
              calculatedWidths[i] = flexWidth;
            }
          }
        }
      }
    }

    setState(() {
      _columnWidths = calculatedWidths;
      _widthsInitialized = true;
      widget.onColumnWidthsChanged?.call(calculatedWidths);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, int columnIndex) {
    if (!widget.allowColumnResize) return;
    setState(() {
      final double delta = details.primaryDelta ?? 0;
      final leftColumn = widget.columns[columnIndex];
      final rightColumn = widget.columns[columnIndex + 1];

      double newLeftWidth = _columnWidths[columnIndex] + delta;
      double newRightWidth = _columnWidths[columnIndex + 1] - delta;

      if (newLeftWidth < leftColumn.minWidth) {
        newLeftWidth = leftColumn.minWidth;
        newRightWidth = _columnWidths[columnIndex] + _columnWidths[columnIndex + 1] - newLeftWidth;
      }
      if (newRightWidth < rightColumn.minWidth) {
        newRightWidth = rightColumn.minWidth;
        newLeftWidth = _columnWidths[columnIndex] + _columnWidths[columnIndex + 1] - newRightWidth;
      }

      _columnWidths[columnIndex] = newLeftWidth;
      _columnWidths[columnIndex + 1] = newRightWidth;
      widget.onColumnWidthsChanged?.call(_columnWidths);
    });
  }

  Widget _buildSelectAllCheckboxWidget() {
    final displayedIds = widget.rows.map((row) => _extractValue(row, widget.rowIdKey!).toString()).toSet();
    final selectedDisplayedIds = widget.selectedRowIds!.intersection(displayedIds);

    bool? isChecked;
    if (selectedDisplayedIds.isEmpty && displayedIds.isNotEmpty) {
      isChecked = false;
    } else if (selectedDisplayedIds.length == displayedIds.length && displayedIds.isNotEmpty) {
      isChecked = true;
    } else if (selectedDisplayedIds.isNotEmpty) {
      isChecked = null;
    } else {
      isChecked = false;
    }

    return SizedBox(
      width: _checkboxColumnWidth,
      child: Center(
        child: Transform.scale(
          scale: 0.85,
          child: Checkbox(
            value: isChecked,
            tristate: true,
            onChanged: (bool? value) {
              final bool shouldSelectAll = isChecked != true;
              Set<String> newSelection = Set.from(widget.selectedRowIds!);
              if (shouldSelectAll) {
                newSelection.addAll(displayedIds);
              } else {
                newSelection.removeAll(displayedIds);
              }
              widget.onSelectionChanged?.call(newSelection);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMergedHeaderAndFilter() {
    final bool showCheckbox = widget.showCheckboxColumn;
    final bool hasDragHandle = widget.columns.isNotEmpty && widget.columns.first.isDragHandle;
    final dividerColor = widget.border?.verticalInside.color ?? Theme.of(context).dividerColor.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDragHandle) ...[SizedBox(width: _columnWidths[0]), VerticalDivider(width: 1.0, thickness: 0.5, color: dividerColor)],
          if (showCheckbox) ...[_buildSelectAllCheckboxWidget(), VerticalDivider(width: 1.0, thickness: 0.5, color: dividerColor)],
          Expanded(
            child: Column(
              children: [
                SizedBox(height: widget.headerHeight * widget.scale, child: _buildHeader()),
                if (widget.allowFiltering)
                  SizedBox(
                    height: (widget.filterRowHeight ?? widget.dataRowHeight) * widget.scale,
                    child: _buildFilterRow(skipFirst: hasDragHandle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasDragHandle = widget.columns.isNotEmpty && widget.columns.first.isDragHandle;
    return _DataTableHeader(
      columns: hasDragHandle ? widget.columns.skip(1).toList() : widget.columns,
      columnWidths: hasDragHandle ? _columnWidths.skip(1).toList() : _columnWidths,
      onSort: widget.onSort,
      sortColumnId: widget.sortColumnId,
      sortAscending: widget.sortAscending,
      allowColumnResize: widget.allowColumnResize,
      onColumnResize: (details, index) => _handleDragUpdate(details, hasDragHandle ? index + 1 : index),
      border: widget.border,
      showCheckboxColumn: false,
      rows: widget.rows,
      rowIdKey: widget.rowIdKey,
      selectedRowIds: widget.selectedRowIds,
      onSelectionChanged: widget.onSelectionChanged,
      sortIconAscending: widget.sortIconAscending,
      sortIconDescending: widget.sortIconDescending,
      headerTrailingWidgets: widget.headerTrailingWidgets,
      scale: widget.scale,
      showBottomBorder: widget.allowFiltering,
    );
  }

  Widget _buildFilterRow({bool skipFirst = false}) {
    if (!widget.allowFiltering || widget.filterRowBuilder == null) return const SizedBox.shrink();
    final columns = skipFirst ? widget.columns.skip(1).toList() : widget.columns;
    final widths = skipFirst ? _columnWidths.skip(1).toList() : _columnWidths;
    return widget.filterRowBuilder!(context, columns, widths);
  }

  void _handleRowTap(Map<String, dynamic> rowData) {
    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();
    setState(() => _selectedRowId = (_selectedRowId == rowId) ? null : rowId);
    widget.onRowTap?.call(rowData);
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> rowData, int index, List<Map<String, dynamic>> rows) {
    if (widget.rowBuilder != null) return widget.rowBuilder!(context, rowData, widget.columns);
    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();
    final double dynamicRowHeight = widget.rowHeightBuilder?.call(rowData) ?? widget.dataRowHeight;

    return _DataTableRow(
      rowData: rowData,
      rows: rows,
      columns: widget.columns,
      columnWidths: _columnWidths,
      rowId: rowId,
      isHovered: _hoveredRowId == rowId,
      isSelected: _selectedRowId == rowId || (widget.selectedRowIds?.contains(rowId) ?? false),
      onHover: (hovering) {
        if (mounted) setState(() => _hoveredRowId = hovering ? rowId : null);
      },
      onRowTap: _handleRowTap,
      onRowDoubleTap: widget.onRowDoubleTap,
      rowHoverColor: widget.rowHoverColor,
      rowHeight: dynamicRowHeight,
      scale: widget.scale,
      border: widget.border,
      showCheckboxColumn: widget.showCheckboxColumn,
      selectedRowIds: widget.selectedRowIds,
      onSelectionChanged: widget.onSelectionChanged,
      isTree: widget.isTree,
      onToggleExpansion: widget.onToggleExpansion,
      isExpandedKey: widget.isExpandedKey,
      hasChildrenKey: widget.hasChildrenKey,
      indentationLevelKey: widget.indentationLevelKey,
      isEffectivelyVisibleKey: widget.isEffectivelyVisibleKey,
      allowColumnResize: widget.allowColumnResize,
      rowIdKey: widget.rowIdKey!,
      treeIconCollapsed: widget.treeIconCollapsed,
      treeIconExpanded: widget.treeIconExpanded,
      index: index,
      onReorder: widget.onReorder,
      onNest: widget.onNest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if ((_lastConstraints != constraints || widget.scale != _lastScale) && widget.initialColumnWidths == null) {
          _lastConstraints = constraints;
          _lastScale = widget.scale;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initializeColumnWidths(constraints);
          });
        }
        if (!_widthsInitialized) return const SizedBox.shrink();

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  height: (widget.headerHeight + (widget.allowFiltering ? (widget.filterRowHeight ?? widget.dataRowHeight) : 0)) * widget.scale + 1.0,
                  child: Material(color: Theme.of(context).canvasColor, child: _buildMergedHeaderAndFilter()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 60),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final rowData = widget.rows[index];
                    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();
                    return KeyedSubtree(key: ValueKey(rowId), child: _buildRow(context, rowData, index, widget.rows));
                  }, childCount: widget.rows.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DataTableRow extends StatefulWidget {
  final Map<String, dynamic> rowData;
  final List<Map<String, dynamic>> rows;
  final List<DataColumnDef> columns;
  final List<double> columnWidths;
  final String rowId;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHover;
  final Function(Map<String, dynamic>) onRowTap;
  final Function(Map<String, dynamic>)? onRowDoubleTap;
  final Color? rowHoverColor;
  final double rowHeight;
  final double scale;
  final TableBorder? border;
  final bool showCheckboxColumn;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final bool isTree;
  final Function(String rowId)? onToggleExpansion;
  final String isExpandedKey;
  final String hasChildrenKey;
  final String indentationLevelKey;
  final String isEffectivelyVisibleKey;
  final bool allowColumnResize;
  final String rowIdKey;
  final Widget? treeIconCollapsed;
  final Widget? treeIconExpanded;
  final int index;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(String draggedRowId, String targetParentRowId)? onNest;

  const _DataTableRow({
    required this.rowData,
    required this.rows,
    required this.columns,
    required this.columnWidths,
    required this.rowId,
    required this.isHovered,
    required this.isSelected,
    required this.onHover,
    required this.onRowTap,
    this.onRowDoubleTap,
    this.rowHoverColor,
    required this.rowHeight,
    required this.scale,
    this.border,
    required this.showCheckboxColumn,
    this.selectedRowIds,
    this.onSelectionChanged,
    required this.isTree,
    this.onToggleExpansion,
    required this.isExpandedKey,
    required this.hasChildrenKey,
    required this.indentationLevelKey,
    required this.isEffectivelyVisibleKey,
    required this.allowColumnResize,
    required this.rowIdKey,
    this.treeIconCollapsed,
    this.treeIconExpanded,
    required this.index,
    this.onReorder,
    this.onNest,
  });

  @override
  State<_DataTableRow> createState() => _DataTableRowState();
}

class _DataTableRowState extends State<_DataTableRow> {
  String? _dropZone;
  bool _isDragging = false;

  void _handleDragHover(DragTargetDetails<int> details, BuildContext context) {
    if (widget.onNest == null && widget.onReorder == null) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final relativeY = box.globalToLocal(details.offset).dy / box.size.height;
    setState(() {
      if (relativeY < 0.25) {
        _dropZone = 'before';
      } else if (relativeY > 0.75) {
        _dropZone = 'after';
      } else {
        _dropZone = 'inside';
      }
    });
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

  void _clearDragState() => setState(() {
    _dropZone = null;
  });

  bool _isDescendant(int ancestorIndex, int targetIndex) {
    if (ancestorIndex < 0 || ancestorIndex >= widget.rows.length) return false;
    if (targetIndex <= ancestorIndex || targetIndex >= widget.rows.length) return false;

    final ancestorLevel = widget.rows[ancestorIndex][widget.indentationLevelKey] as int? ?? 0;

    for (int i = ancestorIndex + 1; i <= targetIndex; i++) {
      final currentLevel = widget.rows[i][widget.indentationLevelKey] as int? ?? 0;
      if (currentLevel <= ancestorLevel) return false;
    }
    return true;
  }

  Widget _buildRowCheckbox() {
    return SizedBox(
      width: _CustomDataTableState._checkboxColumnWidth,
      child: Center(
        child: Transform.scale(
          scale: 0.85,
          child: Checkbox(
            value: widget.isSelected,
            onChanged: (value) {
              if (value == null) return;
              final newSelection = Set<String>.from(widget.selectedRowIds ?? {});
              if (value) {
                newSelection.add(widget.rowId);
              } else {
                newSelection.remove(widget.rowId);
              }
              widget.onSelectionChanged?.call(newSelection);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDecoratedRow({required Widget content, required Color rowColor, required double rowHeight, required ThemeData theme, required bool isDragging}) {
    return Opacity(
      opacity: isDragging ? 0.35 : 1.0,
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: widget.border?.horizontalInside.width ?? 0.5),
          ),
        ),
        child: InkWell(
          onHover: widget.onHover,
          onTap: () => widget.onRowTap(widget.rowData),
          onDoubleTap: widget.onRowDoubleTap != null ? () => widget.onRowDoubleTap!(widget.rowData) : null,
          child: GestureDetector(
            onSecondaryTapUp: (d) {
              final actionCol = widget.columns.where((c) => c.itemsBuilder != null).firstOrNull;
              if (actionCol != null) {
                showContextMenu(
                  context: context,
                  tapPosition: d.globalPosition,
                  menuItems: actionCol.itemsBuilder!(context, widget.rowData),
                );
              }
            },
            child: content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTree && !(widget.rowData[widget.isEffectivelyVisibleKey] as bool? ?? true)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rowHeight = widget.rowHeight * widget.scale;
    final rowColor = widget.isSelected
        ? theme.highlightColor.withValues(alpha: widget.isHovered ? 0.45 : 0.3)
        : (widget.isHovered ? (widget.rowHoverColor ?? theme.hoverColor) : Colors.transparent);

    Widget buildRowContent({required bool isFeedback}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(widget.columns.length, (colIndex) {
          final column = widget.columns[colIndex];
          final width = widget.columnWidths[colIndex];
          final raw = _extractValue(widget.rowData, column.id);
          final display = column.formattedValue?.call(raw, widget.rowData) ?? raw?.toString() ?? '';

          Widget cell =
              column.cellBuilder?.call(context, raw, display, widget.scale, widget.rowData) ??
              Padding(
                padding: EdgeInsets.symmetric(horizontal: (column.useCellPadding ? 8.0 : 0.0) * widget.scale),
                child: Align(
                  alignment: _textAlignToAlignment(column.alignment),
                  child: Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.0 * widget.scale),
                  ),
                ),
              );

          if (widget.isTree && column.isNameColumn) {
            final indent = widget.rowData[widget.indentationLevelKey] as int? ?? 0;
            final hasKids = widget.rowData[widget.hasChildrenKey] as bool? ?? false;
            final expanded = widget.rowData[widget.isExpandedKey] as bool? ?? false;
            cell = Row(
              children: [
                SizedBox(width: indent * 20.0 * widget.scale),
                if (hasKids)
                  InkWell(
                    onTap: () => widget.onToggleExpansion?.call(widget.rowId),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: expanded
                          ? (widget.treeIconExpanded ?? const Icon(Icons.expand_more, size: 20))
                          : (widget.treeIconCollapsed ?? const Icon(Icons.chevron_right, size: 20)),
                    ),
                  )
                else
                  SizedBox(width: 24.0 * widget.scale),
                const SizedBox(width: 4.0),
                Expanded(child: cell),
              ],
            );
          }

          Widget finalCell = cell;
          if (column.isDragHandle && !isFeedback && widget.onReorder != null) {
            finalCell = Draggable<int>(
              data: widget.index,
              axis: Axis.vertical,
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: (_) => setState(() => _isDragging = false),
              feedback: Material(
                elevation: 4.0,
                color: theme.cardColor.withValues(alpha: 0.8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: rowHeight,
                  child: _buildDecoratedRow(
                    content: buildRowContent(isFeedback: true),
                    rowColor: rowColor,
                    rowHeight: rowHeight,
                    theme: theme,
                    isDragging: false,
                  ),
                ),
              ),
              child: finalCell,
            );
          }

          final cellStack = [
            SizedBox(
              width: width,
              child: Opacity(
                opacity: (column.showOnRowHover && !widget.isHovered) ? 0.0 : 1.0,
                child: IgnorePointer(ignoring: column.showOnRowHover && !widget.isHovered, child: finalCell),
              ),
            ),
            VerticalDivider(
              width: (widget.allowColumnResize && colIndex < widget.columns.length - 1 && column.resizable && widget.columns[colIndex + 1].resizable)
                  ? 10.0
                  : 1.0,
              thickness: 0.5,
              color: widget.border?.verticalInside.color ?? theme.dividerColor.withValues(alpha: 0.5),
            ),
          ];

          if (colIndex == 0 && column.isDragHandle && widget.showCheckboxColumn) {
            cellStack.addAll([
              _buildRowCheckbox(),
              VerticalDivider(width: 1.0, thickness: 0.5, color: widget.border?.verticalInside.color ?? theme.dividerColor.withValues(alpha: 0.5)),
            ]);
          }
          return cellStack;
        }).expand((w) => w).toList(),
      );
    }

    final decorated = _buildDecoratedRow(
      content: buildRowContent(isFeedback: false),
      rowColor: rowColor,
      rowHeight: rowHeight,
      theme: theme,
      isDragging: _isDragging,
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        if (d.data == widget.index) return false;
        if (_isDescendant(d.data, widget.index)) return false;
        return true;
      },
      onMove: (d) => _handleDragHover(d, context),
      onLeave: (_) => _clearDragState(),
      onAcceptWithDetails: (d) {
        if (_dropZone == 'inside') {
          final draggedId = _extractValue(widget.rows[d.data], widget.rowIdKey).toString();
          widget.onNest?.call(draggedId, widget.rowId);
        } else if (_dropZone == 'before') {
          widget.onReorder?.call(d.data, widget.index);
        } else if (_dropZone == 'after') {
          widget.onReorder?.call(d.data, widget.index + 1);
        }
        _clearDragState();
      },
      builder: (context, candidate, rejected) => Stack(
        clipBehavior: Clip.none,
        children: [
          decorated,
          if (_dropZone == 'before') Positioned(top: -2, left: 0, right: 0, child: Container(height: 4, color: Colors.blueAccent)),
          if (_dropZone == 'after') Positioned(bottom: -2, left: 0, right: 0, child: Container(height: 4, color: Colors.blueAccent)),
          if (_dropZone == 'inside')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataTableHeader extends StatelessWidget {
  final List<DataColumnDef> columns;
  final List<double> columnWidths;
  final void Function(String)? onSort;
  final String? sortColumnId;
  final bool sortAscending;
  final bool allowColumnResize;
  final void Function(DragUpdateDetails, int) onColumnResize;
  final TableBorder? border;
  final bool showCheckboxColumn;
  final List<Map<String, dynamic>> rows;
  final String? rowIdKey;
  final Set<String>? selectedRowIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final Widget? sortIconAscending;
  final Widget? sortIconDescending;
  final List<WidgetBuilder>? headerTrailingWidgets;
  final double scale;
  final bool showBottomBorder;

  const _DataTableHeader({
    required this.columns,
    required this.columnWidths,
    this.onSort,
    this.sortColumnId,
    required this.sortAscending,
    required this.allowColumnResize,
    required this.onColumnResize,
    this.border,
    required this.showCheckboxColumn,
    required this.rows,
    this.rowIdKey,
    this.selectedRowIds,
    this.onSelectionChanged,
    this.sortIconAscending,
    this.sortIconDescending,
    this.headerTrailingWidgets,
    required this.scale,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showBottomBorder ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(columns.length, (index) {
          final col = columns[index];
          final activeSort = sortColumnId == col.id;
          final headerText = Text(
            col.caption,
            style: (Theme.of(context).textTheme.titleSmall ?? TextStyle(fontSize: 14.0 * scale)).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14.0) * scale,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: col.headerAlignment,
          );

          Widget header = InkWell(
            onTap: col.sortable && onSort != null ? () => onSort!(col.id) : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (col.useCellPadding ? 8.0 : 0.0) * scale),
              child: Row(
                mainAxisAlignment: _textAlignToMainAxisAlignment(col.headerAlignment),
                children: [
                  Expanded(child: headerText),
                  if (activeSort) ...[
                    const SizedBox(width: 6),
                    activeSort
                        ? (sortAscending
                              ? (sortIconAscending ?? Icon(Icons.arrow_upward, size: 16 * scale))
                              : (sortIconDescending ?? Icon(Icons.arrow_downward, size: 16 * scale)))
                        : const SizedBox.shrink(),
                  ],
                ],
              ),
            ),
          );

          if (index == columns.length - 1 && headerTrailingWidgets != null) {
            header = Row(
              children: [
                Expanded(child: header),
                ...headerTrailingWidgets!.map((b) => b(context)),
              ],
            );
          }

          final widgets = [
            SizedBox(width: columnWidths[index], child: header),
            VerticalDivider(
              width: (allowColumnResize && index < columns.length - 1 && col.resizable && columns[index + 1].resizable) ? 10.0 : 1.0,
              thickness: 0.5,
              color: border?.verticalInside.color ?? Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ];
          return widgets;
        }).expand((w) => w).toList(),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _SliverHeaderDelegate({required this.child, required this.height});
  @override
  Widget build(context, shrink, overlaps) => SizedBox.expand(child: child);
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) => oldDelegate.child != child || oldDelegate.height != height;
}
