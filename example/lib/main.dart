import 'package:flutter/material.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Data Grid Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unified Data Grid Demo')),
      body: UnifiedDataGrid(
        onRowTap: (rowData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on row ID: ${rowData['id']}')),
          );
        },
        mode: DataGridMode.client,
        rowHoverColor: Theme.of(context).primaryColor.withValues(alpha:0.1),
        clientData: const [
          {
            'id': '1',
            'name': 'John Doe',
            'age': 30,
            'parent': null,
            'status': 'active',
          },
          {
            'id': '2',
            'name': 'Jane Doe',
            'age': 28,
            'parent': '1',
            'status': 'inactive',
          },
          {
            'id': '3',
            'name': 'Peter Pan',
            'age': 12,
            'parent': null,
            'status': 'pending',
          },
          {
            'id': '4',
            'name': 'Wendy Darling',
            'age': 10,
            'parent': '3',
            'status': 'active',
          },
        ],
        columnDefs: [
          DataColumnDef.actions(
            id: 'actions',
            width: 32,
            showOnRowHover: true,
            itemsBuilder: (context, rowData) => [
              ContextMenuItem(
                caption: 'Edit',
                childContent: const Text('Edit'),
                onTap: () {},
              ),
              ContextMenuItem(
                caption: 'Delete',
                childContent: const Text('Delete'),
                onTap: () {},
              ),
            ],
          ),
          DataColumnDef(
            id: 'name',
            caption: 'Name',
            flex: 1,
            minWidth: 150,
            isNameColumn: true,
            filterType: FilterType.string,
          ),
          DataColumnDef(
            id: 'age',
            caption: 'Age',
            width: 150,
            minWidth: 150,
            filterType: FilterType.numeric,
          ),
          DataColumnDef(
            id: 'status',
            caption: 'Status',
            width: 150,
            minWidth: 150,
            cellBuilder: (context, rowData) {
              final status = rowData['status'];
              Color color;
              switch (status) {
                case 'active':
                  color = Colors.green;
                  break;
                case 'inactive':
                  color = Colors.grey;
                  break;
                case 'pending':
                  color = Colors.orange;
                  break;
                default:
                  color = Colors.transparent;
              }
              return AbsorbPointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3.0,
                    horizontal: 4.0,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      vertical: 2.0,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: getContrastingTextColor(color),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        toMap: (item) => item,
        rowIdKey: 'id',
        isTree: true,
        parentIdKey: 'parent',
      ),
    );
  }
}
