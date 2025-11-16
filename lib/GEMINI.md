# `legacy_tree_grid` Documentation

This document provides an overview of the functionality of the files in the `lib` directory of the `legacy_tree_grid` project.

---

## `client_side_data_grid.dart`

### Overview

This file defines the `ClientSideDataGrid<T>` widget, a reusable and stateful Flutter data grid designed for client-side data operations. It is a specialized wrapper around the `UnifiedDataGrid` widget, providing a familiar API for scenarios where data is managed on the client.

The widget handles fetching data once and then performs filtering, sorting, and pagination in memory.

### `ClientSideDataGrid<T>` Widget

A widget that displays a list of items of type `T` in a tabular format.

#### Key Features:

*   **Client-Side Data:** Manages a collection of data entirely on the client.
*   **Data Source:** Accepts data either from a `Future<List<T>>` (`fetchData`) or a direct `List<T>` (`data`). The widget ensures that only one is provided.
*   **Column Definitions:** Column appearance and behavior are defined by a `List<DataColumnDef>`.
*   **Row Mapping:** A function `toMap` is required to convert each data object `T` into a `Map<String, dynamic>` for display.
*   **Unique Row Identifier:** The `rowIdKey` specifies the key in the mapped data that uniquely identifies each row.
*   **Pagination:** Automatically handles pagination with a configurable `pageSize`.
*   **Sorting:** Supports initial sorting via `initialSortColumnId` and `initialSortAscending`. Users can sort columns by clicking on the headers.
*   **Filtering:** If `allowFiltering` is true, users can filter data on a per-column basis.
*   **Row Selection:** A checkbox column can be displayed for row selection by setting `showCheckboxColumn` to true.
*   **CRUD Operations:**
    *   `onAdd`: A callback to trigger an "add new item" action.
    *   `onDelete`: A callback that receives a `Set<String>` of selected row IDs for deletion.
    *   `onRowTap`: A callback triggered when a user taps on a row, providing the row's data.
*   **Deleted Item Filtering:** Includes a toggle to show or hide items marked as "deleted." This requires the `isDeleted` function to be provided.
*   **Column Resizing:** Column widths can be resized by the user if `allowColumnResize` is true.

### `ClientSideDataGridState<T>` State Class

The state for the `ClientSideDataGrid` widget.

#### Public Methods:

*   **`refresh()`**: An asynchronous method that allows external widgets to trigger a full refresh of the data. This is only effective when the grid is using the `fetchData` property. It works by calling the `refresh` method on the underlying `UnifiedDataGrid`.

---

## `color_utils.dart`

### Overview

This file provides a set of utility functions and extensions for working with `Color` objects in Flutter. It includes functions for parsing hex color strings, determining a readable contrasting text color, and darkening a color.

### Functions

#### `Color parseColorHex(String? hexString, Color defaultColor)`

Parses a hexadecimal color string and converts it into a Flutter `Color` object.

*   **Parameters:**
    *   `hexString`: The string to parse. It can be in 3-digit (`F0C`) or 6-digit (`FF00CC`) format, with or without a leading `#`.
    *   `defaultColor`: The color to return if the `hexString` is null, empty, or invalid.
*   **Returns:** A `Color` object. If parsing fails, it returns the `defaultColor`.

#### `Color getContrastingTextColor(Color backgroundColor)`

Calculates a suitable text color (either black or white) that will have a high contrast against the given `backgroundColor`.

*   **Parameters:**
    *   `backgroundColor`: The background color to check against.
*   **Returns:** `Colors.black` for light backgrounds and `Colors.white` for dark backgrounds to ensure text readability.

### Extensions

#### `extension ColorExtension on Color`

An extension on the `Color` class to add helpful methods.

##### `Color darken([double amount = .1])`

Creates a darker version of the color.

*   **Parameters:**
    *   `amount`: An optional `double` between 0.0 and 1.0 that specifies how much to darken the color. Defaults to `0.1` (10%).
