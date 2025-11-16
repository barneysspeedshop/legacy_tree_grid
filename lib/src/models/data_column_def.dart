import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:legacy_context_menu/legacy_context_menu.dart';

/// Defines the type of filtering to apply to a column.
enum FilterType { none, string, numeric, date, list, boolean }

/// Defines the structure and behavior of a column in the CustomDataTable.
///
/// Each column must have either a `flex` value or a `width` value.
class DataColumnDef {
  /// A unique identifier for the column, used for sorting and data mapping.
  /// It can be a nested path like 'user.name'.
  final String id;

  /// The text to display in the column header.
  final String caption;

  /// The flex factor to use for this column. If provided, the column will expand
  /// to fill the available space based on its flex factor.
  final int? flex;

  /// The fixed width for this column.
  final double? width;

  /// A factor to calculate width dynamically. Used in conjunction with custom
  /// width calculation logic.
  final double widthFactor;

  /// The minimum width this column is allowed to be.
  /// When resizing, the user cannot make the column smaller than this value.
  /// Defaults to 50.0.
  final double minWidth;

  /// The alignment of the content within the column. Defaults to `TextAlign.left`.
  /// If not specified, it will automatically be set to `TextAlign.right` for
  /// columns with `filterType` of `FilterType.numeric`.
  final TextAlign alignment;

  /// Whether this column can be sorted. Defaults to `true`.
  final bool sortable;

  /// If `true`, the first sort on this column will be descending.
  /// Defaults to `false`.
  final bool sortDescendingFirst;

  /// An optional custom builder for rendering the cell content.
  /// If not provided, a default `Text` widget will be used.
  final Widget? Function(BuildContext context, Map<String, dynamic> rowData)?
  cellBuilder;

  /// For `FilterType.list`, this provides the dropdown options.
  final List<String>? filterOptions;

  /// The type of filter to use for this column. Defaults to `none`.
  final FilterType filterType;

  /// If `true`, this column will render the expand/collapse icons and indentation
  /// for a tree grid. Only one column should have this set to true.
  final bool isNameColumn;

  /// An optional function to get a formatted string value for display.
  /// If provided, this will be used for the cell's text content instead of
  /// the direct value from the data source. The underlying value from `id`
  /// is still used for sorting and filtering.
  /// The function receives the entire row data map.
  final String Function(Map<String, dynamic> rowData)? formattedValue;

  /// If `true`, the content of this column's cells will only be visible
  /// when the user is hovering over the entire row.
  /// Defaults to `false`.
  final bool showOnRowHover;

  /// Whether this column can be resized by the user.
  /// Only effective if `CustomDataTable.allowColumnResize` is `true`.
  /// Defaults to `true`.
  final bool resizable;

  /// An optional builder for creating context menu items for a row.
  /// If provided, this will be used to show a context menu on secondary-click/long-press.
  final List<ContextMenuItem> Function(
    BuildContext context,
    Map<String, dynamic> rowData,
  )?
  itemsBuilder;

  DataColumnDef({
    required this.id,
    required this.caption,
    this.flex,
    this.width,
    this.widthFactor = 1.0,
    required this.minWidth,
    TextAlign? alignment,
    this.sortable = true,
    this.sortDescendingFirst = false,
    this.cellBuilder,
    this.filterOptions,
    this.filterType = FilterType.none,
    this.isNameColumn = false,
    this.formattedValue,
    this.showOnRowHover = false,
    this.resizable = true,
    this.itemsBuilder,
  }) : alignment =
           alignment ??
           (filterType == FilterType.numeric
               ? TextAlign.right
               : TextAlign.left),
       assert(
         flex != null || width != null,
         'Either flex or width must be provided for a column.',
       ),
       assert(
         filterType != FilterType.list ||
             (filterOptions != null && filterOptions.isNotEmpty),
         'If filterType is list, filterOptions must be provided and not empty.',
       );

  /// A factory for creating a standard, non-resizable "Actions" column.
  ///
  /// This provides a convenient way to create a column for action buttons
  /// with sensible defaults: fixed width, non-resizable, and non-sortable.
  factory DataColumnDef.actions({
    String id = 'actions',
    String caption = '',
    double width = 30.0,
    required List<ContextMenuItem> Function(
      BuildContext context,
      Map<String, dynamic> rowData,
    )
    itemsBuilder,
    bool showOnRowHover = true,
  }) {
    return DataColumnDef(
      id: id,
      caption: caption,
      width: width,
      minWidth: width,
      resizable: false, // Actions columns are never resizable.
      sortable: false, // Actions columns are not sortable.
      alignment: TextAlign.center,
      showOnRowHover: showOnRowHover,
      itemsBuilder: itemsBuilder,
      cellBuilder: (context, rowData) {
        // Use a Builder to get a context that is a descendant of the cell,
        // which is crucial for correctly positioning the menu relative to the button.
        return Builder(
          builder: (buttonContext) {
            return Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  final RenderBox button =
                      buttonContext.findRenderObject() as RenderBox;
                  // Position the menu at the bottom-left of the button.
                  final Offset position = button.localToGlobal(
                    Offset(0, button.size.height),
                  );

                  showContextMenu(
                    context: context,
                    tapPosition: position,
                    menuItems: itemsBuilder(context, rowData),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(
                    4.0,
                  ), // Smaller padding for the tap target
                  child: FaIcon(FontAwesomeIcons.ellipsis, size: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
