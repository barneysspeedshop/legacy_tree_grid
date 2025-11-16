import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';

// A simple data model for testing purposes.
class TestPerson {
  final String id;
  final String name;
  final int age;

  TestPerson({required this.id, required this.name, required this.age});
}

void main() {
  // A small dataset for the grid.
  final List<TestPerson> testData = [
    TestPerson(id: '1', name: 'John Doe', age: 30),
    TestPerson(id: '2', name: 'Jane Smith', age: 25),
  ];

  testWidgets('ClientSideDataGrid renders data and headers correctly',
      (WidgetTester tester) async {
    // Build the ClientSideDataGrid widget.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientSideDataGrid<TestPerson>(
            data: testData,
            toMap: (person) => {
              'id': person.id,
              'name': person.name,
              'age': person.age,
            },
            rowIdKey: 'id',
            columnDefs: [
              DataColumnDef(
                id: 'name',
                caption: 'Full Name',
                width: 200,
                minWidth: 200,
              ),
              DataColumnDef(
                id: 'age',
                caption: 'Age',
                width: 100,
                minWidth: 100,
              ),
            ],
          ),
        ),
      ),
    );

    // Wait for the grid to settle.
    await tester.pumpAndSettle();

    // Verify that the column headers are rendered.
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);

    // Verify that the data for the rows is rendered.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });
}
