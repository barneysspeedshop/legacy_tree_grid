import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/src/utils/scale_notifier.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// Defines the types of actions that can be displayed in the footer.
/// Used to configure the order of the action buttons.
enum FooterActionType {
  add,
  delete,
  clearFilters,
  firstPage,
  previousPage,
  nextPage,
  lastPage,
  refresh,
}

/// Helper class to define the properties of a footer action.
class _FooterAction {
  final IconData icon;
  final String tooltip;
  final String menuText;
  final VoidCallback? onPressed;

  _FooterAction({
    required this.icon,
    required this.tooltip,
    required this.menuText,
    this.onPressed,
  });
}

/// A private helper widget to ensure that the `leadingWidgets` are built with a
/// BuildContext that is a descendant of the `Material` widget in the footer.
/// This is crucial for overlay widgets like DropdownButton to position themselves correctly.
class _LeadingWidgetsWrapper extends StatelessWidget {
  final List<WidgetBuilder> builders;
  const _LeadingWidgetsWrapper({required this.builders});

  @override
  Widget build(BuildContext context) {
    // The 'context' passed to this build method is correctly scoped under the
    // Material widget that is the parent of this wrapper.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: builders.map((builder) => builder(context)).toList(),
    );
  }
}

/// A responsive data grid footer that collapses actions into an overflow menu on smaller screens.
/// It adapts its layout based on the available width.

class DataGridFooter extends StatefulWidget {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int? totalPages; // Optional for non-paginated grids
  final VoidCallback onRefresh;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onFirstPage;
  final VoidCallback? onLastPage;
  // Optional actions for the footer toolbar
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onClearFilters;
  final bool? showDeleted;
  final ValueChanged<bool?>? onShowDeletedChanged;
  final bool isUndeleteMode;
  final List<WidgetBuilder>? leadingWidgets;
  final bool? includeChildrenInFilter;
  final ValueChanged<bool?>? onIncludeChildrenInFilterChanged;

  /// An optional list to define the order of action buttons in the footer.
  /// If not provided, a default order will be used.
  final List<FooterActionType>? actionOrder;

  const DataGridFooter({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    this.totalPages,
    required this.onRefresh,
    this.onPreviousPage,
    this.onNextPage,
    this.onFirstPage,
    this.onLastPage,
    this.onAdd,
    this.onDelete,
    this.onClearFilters,
    this.showDeleted,
    this.onShowDeletedChanged,
    this.isUndeleteMode = false,
    this.leadingWidgets,
    this.includeChildrenInFilter,
    this.onIncludeChildrenInFilterChanged,
    this.actionOrder,
  });

  @override
  State<DataGridFooter> createState() => _DataGridFooterState();
}

