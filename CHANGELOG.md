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