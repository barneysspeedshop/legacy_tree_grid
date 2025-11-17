import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final double rowHeight;
  final double headerHeight;
  final void Function(Map<String, dynamic> rowData)? onRowTap;
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

  /// The border to display between rows and columns.
  /// Use `TableBorder.symmetric(inside: ...)` to add borders between cells.
  final TableBorder? border;

  /// Whether to show the filter row beneath the header.
  final bool allowFiltering;

  /// Whether to allow users to resize columns by dragging the header dividers.
  final bool allowColumnResize;

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

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.rowHeight = 25.0,
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
    // Calculate total width of dividers between columns.
    final double dividerWidths = widget.columns.length > 1
        ? widget.columns
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
              .reduce((a, b) => a + b)
        : 0;

    // Calculate the total width available for all columns.
    final double availableWidth =
        constraints.maxWidth -
        (widget.showCheckboxColumn ? _checkboxColumnWidth : 0) -
        dividerWidths;

    List<double> finalWidths;

    if (widget.useAvailableWidthDistribution) {
      // --- NEW LOGIC for Calendar View ---
      // This logic uses the explicit `width` properties, scales them, and then
      // distributes extra space if available. It's designed for views that
      // might need to scroll horizontally.
      final List<double> initialWidths = widget.columns.map((col) {
        return (col.width ?? col.minWidth) * widget.scale;
      }).toList();

      final double sumOfInitialWidths = initialWidths.reduce((a, b) => a + b);

      if (sumOfInitialWidths < availableWidth) {
        final double extraSpace = availableWidth - sumOfInitialWidths;
        final nameColumnIndex = widget.columns.indexWhere(
          (col) => col.isNameColumn,
        );

        finalWidths = List.from(initialWidths);
        if (nameColumnIndex != -1) {
          finalWidths[nameColumnIndex] += extraSpace;
        } else if (finalWidths.isNotEmpty) {
          finalWidths[0] += extraSpace;
        }
      } else {
        finalWidths = initialWidths;
      }
    } else {
      // --- OLD LOGIC (DEFAULT) for other views ---
      // This logic uses a mix of `flex` and `width` to proportionally
      // fill the available screen space without horizontal scrolling.
      double totalFlex = 0.0;
      double totalFixedWidth = 0.0;

      for (final column in widget.columns) {
        if (column.width != null) {
          totalFixedWidth += column.width! * widget.scale;
        } else {
          totalFlex += (column.flex ?? 1).toDouble();
        }
      }

      final double availableWidthForFlex = availableWidth - totalFixedWidth;
      final double widthPerFlex = (availableWidthForFlex > 0 && totalFlex > 0)
          ? availableWidthForFlex / totalFlex
          : 0;

      finalWidths = widget.columns.map((column) {
        if (column.width != null) {
          return column.width! * widget.scale;
        } else {
          return (column.flex ?? 1) * widthPerFlex;
        }
      }).toList();
    }

    // Ensure no column is smaller than its defined minimum width.
    finalWidths = List.generate(widget.columns.length, (index) {
      final col = widget.columns[index];
      final width = finalWidths[index];
      return width.clamp(col.minWidth, double.infinity);
    });

    setState(() {
      _columnWidths = finalWidths;
      _widthsInitialized = true;
      widget.onColumnWidthsChanged?.call(finalWidths);
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

  Widget _buildHeader() {
    if (widget.headerRowBuilder != null) {
      return widget.headerRowBuilder!(context, widget.columns);
    }

    return _DataTableHeader(
      columns: widget.columns,
      columnWidths: _columnWidths,
      onSort: widget.onSort,
      sortColumnId: widget.sortColumnId,
      sortAscending: widget.sortAscending,
      allowColumnResize: widget.allowColumnResize,
      onColumnResize: _handleDragUpdate,
      border: widget.border,
      showCheckboxColumn: widget.showCheckboxColumn,
      rows: widget.rows,
      rowIdKey: widget.rowIdKey,
      selectedRowIds: widget.selectedRowIds,
      onSelectionChanged: widget.onSelectionChanged,
    );
  }

  Widget _buildFilterRow() {
    if (!widget.allowFiltering) {
      return const SizedBox.shrink();
    }

    if (widget.filterRowBuilder != null) {
      return widget.filterRowBuilder!(context, widget.columns, _columnWidths);
    }

    // The default implementation is removed. The parent must provide a builder.
    return const SizedBox.shrink();
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

  Widget _buildRow(BuildContext context, Map<String, dynamic> rowData) {
    if (widget.rowBuilder != null) {
      return widget.rowBuilder!(context, rowData, widget.columns);
    }
    final rowId = _extractValue(rowData, widget.rowIdKey!).toString();

    return _DataTableRow(
      rowData: rowData,
      columns: widget.columns,
      columnWidths: _columnWidths,
      rowId: rowId,
      isHovered: _hoveredRowId == rowId,
      isSelected: _selectedRowId == rowId,
      onHover: (hovering) {
        if (!mounted) return;
        setState(() {
          _hoveredRowId = hovering ? rowId : null;
        });
      },
      onRowTap: _handleRowTap,
      rowHoverColor: widget.rowHoverColor,
      rowHeight: widget.rowHeight,
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

        if (constraintsChanged && widget.initialColumnWidths == null) {
          // Post a frame callback to avoid calling setState during a build.
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
                  height: widget.headerHeight * widget.scale,
                  child: Material(
                    // Use Material to provide a solid background color that
                    // prevents rows from showing through during overscroll.
                    color: Theme.of(context).canvasColor,
                    child: _buildHeader(),
                  ),
                ),
              ),
              if (widget.allowFiltering)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    height: widget.rowHeight * widget.scale,
                    child: Material(
                      color: Theme.of(context).canvasColor,
                      child: _buildFilterRow(),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRow(context, widget.rows[index]),
                  childCount: widget.rows.length,
                ),
              ),
            ],
          ),
        );

        double dividerWidths = 0;
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
            _columnWidths.reduce((a, b) => a + b) +
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

  const _DataTableRow({
    required this.rowData,
    required this.columns,
    required this.columnWidths,
    required this.rowId,
    required this.isHovered,
    required this.isSelected,
    required this.onHover,
    this.onRowTap,
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showCheckboxColumn) _buildRowCheckbox(),
                          ...List.generate(columns.length, (index) {
                            final column = columns[index];
                            String displayValue;
                            if (column.formattedValue != null) {
                              displayValue = column.formattedValue!(rowData);
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
                              cellContent =
                                  column.cellBuilder!(context, rowData) ??
                                  Text(
                                    displayValue,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                child: Container(
                                  // Use a container to fill the cell and align the text
                                  width: double.infinity,
                                  alignment: _textAlignToAlignment(
                                    column.alignment,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    displayValue,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                  SizedBox(width: indentation * 20.0 * scale),
                                  if (hasChildren)
                                    InkWell(
                                      onTap: () => onToggleExpansion!(rowId),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: FaIcon(
                                          isExpanded
                                              ? FontAwesomeIcons.caretDown
                                              : FontAwesomeIcons.caretRight,
                                          size: 16 * scale,
                                          color: Theme.of(
                                            context,
                                          ).iconTheme.color,
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: 24.0 * scale,
                                    ), // Keep alignment consistent
                                  SizedBox(width: 8.0 * scale),
                                  Expanded(child: cellContent),
                                ],
                              );
                            }

                            final cell = SizedBox(
                              width: columnWidths[index],
                              child: cellContent,
                            );

                            if (index < columns.length - 1) {
                              final bool isDraggable =
                                  allowColumnResize &&
                                  columns[index].resizable &&
                                  columns[index + 1].resizable;

                              final divider = VerticalDivider(
                                width: isDraggable ? 10.0 : 1.0,
                                thickness: 1,
                                color: border?.verticalInside.color,
                              );
                              return [cell, divider];
                            }
                            return [cell];
                          }).expand((e) => e),
                        ],
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
  });

  Widget _buildSelectAllCheckbox() {
    final displayedIds = rows
        .map((row) => _extractValue(row, rowIdKey!).toString())
        .toSet();
    final selectedDisplayedIds = selectedRowIds!.intersection(displayedIds);

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
      width: _CustomDataTableState._checkboxColumnWidth,
      child: Center(
        child: Checkbox(
          value: isChecked,
          tristate: true,
          onChanged: (bool? value) {
            final bool shouldSelectAll = isChecked != true;
            Set<String> newSelection = Set.from(selectedRowIds!);
            if (shouldSelectAll) {
              newSelection.addAll(displayedIds);
            } else {
              newSelection.removeAll(displayedIds);
            }
            onSelectionChanged!(newSelection);
          },
        ),
      ),
    );
  }

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
      decoration: BoxDecoration(border: containerBorder),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCheckboxColumn) _buildSelectAllCheckbox(),
          ...List.generate(columns.length, (index) {
            final column = columns[index];
            final isCurrentSortColumn = sortColumnId == column.id;

            final headerText = Text(
              column.caption,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            );
            final sortIndicator = isCurrentSortColumn
                ? FaIcon(
                    sortAscending
                        ? FontAwesomeIcons.arrowUp
                        : FontAwesomeIcons.arrowDown,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : const SizedBox.shrink();

            final headerContent = InkWell(
              onTap: column.sortable && onSort != null
                  ? () => onSort!(column.id)
                  : null,
              child: Row(
                mainAxisAlignment: _textAlignToMainAxisAlignment(
                  column.alignment,
                ),
                children: [
                  Expanded(child: headerText),
                  if (isCurrentSortColumn) const SizedBox(width: 6),
                  sortIndicator,
                ],
              ),
            );

            final headerCell = SizedBox(
              width: columnWidths[index],
              child: headerContent,
            );

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
                          thickness: 1,
                          color: border?.verticalInside.color,
                        ),
                      ),
                    )
                  : VerticalDivider(
                      width: 1,
                      color: border?.verticalInside.color,
                    );
              return [headerCell, divider];
            }
            return [headerCell];
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
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    // Rebuild if the child or height has changed. This is important for
    // dynamic content like sort indicators or filter values.
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
