import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';

// Helper to extract widths from the grid header
Future<List<double>> getColumnWidths(WidgetTester tester) async {
  // Find the SliverPersistentHeader which contains the header area
  final headerFinder = find.byType(SliverPersistentHeader).first;
  final widths = <double>[];

  // 1. Check the outer Row for any columns (like drag handle)
  final outerRowFinder = find
      .descendant(of: headerFinder, matching: find.byType(Row))
      .first;
  if (outerRowFinder.evaluate().isNotEmpty) {
    final outerRow = tester.widget<Row>(outerRowFinder);
    for (final child in outerRow.children) {
      if (child is SizedBox && child.width != null) {
        // Skip the checkbox column (width 40.0)
        if (child.width != 40.0) {
          widths.add(child.width!);
        }
      }
    }
  }

  // 2. Check the _DataTableHeader widget (inner header) which contains most columns
  final innerHeaderFinder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_DataTableHeader',
  );
  if (innerHeaderFinder.evaluate().isNotEmpty) {
    final innerRowFinder = find
        .descendant(of: innerHeaderFinder, matching: find.byType(Row))
        .first;
    final innerRow = tester.widget<Row>(innerRowFinder);
    for (final child in innerRow.children) {
      if (child is SizedBox && child.width != null) {
        widths.add(child.width!);
      }
    }
  }

  return widths;
}

void main() {
  group('DataColumnDef Tests', () {
    test('dragHandle factory creates correct column definition', () {
      final col = DataColumnDef.dragHandle();
      expect(col.id, 'drag_handle');
      expect(col.width, 30.0);
      expect(col.minWidth, 30.0);
      expect(col.maxWidth, 30.0);
      expect(col.resizable, false);
      expect(col.sortable, false);
      expect(col.isDragHandle, true);
      expect(col.alignment, TextAlign.center);
    });
  });

  group('CustomDataTable Width Calculation Tests', () {
    // Helper to pump the grid with specific columns and container width
    Future<void> pumpGrid(
      WidgetTester tester,
      List<DataColumnDef> columns,
      double containerWidth,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: containerWidth,
                height: 400,
                child: ClientSideDataGrid<Map<String, dynamic>>(
                  data: [
                    {'id': '1'},
                  ],
                  toMap: (d) => d,
                  rowIdKey: 'id',
                  columnDefs: columns,
                  allowColumnResize:
                      false, // Ensure consistent divider widths (1.0 vs 10.0)
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Basic Flex: 2 columns split evenly', (
      WidgetTester tester,
    ) async {
      final columns = [
        DataColumnDef(id: 'col1', caption: 'Col 1', minWidth: 50, flex: 1),
        DataColumnDef(id: 'col2', caption: 'Col 2', minWidth: 50, flex: 1),
      ];

      // 800 width. 1 divider of 1.0px (default not draggable) or 10.0 if draggable.
      // Def resizable=true. allowColumnResize defaults to false in ClientSideDataGrid wrapper?
      // Check ClientSideDataGrid default: allowColumnResize is false by default unless passed.
      // ClientSideDataGrid passes `allowColumnResize: allowColumnResize` which defaults to true in class def?
      // Checking file... ClientSideDataGrid `this.allowColumnResize = false`.
      // So divider is 0 or 1? `widget.columns.length > 1 ? ... : 0`.
      // In _initializeColumnWidths: `isDraggable ? 10.0 : 1.0`.
      // Since allowColumnResize is false, it's 1.0.

      // Available = 800 - 1 = 799.
      // Col 1 = 399.5
      // Col 2 = 399.5

      await pumpGrid(tester, columns, 800);

      // 800 width. 2 dividers of 1.0px (1 internal + 1 trailing).
      // Available = 800 - 2 = 798.
      // Col 1 = 399.0
      // Col 2 = 399.0

      await pumpGrid(tester, columns, 800);

      final widths = await getColumnWidths(tester);
      expect(widths.length, 2);
      expect(widths[0], closeTo(399.0, 0.1));
      expect(widths[1], closeTo(399.0, 0.1));
    });

    testWidgets('Max Width Constraint: One fits, one expands', (
      WidgetTester tester,
    ) async {
      final columns = [
        DataColumnDef(
          id: 'col1',
          caption: 'Col 1',
          minWidth: 50,
          maxWidth: 100,
          flex: 1,
        ),
        DataColumnDef(id: 'col2', caption: 'Col 2', minWidth: 50, flex: 1),
      ];

      // Available 798.
      // Initial share 399.0 each.
      // Col 1 constrained max 100.
      // Col 1 = 100.
      // Remainder = 698.
      // Col 2 = 698.

      await pumpGrid(tester, columns, 800);

      final widths = await getColumnWidths(tester);
      expect(widths[0], closeTo(100.0, 0.1));
      expect(widths[1], closeTo(698.0, 0.1));
    });

    testWidgets('Min Width Constraint: One forced minimum, other shrinks', (
      WidgetTester tester,
    ) async {
      final columns = [
        DataColumnDef(id: 'col1', caption: 'Col 1', minWidth: 600, flex: 1),
        DataColumnDef(id: 'col2', caption: 'Col 2', minWidth: 50, flex: 1),
      ];

      // Available 798.
      // Initial share 399.0 each.
      // Col 1 constrained min 600.
      // Col 1 = 600.
      // Remainder = 198.
      // Col 2 = 198.

      await pumpGrid(tester, columns, 800);

      final widths = await getColumnWidths(tester);
      expect(widths[0], closeTo(600.0, 0.1));
      expect(widths[1], closeTo(198.0, 0.1));
    });

    testWidgets('Fixed Width + Flex', (WidgetTester tester) async {
      final columns = [
        DataColumnDef(id: 'col1', caption: 'Col 1', width: 100, minWidth: 50),
        DataColumnDef(id: 'col2', caption: 'Col 2', minWidth: 50, flex: 1),
      ];

      // Available 798.
      // Col 1 fixed 100.
      // Remainder 698.
      // Col 2 takes all remainder = 698.

      await pumpGrid(tester, columns, 800);

      final widths = await getColumnWidths(tester);
      expect(widths[0], closeTo(100.0, 0.1));
      expect(widths[1], closeTo(698.0, 0.1));
    });

    testWidgets('Drag Handle Column Width', (WidgetTester tester) async {
      final columns = [
        DataColumnDef.dragHandle(),
        DataColumnDef(id: 'col2', caption: 'Col 2', flex: 1, minWidth: 50),
      ];

      // Available 798.
      // Drag handle fixed 30.
      // Remainder 768.
      // Col 2 = 768.

      await pumpGrid(tester, columns, 800);

      final widths = await getColumnWidths(tester);
      expect(widths[0], 30.0);
      expect(widths[1], closeTo(768.0, 0.1));
    });
  });
}
