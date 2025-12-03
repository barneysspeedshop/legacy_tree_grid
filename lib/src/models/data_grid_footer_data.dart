import 'package:flutter/material.dart';

/// A data class that provides all the necessary information and callbacks
/// for building a custom data grid footer.
class DataGridFooterData {
  /// The current page number (1-based).
  final int currentPage;

  /// The number of items displayed per page.
  final int pageSize;

  /// The total number of records across all pages.
  final int totalRecords;

  /// The total number of pages.
  final int totalPages;

  /// A callback to trigger a data refresh.
  final VoidCallback onRefresh;

  /// A callback to navigate to the first page. Null if on the first page.
  final VoidCallback? onFirstPage;

  /// A callback to navigate to the previous page. Null if on the first page.
  final VoidCallback? onPreviousPage;

  /// A callback to navigate to the next page. Null if on the last page.
  final VoidCallback? onNextPage;

  /// A callback to navigate to the last page. Null if on the last page.
  final VoidCallback? onLastPage;

  /// A callback for the "Add" action. If null, the action is not available.
  final VoidCallback? onAdd;

  /// A callback for the "Delete" action. If null, the action is not available.
  final VoidCallback? onDelete;

  /// A callback to clear all active filters.
  final VoidCallback onClearFilters;

  /// The current state of the "Show Deleted" toggle. Null if not used.
  final bool? showDeleted;

  /// A callback for when the "Show Deleted" toggle changes. Null if not used.
  final ValueChanged<bool?>? onShowDeletedChanged;

  /// Whether the delete button should be in "undelete" mode.
  final bool isUndeleteMode;

  const DataGridFooterData({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.onRefresh,
    this.onFirstPage,
    this.onPreviousPage,
    this.onNextPage,
    this.onLastPage,
    this.onAdd,
    this.onDelete,
    required this.onClearFilters,
    this.showDeleted,
    this.onShowDeletedChanged,
    required this.isUndeleteMode,
  });
}