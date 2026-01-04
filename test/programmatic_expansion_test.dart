import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';

// A simple data model for testing purposes.
class TestNode {
  final String id;
  final String? parentId;
  final String name;

  TestNode({required this.id, this.parentId, required this.name});
}

void main() {
  final List<TestNode> testData = [
    TestNode(id: '1', name: 'Root 1'),
    TestNode(id: '1.1', parentId: '1', name: 'Child 1.1'),
    TestNode(id: '2', name: 'Root 2'),
    TestNode(id: '2.1', parentId: '2', name: 'Child 2.1'),
  ];

  testWidgets('Programmatic expansion works correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GlobalKey<UnifiedDataGridState<TestNode>> gridKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedDataGrid<TestNode>(
            key: gridKey,
            mode: DataGridMode.client,
            clientData: testData,
            isTree: true,
            parentIdKey: 'parentId',
            toMap: (node) => {
              'id': node.id,
              'parentId': node.parentId,
              'name': node.name,
            },
            rowIdKey: 'id',
            columnDefs: [
              DataColumnDef(
                id: 'name',
                caption: 'Name',
                isNameColumn: true,
                minWidth: 100,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially, children should not be visible (collapsed by default)
    expect(find.text('Child 1.1'), findsNothing);
    expect(find.text('Child 2.1'), findsNothing);

    // Expand Root 1 programmatically
    gridKey.currentState?.expandRow('1');
    await tester.pumpAndSettle();

    // Child 1.1 should now be visible
    expect(find.text('Child 1.1'), findsOneWidget);
    expect(find.text('Child 2.1'), findsNothing);

    // Expand Root 2 programmatically using setRowExpansion
    gridKey.currentState?.setRowExpansion('2', true);
    await tester.pumpAndSettle();

    // Both children should be visible
    expect(find.text('Child 1.1'), findsOneWidget);
    expect(find.text('Child 2.1'), findsOneWidget);

    // Collapse Root 1 programmatically
    gridKey.currentState?.collapseRow('1');
    await tester.pumpAndSettle();

    // Child 1.1 should be hidden again
    expect(find.text('Child 1.1'), findsNothing);
    expect(find.text('Child 2.1'), findsOneWidget);
  });
}