*   **Returns:** A new `Color` object that is darker than the original.
---

## `custom_data_table.dart`

### Overview

This file contains `CustomDataTable`, a powerful and highly customizable Flutter widget for displaying tabular and hierarchical data. It is the core rendering engine for the data grid, packed with features for interaction, custom styling, and advanced layouts like tree grids.

The table is built using `CustomScrollView` and `Slivers` to ensure components like the header and an optional filter row remain pinned at the top while the content scrolls vertically.

### `CustomDataTable` Widget

A stateful widget that renders data from a `List<Map<String, dynamic>>` based on a `List<DataColumnDef>`.

#### Key Features & Properties

##### Data & Columns
*   **`columns`**: `List<DataColumnDef>` - Defines the structure, appearance, and behavior of each column.
*   **`rows`**: `List<Map<String, dynamic>>` - The data to be displayed. The widget expects a list of maps, where each map represents a row.

##### Layout & Sizing
*   **`rowHeight` / `headerHeight`**: Sets the height for data rows and the header row.
*   **`scale`**: A global scaling factor applied to heights and font sizes, useful for adjusting density.
*   **`allowColumnResize`**: A boolean to enable or disable user-resizable columns by dragging the header dividers.
*   **`initialColumnWidths` / `onColumnWidthsChanged`**: Allows for programmatic control and persistence of column widths.
*   **`useAvailableWidthDistribution`**: A layout mode that distributes any extra horizontal space to a designated column, useful for ensuring the table fills the screen width.
*   **`border`**: A `TableBorder` to customize the borders between cells.

##### Interaction
*   **`onRowTap`**: A callback function triggered when a row is tapped.
*   **`onSort`**: A callback triggered when a sortable column header is clicked.
*   **`sortColumnId` / `sortAscending`**: Properties to control the visual sort indicator on the columns.
*   **`rowHoverColor`**: An optional color for the row hover effect.

##### Row Selection
*   **`showCheckboxColumn`**: If true, displays a checkbox in each row for selection.
*   **`rowIdKey`**: The key within the row data map that uniquely identifies a row. Essential for selection and tree operations.
*   **`selectedRowIds` / `onSelectionChanged`**: A `Set<String>` and a callback to manage the selection state.

##### Tree Grid Functionality
*   **`isTree`**: When true, enables the tree grid mode.
*   **`onToggleExpansion`**: A callback to handle the expansion and collapse of parent nodes.
*   **`indentationLevelKey`**: A key in the row data that specifies the nesting level of a node.
*   **`hasChildrenKey` / `isExpandedKey`**: Keys in the row data that control the display of the expand/collapse toggle and its state.

##### Custom Rendering
*   **`headerRowBuilder` / `filterRowBuilder` / `rowBuilder`**: Powerful builder functions that delegate the rendering of the header, filter row, and data rows to the parent widget, allowing for complete customization.
*   **`allowFiltering`**: If true, a persistent `Sliver` is created below the header to house a filter row (which must be provided by `filterRowBuilder`).

##### Scrolling
*   **`scrollController`**: An optional `ScrollController` to manage the vertical scroll position externally.
*   The widget automatically wraps itself in a horizontal `SingleChildScrollView` if the total column width exceeds the available space.

#### Static Methods

*   **`buildStatusCell(...)`**: A helper method to create a standardized cell with a colored background and a contrasting text color. It's designed to be used within a `cellBuilder` in a `DataColumnDef`.

### Internal Helper Widgets

*   **`_DataTableHeader`**: A private widget that renders the header row, including titles, sort indicators, the "select all" checkbox, and draggable dividers for resizing.
*   **`_DataTableRow`**: A private widget that renders a single data row. It handles hover states, selection, tree-grid indentation and icons, and calls custom cell builders.
*   **`_SliverHeaderDelegate`**: A custom `SliverPersistentHeaderDelegate` used to create the pinned header and filter rows.

### Top-Level Utility Functions

