import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';

void main() {
  testWidgets('TreeGrid filtering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Initially, all root nodes should be visible.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Peter Pan'), findsOneWidget);
    // Children are not visible until expanded
    expect(find.text('Jane Doe'), findsNothing);
    expect(find.text('Wendy Darling'), findsNothing);

    // --- Test Name Filter ---
    // Find the filter text field for the 'Name' column.
    // We find it by looking for a TextField that is a descendant of the filter row.
    final nameFilterField = find.descendant(
      of: find.byType(UnifiedDataGrid<dynamic>),
      matching: find.widgetWithText(TextField, 'Filter...'),
    ).first;

    expect(nameFilterField, findsOneWidget);

    // Enter 'John' into the name filter.
    await tester.enterText(nameFilterField, 'John');
    await tester.pumpAndSettle();

    // Now, only 'John Doe' should be visible as a root. 'Peter Pan' should be gone.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Peter Pan'), findsNothing);

    // Expand John Doe to see if its child is present.
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();

    // 'Jane Doe' should now be visible.
    expect(find.text('Jane Doe'), findsOneWidget);

    // Clear the name filter.
    await tester.enterText(nameFilterField, '');
    await tester.pumpAndSettle();

    // Both root nodes should be back.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Peter Pan'), findsOneWidget);

    // --- Test Numeric Age Filter ---
    // Find the filter text field for the 'Age' column.
    final ageFilterField = find.descendant(
      of: find.byType(UnifiedDataGrid<dynamic>),
      matching: find.widgetWithText(TextField, 'Filter...'),
    ).last;

    expect(ageFilterField, findsOneWidget);

    // Enter '> 25' into the age filter.
    await tester.enterText(ageFilterField, '> 25');
    await tester.pumpAndSettle();

    // Only 'John Doe' (age 30) and his descendants should be in the tree.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Peter Pan'), findsNothing);

    // 'Jane Doe' (age 28) is a child of John, so she should be visible after expansion.
    // The parent row is already expanded from the previous test.
    expect(find.text('Jane Doe'), findsOneWidget);

    // Enter '< 15' into the age filter.
    await tester.enterText(ageFilterField, '< 15');
    await tester.pumpAndSettle();

    // Now only 'Peter Pan' (12) and his descendants should be in the tree.
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Peter Pan'), findsOneWidget);

    // Expand Peter Pan to see his child.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // 'Wendy Darling' (10) should be visible.
    expect(find.text('Wendy Darling'), findsOneWidget);
  });
}