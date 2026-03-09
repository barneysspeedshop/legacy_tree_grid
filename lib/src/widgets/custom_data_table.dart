import 'dart:ui';
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
  final Widget Function(BuildContext context, List<DataColumnDef> columns)?
  headerRowBuilder;
  final Widget Function(
    BuildContext context,
    List<DataColumnDef> columns,
    List<double> columnWidths,
  )?
  filterRowBuilder;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> rowData,
    List<DataColumnDef> columns,
  )?
  rowBuilder;
  final double Function(Map<String, dynamic> rowData)? rowHeightBuilder;

  /// The border to display between rows and columns.
  /// Use `TableBorder.symmetric(inside: ...)` to add borders between cells.
  final TableBorder? border;

  /// Whether to show the filter row beneath the header.
  final bool allowFiltering;

  /// Whether to allow users to resize columns by dragging the header dividers.
  final bool allowColumnResize;

  /// A list of widgets to display at the end of the header row.
  final List<WidgetBuilder>? headerTrailingWidgets;

  /// An optional color for the row hover effect.
  final Color? rowHoverColor;

  /// A list of initial widths for the columns. If provided, this will override
  /// the default width calculation from `flex` or `width` in `DataColumnDef`.
  final List<double>? initialColumnWidths;

  /// A callback that is fired when the user resizes a column.
  /// The parent widget can use this to save the new layout.
  final Function(List<double> newWidths)? onColumnWidthsChanged;

  /// An optional scroll controller for the vertical scroll view.
  /// Useful for implementing lazy loading or controlling scroll position from a parent.
  final ScrollController? scrollController;

  /// If `true`, distributes any extra horizontal space to the column marked
  /// as `isNameColumn` to make the table fill the screen width. Defaults to `false`.
  final bool useAvailableWidthDistribution;

  /// An optional widget to display for an ascending sort indicator.
  /// Defaults to a Material `Icons.arrow_upward`.
  final Widget? sortIconAscending;

  /// An optional widget to display for a descending sort indicator.
  /// Defaults to a Material `Icons.arrow_downward`.
  final Widget? sortIconDescending;

  /// An optional widget to display for a collapsed tree node.
  /// Defaults to a Material `Icons.chevron_right`.
  final Widget? treeIconCollapsed;

  /// An optional widget to display for an expanded tree node.
  /// Defaults to a Material `Icons.expand_more`.
  final Widget? treeIconExpanded;

  /// An optional callback when a row is reordered.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// The message to display when there are no rows in the table.
  /// Defaults to 'No records found'.
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
    this.hasChildrenKey = 'leaf',
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
    this.noDataMessage = 'No records found',
    this.onHeaderCheckboxChanged,
  }) : assert(
         !showCheckboxColumn ||
             (rowIdKey != null &&
                 selectedRowIds != null &&
                 onSelectionChanged != null),
         'If showCheckboxColumn is true, rowIdKey, selectedRowIds, and onSelectionChanged must be provided.',
       ),
       assert(
         !isTree || (rowIdKey != null && onToggleExpansion != null),
         'If isTree is true, rowIdKey and onToggleExpansion must be provided.',
       );

  /// A helper method to build a standard "status" cell with a colored background.
  ///
  /// This can be used within a `cellBuilder` for a consistent look and feel.
  /// It expects the `rawValue` to be a Map containing optional 'color' and
  /// 'textColor' hex strings.
  static Widget buildStatusCell(
    BuildContext context,
    dynamic rawValue,
    String displayValue,
    double scale,
  ) {
    final theme = Theme.of(context);
    final defaultRowTextColor =
        theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    Color? cellBackgroundColor;
    Color? cellTextColor = defaultRowTextColor;

    if (rawValue is Map<String, dynamic>) {
      if (rawValue.containsKey('color')) {
        cellBackgroundColor = parseColorHex(
          rawValue['color'] as String?,
          Colors.transparent,
        );
      }
      if (rawValue.containsKey('textColor')) {
        final textColorHex = rawValue['textColor'] as String?;
        cellTextColor = textColorHex == '0'
            ? Colors.black
            : parseColorHex(textColorHex, defaultRowTextColor);
      }
    }

    final textWidget = Text(
      displayValue,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: cellTextColor, fontSize: 12.0 * scale),
    );

    if (cellBackgroundColor != null) {
      // Wrap the colored Container in Padding. The Padding widget will be stretched
      // to the full height of the row, and it will then constrain its child,
      // effectively creating vertical padding for the background color.
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3.0 * scale),
        child: Container(
          width: double.infinity, // Fill the width of the column.
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 2.0 * scale),
          decoration: BoxDecoration(
            color: cellBackgroundColor,
            borderRadius: BorderRadius.circular(2.0),
          ),
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
    // Dispose the controller only if it was created internally.
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.columns.length != oldWidget.columns.length ||
        widget.initialColumnWidths != oldWidget.initialColumnWidths) {
      setState(() {
        _widthsInitialized = false;
        if (widget.initialColumnWidths != null) {
          _columnWidths = List.from(widget.initialColumnWidths!);
          _widthsInitialized = true;
        }
      });
    }
  }

  /// Calculates the initial widths for all columns based on their `flex` or
  /// `width` properties and the available screen space.
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

    // 1. Calculate divider widths
    double dividerWidths = (widget.showCheckboxColumn ? 1.0 : 0.0) + 1.0;
    if (widget.columns.length > 1) {
      dividerWidths += widget.columns
          .sublist(0, widget.columns.length - 1)
          .asMap()
          .entries
          .map((entry) {
            final int index = entry.key;
            final bool isDraggable =
                widget.allowColumnResize &&
                widget.columns[index].resizable &&
                widget.columns[index + 1].resizable;
            return isDraggable ? 10.0 : 1.0;
          })
          .reduce((a, b) => a + b);
    }

    // 2. Determine initial available width
    double totalAvailableWidth =
        constraints.maxWidth -
        (widget.showCheckboxColumn ? _checkboxColumnWidth : 0) -
        dividerWidths;

    // Ensure we don't have negative available width
    if (totalAvailableWidth < 0) totalAvailableWidth = 0;

    double remainingWidth = totalAvailableWidth;
    double totalFlex = 0.0;

    // 3. First pass: Handle fixed width columns and sum up initial flex
    for (int i = 0; i < columnCount; i++) {
      final col = widget.columns[i];
      if (col.width != null) {
        double width = col.width! * widget.scale;
        double minWidth = col.minWidth * widget.scale;
        if (width < minWidth) width = minWidth;
        if (col.maxWidth != null) {
          double maxWidth = col.maxWidth! * widget.scale;
          if (width > maxWidth) width = maxWidth;
        }
        calculatedWidths[i] = width;
        isWidthFixed[i] = true;
        remainingWidth -= width;
      } else if (col.flex != null) {
        // Flex column (shares remaining space)
        totalFlex += col.flex!.toDouble();
      } else {
        // Factor-based column (treat as fixed width based on factor)
        // Base unit width * factor * scale
        const double baseUnitWidth = 80.0; // Adjustable constant
        double width = baseUnitWidth * col.widthFactor * widget.scale;

        // Respect constraints
        double minWidth = col.minWidth * widget.scale;
        if (width < minWidth) width = minWidth;
        if (col.maxWidth != null) {
          double maxWidth = col.maxWidth! * widget.scale;
          if (width > maxWidth) width = maxWidth;
        }

        calculatedWidths[i] = width;
        isWidthFixed[i] = true;
        remainingWidth -= width;
      }
    }

    // 4. Iterative pass for flex columns to handle constraints (min/max widths)
    // We need to loop because applying a constraint to one column might strictly fix its width,
    // thereby changing the available space and flex ratio for the remaining columns.
    bool constraintsApplied = true;
    while (constraintsApplied && totalFlex > 0) {
      constraintsApplied = false;

      // Calculate the width per flex unit for this iteration
      // If remainingWidth is negative, we still calculate it to shrink columns if possible,
      // but minWidths will eventually stop it.
      double widthPerFlex = remainingWidth / totalFlex;

      for (int i = 0; i < columnCount; i++) {
        if (isWidthFixed[i]) continue; // Skip already fixed columns

        final col = widget.columns[i];
        final double flexVal = (col.flex ?? 1).toDouble();
        double tentativeWidth = flexVal * widthPerFlex;

        // Check if this tentative width violates min/max constraints
        bool violated = false;
        double newFixedWidth = tentativeWidth;

        double minWidth = col.minWidth * widget.scale;
        if (tentativeWidth < minWidth) {
          newFixedWidth = minWidth;
          violated = true;
        } else if (col.maxWidth != null) {
          double maxWidth = col.maxWidth! * widget.scale;
          if (tentativeWidth > maxWidth) {
            newFixedWidth = maxWidth;
            violated = true;
          }
        }

        if (violated) {
          // Fix this column effectively removing it from the flex pool
          calculatedWidths[i] = newFixedWidth;
          isWidthFixed[i] = true;
          remainingWidth -= newFixedWidth;
          totalFlex -= flexVal;
          constraintsApplied = true;
          // Restart loop since totalFlex and remainingWidth changed
          break;
        }
      }
    }

    // 5. Final pass: Assign width to remaining flexible columns
    if (totalFlex > 0) {
      double widthPerFlex = remainingWidth / totalFlex;
      for (int i = 0; i < columnCount; i++) {
        if (!isWidthFixed[i]) {
          final col = widget.columns[i];
          double width = (col.flex ?? 1) * widthPerFlex;
          // Final clamp just in case, though logic above should have handled it
          double minWidth = col.minWidth * widget.scale;
          if (width < minWidth) width = minWidth;
          if (col.maxWidth != null) {
            double maxWidth = col.maxWidth! * widget.scale;
            if (width > maxWidth) width = maxWidth;
          }
          calculatedWidths[i] = width;
        }
      }
    }

    // 6. Constraints check: If we have over-constrained (e.g. min widths),
    // calculatedWidths sum might exceed available width.
    // The previous logic naturally handles "filling" the width (up to max constraints).
    // If the window is too small, we just overflow (controlled by SingleChildScrollView in build).

    // 7. Width distribution: if enabled, give any remaining space to the name column
    if (widget.useAvailableWidthDistribution && remainingWidth > 0) {
      int distributorIndex = widget.columns.indexWhere((c) => c.isNameColumn);
      if (distributorIndex == -1) {
        // Fallback to the first flexible column if no name column is designated
        distributorIndex = widget.columns.indexWhere((c) => c.flex != null);
      }

      if (distributorIndex != -1) {
        calculatedWidths[distributorIndex] += remainingWidth;
        remainingWidth = 0;
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

      // The column being resized (to the left of the divider)
      double newLeftWidth = _columnWidths[columnIndex] + delta;

      // The column to the right of the divider
      double newRightWidth = _columnWidths[columnIndex + 1] - delta;

      // Enforce minimum width for both columns
      if (newLeftWidth < leftColumn.minWidth ||
          newRightWidth < rightColumn.minWidth) {
        // If one column is at its minimum, prevent further resizing in that direction.
        if (newLeftWidth < leftColumn.minWidth) {
          newLeftWidth = leftColumn.minWidth;
          newRightWidth =
              _columnWidths[columnIndex] +
              _columnWidths[columnIndex + 1] -
              newLeftWidth;
        }
        if (newRightWidth < rightColumn.minWidth) {
          newRightWidth = rightColumn.minWidth;
          newLeftWidth =
              _columnWidths[columnIndex] +
              _columnWidths[columnIndex + 1] -
              newRightWidth;
        }
      }

      _columnWidths[columnIndex] = newLeftWidth;
      _columnWidths[columnIndex + 1] = newRightWidth;

      widget.onColumnWidthsChanged?.call(_columnWidths);
    });
  }

  Widget _buildSelectAllCheckboxWidget({bool isMerged = false}) {
    final displayedIds = widget.rows
        .map((row) => _extractValue(row, widget.rowIdKey!).toString())
        .toSet();
    final selectedDisplayedIds = widget.selectedRowIds!.intersection(
      displayedIds,
    );

    bool? isChecked;
    if (selectedDisplayedIds.isEmpty && displayedIds.isNotEmpty) {
      isChecked = false;
    } else if (selectedDisplayedIds.length == displayedIds.length &&
        displayedIds.isNotEmpty) {
      isChecked = true;
    } else if (selectedDisplayedIds.isNotEmpty) {
      isChecked = null; // tristate
    } else {
      isChecked = false; // No items displayed
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
              if (widget.onHeaderCheckboxChanged != null) {
                widget.onHeaderCheckboxChanged!(shouldSelectAll);
              } else {
                widget.onSelectionChanged?.call(newSelection);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMergedHeaderAndFilter() {
    final bool showCheckbox = widget.showCheckboxColumn;
    final bool hasDragHandle =
        widget.columns.isNotEmpty && widget.columns.first.isDragHandle;

    Border? containerBorder;
    final horizontalBorder = widget.border?.horizontalInside;
    if (horizontalBorder != null && horizontalBorder != BorderSide.none) {
      containerBorder = Border(bottom: horizontalBorder);
    } else if (widget.border == null) {
      containerBorder = Border(
        bottom: BorderSide(color: Theme.of(context).dividerColor),
      );
    }

    final dividerColor =
        widget.border?.verticalInside.color ??
        Theme.of(context).dividerColor.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(border: containerBorder),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDragHandle) ...[
            SizedBox(width: _columnWidths[0]),
            VerticalDivider(width: 1.0, thickness: 0.5, color: dividerColor),
          ],
          if (showCheckbox) ...[
            _buildSelectAllCheckboxWidget(isMerged: true),
            VerticalDivider(width: 1.0, thickness: 0.5, color: dividerColor),
          ],
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: widget.headerHeight * widget.scale,
                  child: _DataTableHeader(
                    // If we have a drag handle, skip it as we rendered it in the merged area
                    columns: hasDragHandle
                        ? widget.columns.skip(1).toList()
                        : widget.columns,
                    columnWidths: hasDragHandle
                        ? _columnWidths.skip(1).toList()
                        : _columnWidths,
                    onSort: widget.onSort,
                    sortColumnId: widget.sortColumnId,
                    sortAscending: widget.sortAscending,
                    allowColumnResize: widget.allowColumnResize,
                    onColumnResize: (details, index) {
                      // Adjust index because we skipped the first column in the header rendering
                      _handleDragUpdate(
                        details,
                        hasDragHandle ? index + 1 : index,
                      );
                    },
                    border: widget.border,
                    showCheckboxColumn: false, // Handled by merged layout
                    rows: widget.rows,
                    rowIdKey: widget.rowIdKey,
                    selectedRowIds: widget.selectedRowIds,
                    onSelectionChanged: widget.onSelectionChanged,
                    onHeaderCheckboxChanged: widget.onHeaderCheckboxChanged,
                    sortIconAscending: widget.sortIconAscending,
                    sortIconDescending: widget.sortIconDescending,
                    headerTrailingWidgets: widget.headerTrailingWidgets,
                    scale: widget.scale,
                    showBottomBorder: widget.allowFiltering,
                  ),
                ),
                if (widget.allowFiltering)
                  SizedBox(
                    height:
                        (widget.filterRowHeight ?? widget.dataRowHeight) *
                        widget.scale,
                    child: _buildFilterRow(skipFirst: hasDragHandle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({bool skipFirst = false}) {
    if (!widget.allowFiltering) {
      return const SizedBox.shrink();
    }

    if (widget.filterRowBuilder != null) {
      final filteredCols = skipFirst
          ? widget.columns.skip(1).toList()
          : widget.columns;
      final filteredWidths = skipFirst
          ? _columnWidths.skip(1).toList()
          : _columnWidths;
      return widget.filterRowBuilder!(context, filteredCols, filteredWidths);
    }

    // The default implementation is removed. The parent must provide a builder.
    return const SizedBox.shrink();
  }

  Widget _buildDragProxy(
    BuildContext context,
    Widget? originalChild,
    int index,
  ) {
    if (originalChild == null) return const SizedBox.shrink();
    if (!widget.isTree || index >= widget.rows.length) return originalChild;

    final rowData = widget.rows[index];
    final isExpanded = rowData[widget.isExpandedKey] as bool? ?? false;

    // If not expanded, we just drag the single row
    if (!isExpanded) return originalChild;

    // It is expanded. Find children to inspect.
    final parentIndent = rowData[widget.indentationLevelKey] as int? ?? 0;
    List<Widget> childrenWidgets = [];

    // Scan forward to find children
    for (int i = index + 1; i < widget.rows.length; i++) {
      final nextRow = widget.rows[i];
      final nextIndent = nextRow[widget.indentationLevelKey] as int? ?? 0;
      if (nextIndent <= parentIndent) break; // End of block

      // Build the child row
      childrenWidgets.add(_buildRow(context, nextRow, i));
    }

    if (childrenWidgets.isEmpty) return originalChild;

    // Return a column of Parent + Children
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [originalChild, ...childrenWidgets],
    );
  }

  void _handleRowTap(Map<String, dynamic> rowData) {
    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();
    setState(() {
      if (_selectedRowId == rowId) {
        _selectedRowId = null; // Toggle off if tapping the same row
      } else {
        _selectedRowId = rowId; // Select the new row
      }
    });
    widget.onRowTap?.call(rowData); // Also call the external listener
  }

  Widget _buildRow(
    BuildContext context,
    Map<String, dynamic> rowData,
    int index,
  ) {
    if (widget.rowBuilder != null) {
      return widget.rowBuilder!(context, rowData, widget.columns);
    }
    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();

    final double dynamicRowHeight =
        widget.rowHeightBuilder?.call(rowData) ?? widget.dataRowHeight;

    return _DataTableRow(
      rowData: rowData,
      columns: widget.columns,
      columnWidths: _columnWidths,
      rowId: rowId,
      isHovered: _hoveredRowId == rowId,
      isSelected:
          _selectedRowId == rowId ||
          (widget.selectedRowIds?.contains(rowId) ?? false),
      onHover: (hovering) {
        if (!mounted) return;
        setState(() {
          _hoveredRowId = hovering ? rowId : null;
        });
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
      treeIconExpanded: widget.treeIconExpanded, // scale was duplicated here
      index: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The core table layout, which is a Column containing the header, filters, and rows.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if a recalculation is needed. This happens on the first build,
        // or if the constraints have changed and we are not using fixed initial widths.
        final bool constraintsChanged = _lastConstraints != constraints;
        if (constraintsChanged) {
          _lastConstraints = constraints;
        }

        final bool scaleChanged = widget.scale != _lastScale;
        if (scaleChanged) {
          _lastScale = widget.scale;
        }

        if ((constraintsChanged || scaleChanged) &&
            widget.initialColumnWidths == null) {
          // Post a frame callback to avoid calling setState during a build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initializeColumnWidths(constraints);
            }
          });
        }

        // Safety check: if widths are initialized but the length doesn't match the columns,
        // we must re-initialize. This can happen if columns are changed dynamically.
        if (_widthsInitialized &&
            _columnWidths.length != widget.columns.length) {
          _widthsInitialized = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initializeColumnWidths(constraints);
            }
          });
        }

        if (!_widthsInitialized) return const SizedBox.shrink();
        // The new layout using CustomScrollView and Slivers. This ensures that
        // the header, filter row, and data rows all live within the same
        // scrollable viewport. When a vertical scrollbar appears, it correctly
        // reduces the width of all components, preventing misalignment.
        final tableLayout = Scrollbar(
          controller: _scrollController,
          thumbVisibility: true, // Always show scrollbar on web for clarity
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  // Add 1.0 for the bottom border thickness to prevent vertical overflow
                  height:
                      (widget.headerHeight +
                              (widget.allowFiltering
                                  ? (widget.filterRowHeight ??
                                        widget.dataRowHeight)
                                  : 0)) *
                          widget.scale +
                      1.0,
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _buildMergedHeaderAndFilter(),
                  ),
                ),
              ),
              if (widget.onReorder != null)
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 60),
                  sliver: SliverReorderableList(
                    itemBuilder: (context, index) {
                      final rowData = widget.rows[index];
                      final rowId = _extractValue(
                        rowData,
                        widget.rowIdKey!,
                      ).toString();
                      return KeyedSubtree(
                        key: ValueKey(rowId),
                        child: _buildRow(context, rowData, index),
                      );
                    },
                    itemCount: widget.rows.length,
                    onReorder: widget.onReorder!,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(
                            animation.value,
                          );
                          final double elevation =
                              lerpDouble(0, 6, animValue) ?? 0;
                          return Material(
                            elevation: elevation,
                            color: Colors
                                .transparent, // Let row color shine through
                            shadowColor: Colors.black38,
                            child: child ?? const SizedBox.shrink(),
                          );
                        },
                        child: _buildDragProxy(context, child, index),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildRow(context, widget.rows[index], index),
                      childCount: widget.rows.length,
                    ),
                  ),
                ),
              if (widget.rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      widget.noDataMessage,
                      style: TextStyle(
                        fontSize: 12.0 * widget.scale,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        double dividerWidths = (widget.showCheckboxColumn ? 1.0 : 0.0) + 1.0;
        if (widget.columns.length > 1) {
          for (int i = 0; i < widget.columns.length - 1; i++) {
            final bool isDraggable =
                widget.allowColumnResize &&
                widget.columns[i].resizable &&
                widget.columns[i + 1].resizable;
            dividerWidths += isDraggable ? 10.0 : 1.0;
          }
        }

        final double totalWidth =
            (_columnWidths.isEmpty
                ? 0.0
                : _columnWidths.reduce((a, b) => a + b)) +
            (widget.showCheckboxColumn ? _checkboxColumnWidth : 0) +
            dividerWidths;

        // If the total calculated width of columns exceeds the available screen width,
        // wrap the table in a horizontal scroll view.
        if (totalWidth > constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: totalWidth, child: tableLayout),
          );
        }
        // Otherwise, display as normal, filling the available width.
        return tableLayout;
      },
    );
  }
}