*   **`_extractValue(...)`**: A utility to safely access values from nested maps using a dot-separated path string (e.g., `'user.name'`).
*   **`_textAlignTo...`**: Functions to convert `TextAlign` enums into corresponding `Alignment` or `MainAxisAlignment` values for layout.
---

## `data_column_def.dart`

### Overview

This file defines the `DataColumnDef` class and the `FilterType` enum. The `DataColumnDef` class is a configuration object used by `CustomDataTable` to define the properties and behavior of each column in the grid.

### `FilterType` Enum

An enumeration that specifies the type of filter to be applied to a column.
*   **Values**: `none`, `string`, `numeric`, `date`, `list`, `boolean`.

### `DataColumnDef` Class

A class that holds all the configuration for a single data grid column.

#### Key Properties

*   **`id`**: A unique string identifier for the column, which maps to a key in the row data. It supports dot notation for nested data (e.g., `'user.address.city'`).
*   **`caption`**: The text displayed in the column's header.
*   **`flex` / `width`**: Defines the column's width. A column must have either a `flex` (for proportional sizing) or a `width` (for a fixed size).
*   **`minWidth`**: The minimum width the column can be resized to.
*   **`resizable`**: A boolean indicating if the user can resize the column.
*   **`alignment`**: The `TextAlign` for the cell content. It intelligently defaults to `TextAlign.right` for numeric columns and `TextAlign.left` for others.
*   **`sortable`**: A boolean to enable or disable sorting on the column.
*   **`sortDescendingFirst`**: If true, the first click to sort the column will be in descending order.
*   **`cellBuilder`**: A powerful builder function `(context, rowData)` that allows for complete custom rendering of the cell's content.
*   **`formattedValue`**: A function that provides a custom string representation for a cell's value, used for display purposes only. The original value is still used for sorting and filtering.
*   **`filterType`**: The `FilterType` enum value that determines the kind of filter UI to use.
*   **`filterOptions`**: A `List<String>` of options for the filter dropdown, required when `filterType` is `FilterType.list`.
*   **`isNameColumn`**: A boolean that designates this column as the primary "name" column in a tree grid, which will render the indentation and expand/collapse icons.
*   **`showOnRowHover`**: If true, the cell's content will only be visible when the user hovers over the row. This is useful for action buttons.

#### `DataColumnDef.actions` Factory

A convenient factory for creating a standardized "Actions" column.

*   **Purpose**: Simplifies the creation of a column containing action buttons, typically displayed as a context menu.
*   **Defaults**: Creates a non-resizable, non-sortable column with a fixed width and an empty header. The content is set to `showOnRowHover: true`.
*   **`itemsBuilder`**: A required function `(context, rowData)` that returns a list of `ContextMenuItem`s to be displayed when the action button is clicked.
*   **Functionality**: The factory generates a `cellBuilder` that renders an ellipsis icon button. On press, it uses the `legacy_context_menu` package to show a popup menu at the button's location.
---

## `data_grid_fetch_options.dart`

### Overview

This file defines `DataGridFetchOptions`, an immutable data class that encapsulates the parameters for a server-side data request. It serves as a bridge between the data grid's UI state (pagination, sorting, filtering) and the data fetching logic, particularly for the `ServerSideDataGrid`.

### `DataGridFetchOptions` Class

A class that holds all the necessary information for a single data fetch operation.

#### Properties

*   **`page`**: The 1-based page number to be fetched.
*   **`pageSize`**: The number of records to retrieve for the page.
*   **`sortBy`**: The ID of the column to sort by.
*   **`sortAscending`**: A boolean indicating the sort direction (`true` for ascending, `false` for descending).
*   **`filters`**: A `Map<String, String>` containing the active filters, where the key is the column ID and the value is the filter criterion.

#### Methods

