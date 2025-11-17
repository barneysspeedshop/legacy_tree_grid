import 'package:flutter/material.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart' show ContextMenuItem;
import 'package:legacy_tree_grid/legacy_tree_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _gridKey = GlobalKey<UnifiedDataGridState>();
  GridViewState? _savedViewState;
  bool _isLoadingView = true;

  @override
  void initState() {
    super.initState();
    _loadSavedView();
  }

  Future<void> _loadSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    final savedViewJson = prefs.getString('my_grid_view');
    if (savedViewJson != null) {
      setState(() {
        _savedViewState = GridViewState.fromJsonString(savedViewJson);
      });
    }
    setState(() {
      _isLoadingView = false;
    });
  }

  Future<void> _saveView() async {
    final currentState = _gridKey.currentState?.getCurrentViewState();
    if (currentState != null) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = currentState.toJsonString();
      await prefs.setString('my_grid_view', jsonString);

      setState(() {
        _savedViewState = currentState;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('View saved to local storage!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _restoreView() {
    if (_savedViewState != null) {
      _gridKey.currentState?.applyViewState(_savedViewState!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restored saved view!'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No view saved to restore.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _clearSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('my_grid_view');
    setState(() {
      _savedViewState = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved view cleared. Restart the app to see the default view.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unified Data Grid Demo')),
      body: _isLoadingView
          ? const Center(child: CircularProgressIndicator())
          : UnifiedDataGrid(
              key: _gridKey,
              initialViewState: _savedViewState,
              onRowTap: (rowData) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped on row ID: ${rowData['id']}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              mode: DataGridMode.client,
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
              // --- Example of adding custom widgets to the footer ---
              footerLeadingWidgets: [
                (context) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _saveView,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save View'),
                      ),
                    ),
                (context) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _restoreView,
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restore View'),
                      ),
                    ),
                (context) => TextButton(
                      onPressed: _clearSavedView,
                      child: const Text('Clear Saved View'),
                    ),
              ],
              rowIdKey: 'id',
              isTree: true,
              parentIdKey: 'parent',
            ),
    );
  }
}
