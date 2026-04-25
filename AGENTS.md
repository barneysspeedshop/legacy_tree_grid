# AI Agent Instructions for Legacy Tree Grid

This directory contains the `legacy_tree_grid` package, a high-performance custom table grid used by the Gantt Chart. It supports both flat lists and deep hierarchical data structures.

## Fragile Code Warnings

### 1. Row Expansion Reactivity (`didUpdateWidget`)
> [!WARNING]
> The `UnifiedDataGrid` relies heavily on the `didUpdateWidget` lifecycle method to synchronize incoming changes to expanded grid rows, reconciling them with remote collaborators dynamically via `initialExpandedRowIds`.
> 
> In previous refactors, developers mistakenly removed the logic that synchronized `_expandedRowIds`. This prevents remote clients from reacting to folder open/closures in real-time. Do not modify or remove this synchronization block without thorough state testing.

### 2. Flattened Tree Traversal Math
When `isTree: true` is enabled, the Custom Data Table does **not** rely on recursive UI widgets. To maintain 60FPS UI scrolling, `_processData` inside `UnifiedDataGrid` recursively traverses hierarchical data, flattening it into a 1D array while dynamically injecting `_indentationLevel` and `_isEffectivelyVisible` keys. 
If inserting or deleting nodes programmatically, you must re-run this flattening function. Do not attempt to alter UI widgets to handle tree offsets.

### 3. Server Pagination Zero-Indexing
When interacting with `ServerSideDataGrid`, API pagination uses a standard 1-based `page` property inside `DataGridFetchOptions`. However, the mathematical helper method `toQueryParameters()` translates this to a 0-based `start` index for the backend API. Be extremely careful when doing math on `numberOfElements` or `totalElements` during pagination fetches to avoid off-by-one out-of-bounds requests.

### 4. Slivers and ScaleNotifier
The grid header (`_DataTableHeader`) and filter rows are statically pinned headers built with custom `SliverPersistentHeaderDelegate` implementations. Their component heights are strictly bound to a provider-based `ScaleNotifier`. Removing the reactive scale listener or hard-coding sliver heights will permanently break the parent Gantt Chart's dynamic UI zooming capability.