*   **`copyWith(...)`**: A standard method to create a new instance with updated values, promoting immutability.
*   **`toQueryParameters(...)`**: A utility method that converts the `DataGridFetchOptions` into a `Map<String, dynamic>` suitable for use as query parameters in an API call.
    *   It translates the 1-based `page` into a 0-based `start` index.
    *   It formats the `sortBy` and `sortAscending` properties into a single `sort` string (e.g., `"name,ASC"`).
    *   It transforms the `filters` map into a JSON-encoded string, which is a common pattern for passing complex filter objects to a backend. It also supports merging in a `defaultFilter`.
---

## `data_grid_footer.dart`

### Overview

This file defines `DataGridFooter`, a responsive and customizable footer widget for the data grid. Its primary feature is its ability to adapt to different screen sizes by collapsing action buttons into an overflow menu when space is limited. It also displays pagination controls and data record counts.

### `DataGridFooter` Widget

A stateful widget that provides a feature-rich footer.

#### Key Features & Properties

*   **Responsive Layout**: The footer uses a `LayoutBuilder` to measure available width. It displays as many action icons as possible and automatically moves the rest into a vertical ellipsis (`...`) overflow menu.
*   **Pagination Display**:
    *   It displays the current page and total pages (e.g., "Page 5 of 10").
    *   It shows the range of visible records (e.g., "Displaying records 101 - 125 of 500").
    *   Pagination controls are automatically hidden if `totalPages` is 1 or less.
*   **Pagination Callbacks**:
    *   `onFirstPage`, `onPreviousPage`, `onNextPage`, `onLastPage`: Callbacks for pagination buttons. Buttons are automatically disabled when not applicable (e.g., "Next Page" on the last page).
*   **Action Buttons**:
    *   `onRefresh`, `onAdd`, `onDelete`, `onClearFilters`: Providing a callback for any of these will cause the corresponding icon button to appear in the footer (or in the overflow menu).
*   **"Show Deleted" Toggle**:
    *   `showDeleted` and `onShowDeletedChanged` properties will add a "Show Deleted Only" checkbox to the footer.
    *   `isUndeleteMode`: A boolean that, when true, changes the delete icon and tooltip to "Undelete", useful for grids that support soft-deletes.
*   **Custom Widget Injection**:
    *   `leadingWidgets`: A `List<WidgetBuilder>` that allows you to insert custom widgets (like filter dropdowns or buttons) into the footer. The footer manages the layout space for these widgets.
*   **Dynamic Scaling**:
    *   The footer listens to a `ScaleNotifier` from `provider` to dynamically scale its height, icons, and font sizes in sync with the main data grid.

### Internal Helper Widgets

*   **`_LeadingWidgetsWrapper`**: A private wrapper that ensures custom `leadingWidgets` are built with the correct `BuildContext`. This is crucial for any injected widgets that use overlays (like `DropdownButton`) to position themselves correctly on the screen.
---

## `legacy_tree_grid.dart`

### Overview

This file serves as the main entry point for the `legacy_tree_grid` library.

### Functionality

Its sole purpose is to export the contents of `unified_data_grid.dart`. This is a common Dart convention that allows users of the package to import a single file (`package:legacy_tree_grid/legacy_tree_grid.dart`) to get access to all the primary, public-facing widgets and classes of the library, such as `UnifiedDataGrid`.

This simplifies the import statements for consumers of the package and provides a single place to manage the library's public API.

---

## `paginated_data_response.dart`

### Overview

This file defines the `PaginatedDataResponse<T>` class, a generic data structure used to model a paginated response from an API. Its structure is intentionally aligned with common backend pagination formats, such as those produced by Spring Data JPA, making integration with such backends seamless.

### `PaginatedDataResponse<T>` Class

A class that holds a "page" of data along with metadata about the entire dataset.

#### Properties

*   **`content`**: `List<T>` - The list of data items for the current page.
*   **`totalElements`**: The total number of records available across all pages on the server.
*   **`totalPages`**: The total number of pages available.
*   **`last` / `first`**: Booleans indicating if the current page is the last or first page, respectively. Used to enable/disable pagination controls in the footer.
*   **`size`**: The maximum number of records per page.
*   **`number`**: The current page number, typically 0-indexed from the server.
*   **`numberOfElements`**: The actual number of records in the `content` list for the current page.
*   **`empty`**: A boolean indicating if the current page contains any records.