class _DataGridFooterState extends State<DataGridFooter> {
  final GlobalKey _leadingWidgetsKey = GlobalKey();
  double _leadingWidgetsWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureLeadingWidgets(),
    );
  }

  void _measureLeadingWidgets() {
    final context = _leadingWidgetsKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        if (mounted && renderBox.size.width != _leadingWidgetsWidth) {
          setState(() {
            _leadingWidgetsWidth = renderBox.size.width;
          });
        }
      }
    }
  }

  /// Measures the width of a given text with a specific style.
  double _getTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  Widget _buildIconButton(_FooterAction action, double size, Color color) {
    return IconButton(
      icon: FaIcon(action.icon, size: size, color: color),
      tooltip: action.tooltip,
      onPressed: action.onPressed,
    );
  }

  Widget _buildOverflowMenu(
    List<_FooterAction> actions,
    double size,
    Color color,
  ) {
    return PopupMenuButton<_FooterAction>(
      icon: FaIcon(FontAwesomeIcons.ellipsisVertical, size: size, color: color),
      tooltip: 'More Actions',
      onSelected: (selectedAction) => selectedAction.onPressed?.call(),
      itemBuilder: (BuildContext context) {
        return actions.map((action) {
          return PopupMenuItem<_FooterAction>(
            value: action,
            enabled: action.onPressed != null,
            child: Text(action.menuText),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rerun measurement after build if the widgets might have changed.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureLeadingWidgets(),
    );

    final theme = Theme.of(context);
    final scale = context.watch<ScaleNotifier?>()?.scale ?? 1.0;
    final hasPagination = widget.totalPages != null && widget.totalPages! > 1;
    const Color iconColor = Color(0xFF3b89b9);
    const double baseRowHeight = 48.0;
    const double baseIconSize = 16.0;
    final double scaledIconSize = baseIconSize * scale;
    final textStyle = TextStyle(fontSize: 14.0 * scale);

    // --- Define all possible icon actions ---
    final addAction = widget.onAdd == null
        ? null
        : _FooterAction(
            icon: FontAwesomeIcons.circlePlus,
            tooltip: 'Add New',
            menuText: 'Add New',
            onPressed: widget.onAdd,
          );
    final deleteAction = widget.onDelete == null
        ? null
        : _FooterAction(
            icon: widget.isUndeleteMode
                ? FontAwesomeIcons.trashCanArrowUp
                : FontAwesomeIcons.trashCan,
            tooltip: widget.isUndeleteMode
                ? 'Undelete Selected'
                : 'Delete Selected',
            menuText: widget.isUndeleteMode
                ? 'Undelete Selected'
                : 'Delete Selected',
            onPressed: widget.onDelete,
          );
    final clearFiltersAction = widget.onClearFilters == null
        ? null
        : _FooterAction(
            icon: FontAwesomeIcons.filterCircleXmark,
            tooltip: 'Clear All Filters',
            menuText: 'Clear Filters',
            onPressed: widget.onClearFilters,
          );

    _FooterAction? firstPageAction,
        prevPageAction,
        nextPageAction,
        lastPageAction;
    if (hasPagination) {
      firstPageAction = _FooterAction(
        icon: FontAwesomeIcons.anglesLeft,
        tooltip: 'First Page',
        menuText: 'First Page',
        onPressed: widget.currentPage > 1 ? widget.onFirstPage : null,
      );
      prevPageAction = _FooterAction(
        icon: FontAwesomeIcons.angleLeft,
        tooltip: 'Previous Page',
        menuText: 'Previous Page',
        onPressed: widget.currentPage > 1 ? widget.onPreviousPage : null,
      );
      nextPageAction = _FooterAction(
        icon: FontAwesomeIcons.angleRight,
        tooltip: 'Next Page',
        menuText: 'Next Page',
        onPressed: widget.currentPage < widget.totalPages!
            ? widget.onNextPage
            : null,
      );
      lastPageAction = _FooterAction(
        icon: FontAwesomeIcons.anglesRight,
        tooltip: 'Last Page',
        menuText: 'Last Page',
        onPressed: widget.currentPage < widget.totalPages!
            ? widget.onLastPage
            : null,
      );
    }
    final refreshAction = _FooterAction(
      icon: FontAwesomeIcons.rotate,
      tooltip: 'Refresh',
      menuText: 'Refresh Data',
      onPressed: widget.onRefresh,
    );

    // --- Build the list of actions based on the configured order ---
    final Map<FooterActionType, _FooterAction> actionsMap = {
      if (addAction != null) FooterActionType.add: addAction,
      if (deleteAction != null) FooterActionType.delete: deleteAction,
      if (clearFiltersAction != null)
        FooterActionType.clearFilters: clearFiltersAction,
      if (firstPageAction != null) FooterActionType.firstPage: firstPageAction,
      if (prevPageAction != null) FooterActionType.previousPage: prevPageAction,
      if (nextPageAction != null) FooterActionType.nextPage: nextPageAction,
      if (lastPageAction != null) FooterActionType.lastPage: lastPageAction,
      FooterActionType.refresh: refreshAction,
    };

    // Use the provided order, or a default order if null.
    final List<FooterActionType> order =
        widget.actionOrder ??
        const [
          FooterActionType.add,
          FooterActionType.delete,
          FooterActionType.clearFilters,
          FooterActionType.firstPage,
          FooterActionType.previousPage,
          FooterActionType.nextPage,
          FooterActionType.lastPage,
          FooterActionType.refresh,
        ];

    // This list defines the on-screen and overflow order of all icons
    final allIconActions = order
        .map((type) => actionsMap[type])
        .whereType<_FooterAction>()
        .toList();

    // --- Build Records Display Text ---
    String recordsRange = '0 - 0';
    if (widget.totalRecords > 0) {
      int start = (widget.currentPage - 1) * widget.pageSize + 1;
      int end = (widget.currentPage * widget.pageSize).clamp(
        0,
        widget.totalRecords,
      );
      recordsRange = '$start - $end';
    }
    final recordsText =
        'Displaying records $recordsRange of ${widget.totalRecords}';

    final leadingWidgetsRow =
        (widget.leadingWidgets != null && widget.leadingWidgets!.isNotEmpty)
        ? Row(
            key: _leadingWidgetsKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              // const VerticalDivider(indent: 12, endIndent: 12, width: 24),
              _LeadingWidgetsWrapper(builders: widget.leadingWidgets!),
            ],
          )
        : const SizedBox.shrink();

    // By wrapping the entire footer in a Material widget, we ensure that any
    // BuildContext used within its descendants (including inside the LayoutBuilder)
    // can correctly find the Material's RenderObject. This is essential for
    // overlay-based widgets like DropdownButton to position themselves correctly.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: baseRowHeight * scale,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // --- 1. Calculate width of all non-icon elements ---
            double fixedWidth = 0;
            const double checkboxWidth =
                48.0; // Standard width for a checkbox with padding
            const double textPadding = 8.0;

            Widget? showDeletedGroup;
            if (widget.showDeleted != null &&
                widget.onShowDeletedChanged != null) {
              final text = 'Show Deleted Only';
              final textWidth = _getTextWidth(text, textStyle);
              fixedWidth += checkboxWidth + textWidth + 16; // 16 for SizedBox
              showDeletedGroup = InkWell(
                onTap: () {
                  // This makes the entire area (text and checkbox) tappable, toggling the state.
                  widget.onShowDeletedChanged?.call(!widget.showDeleted!);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: widget.showDeleted,
                      onChanged: widget.onShowDeletedChanged,
                    ),
                    Text(text, style: textStyle),
                  ],
                ),
              );
            }

            Widget? includeChildrenGroup;
            if (widget.includeChildrenInFilter != null &&
                widget.onIncludeChildrenInFilterChanged != null) {
              final text = 'Filter Includes Children';
              final textWidth = _getTextWidth(text, textStyle);
              fixedWidth += checkboxWidth + textWidth + 16; // 16 for SizedBox
              includeChildrenGroup = InkWell(
                onTap: () {
                  widget.onIncludeChildrenInFilterChanged?.call(
                    !widget.includeChildrenInFilter!,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: widget.includeChildrenInFilter,
                      onChanged: widget.onIncludeChildrenInFilterChanged,
                    ),
                    Text(text, style: textStyle),
                  ],
                ),
              );
            }

            final recordsTextWidth = _getTextWidth(recordsText, textStyle);
            fixedWidth += recordsTextWidth + textPadding; // 8 for SizedBox

            Widget? pageTextWidget;
            if (hasPagination) {
              final pageText =
                  'Page ${widget.currentPage} of ${widget.totalPages}';
              pageTextWidget = Padding(
                padding: const EdgeInsets.symmetric(horizontal: textPadding),
                child: Text(pageText, style: textStyle),
              );
              final pageTextWidth = _getTextWidth(pageText, textStyle);
              fixedWidth += pageTextWidth + (textPadding * 2);
            }

            // --- 2. Determine how many icons can fit ---
            const double iconButtonWidth = 48.0; // Standard touch target size
            double availableWidth =
                constraints.maxWidth -
                fixedWidth -
                _leadingWidgetsWidth -
                16.0 -
                8.0;

            int maxVisibleIcons = (availableWidth / iconButtonWidth).floor();
            List<_FooterAction> visibleIcons;
            List<_FooterAction> overflowIcons;

            final bool needsOverflow = allIconActions.length > maxVisibleIcons;
            if (needsOverflow) {
              // Account for the overflow button itself, which takes up one icon slot
              final numVisible = (maxVisibleIcons - 1).clamp(
                0,
                allIconActions.length,
              );
              visibleIcons = allIconActions.sublist(0, numVisible);
              overflowIcons = allIconActions.sublist(numVisible);
            } else {
              visibleIcons = allIconActions;
              overflowIcons = [];
            }
            final visibleIconsSet = Set.from(visibleIcons);

            // --- 3. Build the final Row with visible items ---
            final bool anyLeftIconsVisible = [
              addAction,
              deleteAction,
              clearFiltersAction,
            ].whereType<_FooterAction>().any(visibleIconsSet.contains);
            final bool anyPaginationIconsVisible = [
              firstPageAction,
              prevPageAction,
              nextPageAction,
              lastPageAction,
            ].whereType<_FooterAction>().any(visibleIconsSet.contains);

            return Row(
              children: [
                // --- Left Side Actions ---
                if (addAction != null && visibleIconsSet.contains(addAction))
                  _buildIconButton(addAction, scaledIconSize, iconColor),
                if (deleteAction != null &&
                    visibleIconsSet.contains(deleteAction))
                  _buildIconButton(deleteAction, scaledIconSize, iconColor),
                if (clearFiltersAction != null &&
                    visibleIconsSet.contains(clearFiltersAction))
                  _buildIconButton(
                    clearFiltersAction,
                    scaledIconSize,
                    iconColor,
                  ),

                if (showDeletedGroup != null) ...[
                  if (anyLeftIconsVisible) const SizedBox(width: 16),
                  showDeletedGroup,
                ],
                if (includeChildrenGroup != null) ...[includeChildrenGroup],

                leadingWidgetsRow,

                const Spacer(),

                // --- Right Side Pagination ---
                if (firstPageAction != null &&
                    visibleIconsSet.contains(firstPageAction))
                  _buildIconButton(firstPageAction, scaledIconSize, iconColor),
                if (prevPageAction != null &&
                    visibleIconsSet.contains(prevPageAction))
                  _buildIconButton(prevPageAction, scaledIconSize, iconColor),

                if (pageTextWidget != null) pageTextWidget,

                if (nextPageAction != null &&
                    visibleIconsSet.contains(nextPageAction))
                  _buildIconButton(nextPageAction, scaledIconSize, iconColor),
                if (lastPageAction != null &&
                    visibleIconsSet.contains(lastPageAction))
                  _buildIconButton(lastPageAction, scaledIconSize, iconColor),

                if (anyPaginationIconsVisible) const SizedBox(width: 16),

                if (visibleIconsSet.contains(refreshAction))
                  _buildIconButton(refreshAction, scaledIconSize, iconColor),
                const SizedBox(width: 8),
                Text(recordsText, style: textStyle),
                if (overflowIcons.isNotEmpty)
                  _buildOverflowMenu(overflowIcons, scaledIconSize, iconColor),
              ],
            );
          },
        ),
      ),
    );
  }
}
