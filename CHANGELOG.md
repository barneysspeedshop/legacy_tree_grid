## 0.14.3

* **FIX**: Fix for an issue that caused horizontal overflow. 

## 0.14.2

* **FIX**: Fix for an issue that caused the header height to overflow by 1px in customDataTable.

## 0.14.1

* **FIX**: Fix for an issue that caused the header height to be ignored

## 0.14.0

### Features
* **Programmatic Tree Control**: Exposed `expandRow`, `collapseRow`, and `setRowExpansion` on `ClientSideDataGrid` and `ServerSideDataGrid` via their state objects.
* **Intelligent Auto-Expansion**: Target parent rows now automatically expand when a child is nested inside them during drag-and-drop.
* **Server-Side Tree Support**: 
    - `DataGridFetchOptions` now includes `expandedRowIds` for stateful server-side tree generation.
    - Optimized "silent refreshes" for server-side grids to eliminate jarring full-grid loaders during tree navigation and reordering.
    - Prioritized the `hasChildren` flag in data to support robust lazy-loading scenarios.
* **Enhanced UX**: Restricted drag-and-drop interactions to dedicated handle columns for a more intentional and premium user experience.

### Stability & Fixes
* **Circular Nesting Protection**: Implemented robust ancestry checks to prevent disappearing rows caused by circular parent-child dependencies.
* **Row ID Resolution**: Fixed a critical bug where reordering callbacks incorrectly passed row indices instead of unique identifiers.
* **State Management**: Improved the synchronization of `indentationLevel` and `visibility` flags across all grid wrappers.
* **Context Menu**: Restored and stabilized right-click `legacy_context_menu` support across all grid implementations.

## 0.13.1

* **FIX**: Fix for an issue that prevented header alignment from being applied.

## 0.13.0

* **FEATURE**: Dynamic Grid Control Panel for testing different configurations in the example application.
* **FEATURE**: Smarter Column Layout System combining flexible proportional layouts with minWidth/maxWidth/fixed constraints, including logic to absorb horizontal space via `useAvailableWidthDistribution`.
* **FEATURE**: Added `DataColumnDef.dragHandle()` factory for drag-and-drop row reordering.
* **FEATURE**: Expanded `DataColumnDef` with `maxWidth`, `headerAlignment`, `filterOptionsMap`, and `useCellPadding`.
* **FEATURE**: Unified Pinned Headers and Filter row into a single `SliverPersistentHeader` to ensure consistent overlapping limits and borders.
* **FEATURE**: Added an interlocking global "Select All" tri-state checkbox directly to the header when multi-selection checkboxes are enabled. Added `selectedRowIds` and `onSelectionChanged` properties strictly at the wrapper level.
* **FEATURE**: Introduced an `onRowDoubleTap` callback for double-click behavior.
* **FEATURE**: Implemented `treeIconCollapsed` and `treeIconExpanded` options for custom tree parent node expansion icons.
* **FEATURE**: Added `footerLeadingWidgets` property to trailing footer actions, along with `filterRowHeight` and `showFilterCellBorder` options.
* **FIX**: Decreased the default `ScaleNotifier` zoom factor from `1.0` to `0.85` for a higher-density base widget size.
* **FIX**: Optimized bounds-checking logic inside `CustomDataTable` to avoid redundant column rescans when scaling or constraints don't force a wrap.
* **FIX**: Improved grid layout performance by flattening the row iteration tree in `CustomDataTable` during build to reduce inner memory allocations.
* **FIX**: Transferred mock tree data logic in the example app to local state, fixing the expand/collapse behaviors effectively.
* **FIX**: Added `noDataMessage` label (defaulting to "No records found") rendered directly via slivers for empty grids.

## 0.12.0

* **FEATURE**: Added support for drag-and-drop row reordering.
  * Added `onReorder` callback to `UnifiedDataGrid` and `CustomDataTable`.
  * Added `isDragHandle` property to `DataColumnDef` to designate specific columns as drag handles.
  * Implemented smart drag proxy generation to visually drag entire subtrees when reordering expanded parent nodes.

## 0.11.0

* **FEATURE**: Add `isExpandedKey` for more capabilities associated with programmatic expansion.

## 0.10.0

* **FEATURE**: Add `expandRow` and `collapseRow` methods to the UnifiedDataGridState to allow programmatic expansion and collapse of rows.
* **FEATURE**: Add `setRowExpansion` method to the UnifiedDataGridState to allow programmatic expansion and collapse of rows.

## 0.9.1

* **FIX**: Fix for an issue that caused the `selectedRowId` to fail to propagate to the selected row in Unified Data Grid.

## 0.9.0

* **FEATURE**: Add `selectedRowId` so you can programmatically select a row in the Unified Data Grid.

## 0.8.0

* **FEATURE**: Added `allowSorting` so you can disable sorting in the Unified Data Grid.

## 0.7.0

* **FEATURE**: Added two optional properties to the UnifiedDataGrid widget:
    * `initialExpandedRowIds`: A `Set<String>` to specify which tree nodes should be expanded when the grid first loads.
    * `onRowToggle`: A callback `void Function(String rowId, bool isExpanded)` that gets called whenever a user expands or collapses a row in the tree.

## 0.6.0

* **FEATURE**: Add support for a scrollController

## 0.5.0

* **FEATURE**: Add support for dynamic heights
* **FEATURE**: Add support for header actions
* **FEATURE**: Add support for enhanced row actions: allow configuring secondary click or long press on a row 

## 0.4.0

* **FEATURE**: Added `footerBuilder` for completely custom footer implementations

## 0.3.2

* **CHORE**: Remove unused file, more permissive column size
* **IMPROVEMENT**: Switch to material icons for better dependency management

## 0.3.1

* **FIX**: Fix screenshot

## 0.3.0

* **FEATURE**: Add the ability to disable the footer, and customize the footer options further
* **CHORE**: Add screenshot

## 0.2.0

* **FEATURE**: Add the ability to save views and restore them 
* **FEATURE**: Add the ability to adjust the sequence of footer items

## 0.1.0

* **FEATURE**: Add support for dark mode

## 0.0.1

* **🎉**: Initial release. Hopefully this is the start of something good