#### Factory Constructors

*   **`PaginatedDataResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT)`**: A factory for deserializing a JSON map from an API response into a `PaginatedDataResponse` object.
    *   It takes a `fromJsonT` function as an argument, which is responsible for converting the individual JSON objects in the `content` list into the strongly-typed data model `T`.
*   **`PaginatedDataResponse.empty({required int pageSize, required int page})`**: A factory for creating a completely empty response.
    *   This is a crucial utility for initializing the data grid before the first fetch or for gracefully handling API errors, preventing the UI from crashing when data is not available.

---

## `parent_elements_footer.dart`

### Overview

This file provides the `ParentElementsFooter`, a simple, specialized footer widget designed exclusively for use with the data grid when it is in tree mode (`isTree: true`).

### `ParentElementsFooter` Widget

A stateless widget that adds a specific toggle option for hierarchical data.

#### Functionality

*   It displays a single row containing a checkbox and a label: "Show Parent Elements Only".
*   This provides a user-friendly way to filter the tree view, collapsing all nodes to show only the root-level elements.

#### Properties

*   **`showParentElementsOnly`**: A `bool` that represents the current state of the checkbox.
*   **`onShowParentElementsOnlyChanged`**: A `ValueChanged<bool?>` callback that is triggered when the user clicks the checkbox or the text, allowing the parent widget to update the filter state.
---

## `scale_notifier.dart`

### Overview

This file contains `ScaleNotifier`, a state management utility for handling UI scaling (zooming) across the data grid. It uses Flutter's `ChangeNotifier` to broadcast scale changes to listening widgets.

### `ScaleNotifier` Class

A class that extends `ChangeNotifier` to manage a `double` value representing the UI scale factor.

#### Properties

*   **`scale`**: A getter that returns the current scale factor. The scale is clamped between a minimum (`0.5`) and maximum (`2.0`) value.

#### Public Methods

*   **`updateScale(double newScale)`**: Sets the scale to a specific value.
*   **`zoomIn()` / `zoomOut()`**: Increments or decrements the scale by a fixed step (`0.1`).
*   **`resetZoom()`**: Resets the scale to its default value of `1.0`.
*   Each method calls `notifyListeners()` after changing the scale, which triggers a rebuild in any listening widgets (like `DataGridFooter` and `CustomDataTable`).

### `Intent` Classes

*   **`ZoomInIntent`, `ZoomOutIntent`, `ResetZoomIntent`**: These are simple marker classes that extend `Intent`. They are used to associate keyboard shortcuts (via a `Shortcuts` widget) with the zoom actions in the `ScaleNotifier`, enabling accessibility and power-user features like `Ctrl +` and `Ctrl -` for zooming.

---

## `server_side_data_grid.dart`

### Overview

This file defines the `ServerSideDataGrid<T>` widget, a high-level, stateful wrapper around the `UnifiedDataGrid`. It is pre-configured for server-side data operations, simplifying the API for this common and complex use case.

### `ServerSideDataGrid<T>` Widget

A widget that displays paginated data fetched from a remote server.

#### Key Features & Properties

*   **Server-Side Focus**: Its primary purpose is to act as a client for a paginated API. It delegates all data operations (pagination, sorting, filtering) to the server.
*   **`fetchData`**: This is the most critical property. It's a callback of type `ServerFetchDataCallback<T>`, which is defined as `Future<PaginatedDataResponse<T>> Function(DataGridFetchOptions options)`.
    *   The grid calls this function whenever it needs data, passing an object with the current `page`, `pageSize`, `sortBy`, and `filters`.
*   **Simplified API**: It abstracts away the `mode` property of the `UnifiedDataGrid` and exposes only the properties relevant to server-side operations. Other properties like `columnDefs`, `toMap`, `rowIdKey`, `onAdd`, `onDelete`, etc., are passed directly to the underlying `UnifiedDataGrid`.

