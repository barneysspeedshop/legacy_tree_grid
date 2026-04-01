import 'package:flutter/material.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart';

/// Defines the type of filtering to apply to a column.
enum FilterType { none, string, numeric, date, list, boolean }

/// Defines the structure and behavior of a column in the CustomDataTable.
class DataColumnDef {
  final String id;
  final String caption;
  final int? flex;
  final double? width;
  final double widthFactor;
  final double minWidth;
  final double? maxWidth;
  final TextAlign alignment;
  final TextAlign headerAlignment;
  final bool sortable;
  final bool sortDescendingFirst;
  final Widget? Function(BuildContext context, dynamic rawValue, String displayValue, double scale, Map<String, dynamic> rowData)? cellBuilder;
  final List<String>? filterOptions;
  final Map<String, String>? filterOptionsMap;
  final FilterType filterType;
  final bool isNameColumn;
  final String Function(dynamic rawValue, Map<String, dynamic> rowData)? formattedValue;
  final bool showOnRowHover;
  final bool resizable;
  final bool isDragHandle;
  final bool useCellPadding;
  final List<ContextMenuItem> Function(BuildContext context, Map<String, dynamic> rowData)? itemsBuilder;

  DataColumnDef({
    required this.id,
    required this.caption,
    this.flex,
    this.width,
    this.widthFactor = 1.0,
    this.minWidth = 50.0,
    this.maxWidth,
    TextAlign? alignment,
    TextAlign? headerAlignment,
    this.sortable = true,
    this.sortDescendingFirst = false,
    this.cellBuilder,
    this.filterOptions,
    this.filterOptionsMap,
    this.filterType = FilterType.none,
    this.isNameColumn = false,
    this.formattedValue,
    this.showOnRowHover = false,
    this.resizable = true,
    this.isDragHandle = false,
    this.useCellPadding = true,
    this.itemsBuilder,
  }) : alignment = alignment ?? (filterType == FilterType.numeric ? TextAlign.right : TextAlign.left),
       headerAlignment = headerAlignment ?? alignment ?? (filterType == FilterType.numeric ? TextAlign.right : TextAlign.left),
       assert(filterType != FilterType.list || (filterOptions != null && filterOptions.isNotEmpty) || (filterOptionsMap != null && filterOptionsMap.isNotEmpty));

  factory DataColumnDef.actions({
    String id = 'actions',
    String caption = '',
    double width = 30.0,
    TextAlign? alignment,
    TextAlign? headerAlignment,
    List<ContextMenuItem> Function(BuildContext context, Map<String, dynamic> rowData)? itemsBuilder,
    Widget? actionIcon,
    bool showOnRowHover = true,
  }) {
    return DataColumnDef(
      id: id,
      caption: caption,
      width: width,
      minWidth: width,
      resizable: false,
      sortable: false,
      alignment: alignment ?? TextAlign.center,
      headerAlignment: headerAlignment ?? alignment ?? TextAlign.center,
      showOnRowHover: showOnRowHover,
      useCellPadding: false,
      itemsBuilder: itemsBuilder,
      cellBuilder: (context, rawValue, displayValue, scale, rowData) {
        if (itemsBuilder == null) return null;
        return Builder(
          builder: (buttonContext) {
            return Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                  final Offset position = button.localToGlobal(Offset(0, button.size.height));
                  showContextMenu(context: context, tapPosition: position, menuItems: itemsBuilder(context, rowData));
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: actionIcon ?? const Icon(Icons.more_horiz, size: 18),
                ),
              ),
            );
          },
        );
      },
    );
  }

  factory DataColumnDef.reorder({String id = 'reorder', double width = 32.0, Widget? icon, bool showOnRowHover = true}) {
    return DataColumnDef(
      id: id,
      caption: '',
      width: width,
      minWidth: width,
      resizable: false,
      sortable: false,
      alignment: TextAlign.center,
      headerAlignment: TextAlign.center,
      isDragHandle: true,
      showOnRowHover: showOnRowHover,
      cellBuilder: (context, rawValue, displayValue, scale, rowData) => Center(
        child: icon ?? const Icon(Icons.drag_indicator, size: 20, color: Colors.grey),
      ),
    );
  }

  factory DataColumnDef.dragHandle({String id = 'drag_handle', String caption = '', double width = 30.0, Widget? icon}) {
    return DataColumnDef(
      id: id,
      caption: caption,
      width: width,
      minWidth: width,
      maxWidth: width,
      resizable: false,
      sortable: false,
      isDragHandle: true,
      showOnRowHover: true,
      useCellPadding: false,
      alignment: TextAlign.center,
      cellBuilder: (context, rawValue, displayValue, scale, rowData) {
        return Icon(Icons.drag_indicator, size: 20.0, color: Theme.of(context).disabledColor);
      },
    );
  }
}