/// A private widget responsible for rendering a single row in the data table.
class _DataTableRow extends StatelessWidget {
  final Map<String, dynamic> rowData;
  final List<DataColumnDef> columns;
  final List<double> columnWidths;
  final String rowId;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHover;
  final void Function(Map<String, dynamic> rowData)? onRowTap;
  final void Function(Map<String, dynamic> rowData)? onRowDoubleTap;
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
  final String rowIdKey;
  final bool allowColumnResize;
  final Widget? treeIconCollapsed;
  final Widget? treeIconExpanded;
  final int index;

  const _DataTableRow({
    required this.rowData,
    required this.columns,
    required this.columnWidths,
    required this.rowId,
    required this.isHovered,
    required this.isSelected,
    required this.onHover,
    this.onRowTap,
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
    required this.rowIdKey,
    required this.allowColumnResize,
    this.treeIconCollapsed,
    this.treeIconExpanded,
    required this.index,
  });

  Widget _buildRowCheckbox() {
    final isSelected = selectedRowIds!.contains(rowId);

    return SizedBox(
      width: _CustomDataTableState._checkboxColumnWidth,
      // Use a GestureDetector to swallow the tap event, so it doesn't
      // trigger the row's InkWell onTap.
      child: GestureDetector(
        onTap: () {},
        child: Center(
          child: Transform.scale(
            scale: 0.85,
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                if (value == null) return;
                Set<String> newSelection = Set.from(selectedRowIds!);
                if (value) {
                  newSelection.add(rowId);
                } else {
                  newSelection.remove(rowId);
                }
                onSelectionChanged!(newSelection);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEffectivelyVisible =
        !isTree || (rowData[isEffectivelyVisibleKey] as bool? ?? true);

    Border? containerBorder;
    final horizontalBorder = border?.horizontalInside;
    if (horizontalBorder != null && horizontalBorder != BorderSide.none) {
      containerBorder = Border(bottom: horizontalBorder);
    } else if (border == null) {
      // Default behavior
      containerBorder = Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      );
    }

    final theme = Theme.of(context);
    final defaultHoverColor = theme.hoverColor;
    final defaultSelectedColor = theme.highlightColor;

    final hoverColor = rowHoverColor ?? defaultHoverColor;
    final selectedColor = rowHoverColor != null
        ? rowHoverColor!.withValues(alpha: 0.3)
        : defaultSelectedColor;
    final selectedHoverColor = rowHoverColor != null
        ? rowHoverColor!.withValues(alpha: 0.45)
        : defaultSelectedColor.withValues(alpha: 0.45);

    Color rowBackgroundColor;
    if (isSelected && isHovered) {
      rowBackgroundColor = selectedHoverColor;
    } else if (isSelected) {
      rowBackgroundColor = selectedColor;
    } else if (isHovered) {
      rowBackgroundColor = hoverColor;
    } else {
      rowBackgroundColor = Colors.transparent;
    }

    // Find the first column that has an itemsBuilder to use for the context menu.
    final DataColumnDef? actionsColumnDef = columns
        .cast<DataColumnDef?>()
        .firstWhere((c) => c?.itemsBuilder != null, orElse: () => null);

    void showRowContextMenu(BuildContext context, Offset tapPosition) {
      if (actionsColumnDef?.itemsBuilder == null) return;

      final menuItems = actionsColumnDef!.itemsBuilder!(context, rowData);
      if (menuItems.isEmpty) return;

      showContextMenu(
        // This was causing an error due to a missing import
        context: context,
        tapPosition: tapPosition,
        menuItems: menuItems,
      );
    }

    final bool showCheckbox = showCheckboxColumn;
    final bool hasDragHandle = columns.isNotEmpty && columns.first.isDragHandle;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Material(
        color: rowBackgroundColor,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: GestureDetector(
            onSecondaryTapUp: (details) =>
                showRowContextMenu(context, details.globalPosition),
            onLongPressStart: (details) =>
                showRowContextMenu(context, details.globalPosition),
            child: isEffectivelyVisible
                ? SizedBox(
                    height: rowHeight * scale,
                    child: Container(
                      decoration: BoxDecoration(border: containerBorder),
                      child: InkWell(
                        onTap: onRowTap != null
                            ? () => onRowTap!(rowData)
                            : null,
                        onDoubleTap: onRowDoubleTap != null
                            ? () => onRowDoubleTap!(rowData)
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showCheckbox && !hasDragHandle) ...[
                              _buildRowCheckbox(),
                              VerticalDivider(
                                width: 1.0,
                                thickness: 0.5,
                                color:
                                    border?.verticalInside.color ??
                                    Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.5),
                              ),
                            ],
                            ...() {
                              final List<Widget> cells = [];
                              for (
                                int colIndex = 0;
                                colIndex < columns.length;
                                colIndex++
                              ) {
                                final column = columns[colIndex];
                                String displayValue;
                                if (column.formattedValue != null) {
                                  displayValue = column.formattedValue!(
                                    rowData,
                                  );
                                } else {
                                  displayValue =
                                      _extractValue(
                                        rowData,
                                        column.id,
                                      )?.toString() ??
                                      '';
                                }

                                Widget cellContent;
                                if (column.cellBuilder != null) {
                                  // If a builder is provided, call it.
                                  cellContent = Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          (column.useCellPadding ? 8.0 : 0.0) *
                                          scale,
                                    ),
                                    child: Align(
                                      alignment: _textAlignToAlignment(
                                        column.alignment,
                                      ),
                                      child:
                                          column.cellBuilder!(
                                            context,
                                            rowData,
                                          ) ??
                                          Text(
                                            displayValue,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                (Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium ??
                                                        TextStyle(
                                                          fontSize:
                                                              14.0 * scale,
                                                        ))
                                                    .copyWith(
                                                      fontSize:
                                                          (Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.fontSize ??
                                                              14.0) *
                                                          scale,
                                                    ),
                                          ),
                                    ),
                                  );
                                } else {
                                  // Default rendering for non-interactive cells.
                                  // It's wrapped in a GestureDetector to handle onRowTap for this specific cell.
                                  cellContent = GestureDetector(
                                    behavior: HitTestBehavior
                                        .opaque, // Ensure the whole cell area is tappable
                                    onTap: onRowTap != null
                                        ? () => onRowTap!(rowData)
                                        : null,
                                    onDoubleTap: onRowDoubleTap != null
                                        ? () => onRowDoubleTap!(rowData)
                                        : null,
                                    child: Container(
                                      // Use a container to fill the cell and align the text
                                      width: double.infinity,
                                      alignment: _textAlignToAlignment(
                                        column.alignment,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            (column.useCellPadding
                                                ? 8.0
                                                : 0.0) *
                                            scale,
                                      ),
                                      child: Text(
                                        displayValue,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            (Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium ??
                                                    TextStyle(
                                                      fontSize: 14.0 * scale,
                                                    ))
                                                .copyWith(
                                                  fontSize:
                                                      (Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.fontSize ??
                                                          14.0) *
                                                      scale,
                                                ),
                                      ),
                                    ),
                                  );
                                }

                                // If the column is configured to only show on hover, wrap the content
                                // in a Visibility widget that is controlled by the row's hover state.
                                if (column.showOnRowHover) {
                                  cellContent = Visibility.maintain(
                                    visible: isHovered,
                                    child: cellContent,
                                  );
                                }

                                // Check if this column is a drag handle and wrap it
                                if (column.isDragHandle) {
                                  // Use the outer 'index' (rowIndex) for the drag listener
                                  cellContent = ReorderableDragStartListener(
                                    index: index,
                                    child: cellContent,
                                  );
                                }

                                if (isTree && column.isNameColumn) {
                                  final int indentation =
                                      rowData[indentationLevelKey] as int? ?? 0;
                                  final bool hasChildren =
                                      rowData[hasChildrenKey] ==
                                      false; // Inverted logic from original
                                  final bool isExpanded =
                                      rowData[isExpandedKey] as bool? ?? false;
                                  final String rowId = _extractValue(
                                    rowData,
                                    rowIdKey,
                                  ).toString();

                                  cellContent = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: indentation * 20.0 * scale,
                                      ),
                                      if (hasChildren) ...[
                                        InkWell(
                                          onTap: () =>
                                              onToggleExpansion!(rowId),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child:
                                                isExpanded // Use provided icons or default Material icons
                                                ? (treeIconExpanded ??
                                                      const Icon(
                                                        Icons.expand_more,
                                                      ))
                                                : (treeIconCollapsed ??
                                                      const Icon(
                                                        Icons.chevron_right,
                                                      )),
                                          ),
                                        ),
                                      ] else
                                        SizedBox(
                                          width: 24.0 * scale,
                                        ), // Keep alignment consistent
                                      const SizedBox(width: 8.0),
                                      Expanded(child: cellContent),
                                    ],
                                  );
                                }

                                final cell = SizedBox(
                                  width: columnWidths[colIndex],
                                  child: cellContent,
                                );

                                cells.add(cell);

                                if (colIndex < columns.length - 1) {
                                  final bool isDraggable =
                                      allowColumnResize &&
                                      columns[colIndex].resizable &&
                                      columns[colIndex + 1].resizable;
                                  cells.add(
                                    VerticalDivider(
                                      width: isDraggable ? 10.0 : 1.0,
                                      thickness: 0.5,
                                      color:
                                          border?.verticalInside.color ??
                                          Theme.of(
                                            context,
                                          ).dividerColor.withValues(alpha: 0.5),
                                    ),
                                  );
                                } else {
                                  cells.add(
                                    VerticalDivider(
                                      width: 1.0,
                                      thickness: 0.5,
                                      color:
                                          border?.verticalInside.color ??
                                          Theme.of(
                                            context,
                                          ).dividerColor.withValues(alpha: 0.5),
                                    ),
                                  );
                                }

                                // Special case: if we have a drag handle at col 0, insert checkbox after it
                                if (colIndex == 0 &&
                                    hasDragHandle &&
                                    showCheckbox) {
                                  cells.add(_buildRowCheckbox());
                                  cells.add(
                                    VerticalDivider(
                                      width: 1.0,
                                      thickness: 0.5,
                                      color:
                                          border?.verticalInside.color ??
                                          Theme.of(
                                            context,
                                          ).dividerColor.withValues(alpha: 0.5),
                                    ),
                                  );
                                }
                              }
                              return cells;
                            }(),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// A private widget responsible for rendering the header of the data table.
class _DataTableHeader extends StatelessWidget {
  final List<DataColumnDef> columns;
  final List<double> columnWidths;
  final void Function(String columnId)? onSort;
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
  final ValueChanged<bool?>? onHeaderCheckboxChanged;
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
    this.onHeaderCheckboxChanged,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Border? containerBorder;
    final horizontalBorder = border?.horizontalInside;
    if (horizontalBorder != null && horizontalBorder != BorderSide.none) {
      containerBorder = Border(bottom: horizontalBorder);
    } else if (border == null) {
      containerBorder = Border(
        bottom: BorderSide(color: Theme.of(context).dividerColor),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: showBottomBorder ? containerBorder : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(columns.length, (index) {
            final column = columns[index];
            final isCurrentSortColumn = sortColumnId == column.id;

            final headerText = Text(
              column.caption,
              style:
                  (Theme.of(context).textTheme.titleSmall ??
                          TextStyle(fontSize: 14.0 * scale))
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14.0) *
                            scale,
                      ),
              overflow: TextOverflow.ellipsis,
            );
            final sortIndicator = isCurrentSortColumn
                ? (sortAscending //
                      ? (sortIconAscending ??
                            Icon(Icons.arrow_upward, size: 16 * scale))
                      : (sortIconDescending ??
                            Icon(Icons.arrow_downward, size: 16 * scale)))
                : const SizedBox.shrink();

            final headerContent = InkWell(
              onTap:
                  column.sortable &&
                      onSort !=
                          null //
                  ? () => onSort!(column.id)
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (column.useCellPadding ? 8.0 : 0.0) * scale,
                ),
                child: Row(
                  mainAxisAlignment: _textAlignToMainAxisAlignment(
                    column.headerAlignment,
                  ),
                  children: [
                    Expanded(child: headerText),
                    if (isCurrentSortColumn) const SizedBox(width: 6),
                    sortIndicator,
                  ],
                ),
              ),
            );

            Widget finalHeaderCell;
            if (index == columns.length - 1 && headerTrailingWidgets != null) {
              finalHeaderCell = SizedBox(
                width: columnWidths[index],
                child: Row(
                  children: [
                    Expanded(child: headerContent),
                    ...headerTrailingWidgets!.map(
                      (builder) => builder(context),
                    ),
                  ],
                ),
              );
            } else {
              finalHeaderCell = SizedBox(
                width: columnWidths[index],
                child: headerContent,
              );
            }

            if (index < columns.length - 1) {
              final bool isDraggable =
                  allowColumnResize &&
                  column.resizable &&
                  columns[index + 1].resizable;
              final divider = isDraggable
                  ? GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          onColumnResize(details, index),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: VerticalDivider(
                          width: 10,
                          thickness: 0.5,
                          color:
                              border?.verticalInside.color ??
                              Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : VerticalDivider(
                      width: 1,
                      thickness: 0.5,
                      color:
                          border?.verticalInside.color ??
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    );
              return [finalHeaderCell, divider];
            }

            return [
              finalHeaderCell,
              VerticalDivider(
                width: 1.0,
                thickness: 0.5,
                color:
                    border?.verticalInside.color ??
                    Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ];
          }).expand((e) => e),
        ],
      ),
    );
  }
}

/// A delegate for `SliverPersistentHeader` that allows for a fixed-height header.
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