### `ServerSideDataGridState<T>` State Class

The state for the `ServerSideDataGrid` widget.

#### Public Methods

*   **`refresh()`**: An asynchronous method that allows external widgets to trigger a data refresh. It works by obtaining the state of the underlying `UnifiedDataGrid` via a `GlobalKey` and calling its `refresh` method. This provides a clean way to programmatically reload the grid's data from the server.

---

## `unified_data_grid.dart`

### Overview

This file contains `UnifiedDataGrid<T>`, the core engine of the entire `legacy_tree_grid` package. It is a versatile and powerful widget that contains all the logic for both client-side and server-side data management, as well as the tree grid functionality. The `ClientSideDataGrid` and `ServerSideDataGrid` widgets are simply convenient wrappers around this central component.

### `DataGridMode` Enum

*   An enum that defines the two primary operational modes of the grid:
    *   **`client`**: For managing a local list of data.
    *   **`server`**: For interacting with a remote, paginated API.

### `UnifiedDataGrid<T>` Widget

The primary stateful widget that orchestrates all data grid functionality.

#### Key Properties

*   **Mode and Data Sources**:
    *   `mode`: The `DataGridMode` that determines the grid's behavior.
    *   `clientData` / `clientFetch`: Data sources for client mode.
    *   `serverFetch`: The data fetching callback for server mode.
*   **Core Configuration**: `columnDefs`, `toMap`, `rowIdKey`, `pageSize`.
*   **Feature Toggles**: A rich set of booleans to enable/disable features like `showCheckboxColumn`, `allowFiltering`, `allowColumnResize`, and `showDeletedToggle`.
*   **Tree Grid Configuration**: `isTree`, `parentIdKey`, and `rootValue` are used to enable and configure the hierarchical display.

### `UnifiedDataGridState<T>` State Class

This is the "brain" of the data grid, containing the complex state and logic.

#### State Management

*   It holds all the state for the grid's UI, including `_isLoading`, `_currentPage`, `_sortColumnId`, `_sortAscending`, and `_selectedRowIds`.
*   It manages data sources: `_allData` for client mode and `_paginatedData` for server mode.
*   For the tree grid, it maintains the set of `_expandedRowIds` and the processed `_treeData` list.

#### Core Logic

*   **Data Pipeline**: `initState` and `didUpdateWidget` are the entry points to the data pipeline. They trigger the appropriate data fetching or processing logic based on the grid's `mode` and whether the data source has changed.
*   **Client-Side Operations**: When in `client` mode, it performs all operations on the `_allData` list in the following order:
    1.  Filters by the "Show Deleted" toggle.
    2.  Applies all active column filters (`_matchNumericFilter`, `_matchStringFilter`, etc.).
    3.  Sorts the resulting list based on `_sortColumnId` and `_sortAscending`.
    4.  Paginates the final list to get the items for the current page.
*   **Server-Side Operations**: When in `server` mode, it:
    1.  Constructs a `DataGridFetchOptions` object from the current UI state (page, sort, filters).
    2.  Calls the `widget.serverFetch` callback with these options.
    3.  Displays a loading indicator while awaiting the `Future<PaginatedDataResponse<T>>`.
    4.  Updates its state with the response from the server.
    5.  Includes a debounce timer (`_debounceTimer`) for text-based filters to avoid sending excessive API requests while the user is typing.
*   **Tree Processing**: The `_processData` method is responsible for converting a flat list of items into a hierarchical structure suitable for rendering. It recursively traverses the data, building a flattened list that `CustomDataTable` can render, while injecting properties like `_indentationLevel` and `_isEffectivelyVisible` based on the `_expandedRowIds` set.
*   **UI Composition**: The `build` method is responsible for assembling the final widget tree. It passes the correctly processed and paginated data (`displayRows` or `_treeData`) to the `CustomDataTable` and configures the `DataGridFooter` with the current pagination state and appropriate callbacks.