import 'package:flutter/material.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart'
    show ContextMenuItem;
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

  // Settings state
  bool _isDocked = false;

  // Grid Type state
  int _currentGridTypeIndex = 0; // 0: Unified, 1: Client, 2: Server, 3: Custom

  // Grid configuration state
  int _currentExampleIndex = 0; // 0: Tree Grid, 1: Flat List
  double _headerHeight = 38.0;
  double _dataRowHeight = 32.0;
  double _filterRowHeight = 32.0;
  bool _allowFiltering = true;
  bool _allowColumnResize = true;
  bool _showCheckboxColumn = false;
  bool _showFooter = true;
  bool _useAvailableWidthDistribution = false;
  bool _showFilterCellBorder = true;
  double _scale = 1.0;

  final List<Map<String, dynamic>> _customTreeData = [
    {
      'id': '1',
      'name': 'John Doe',
      'age': 30,
      'parent': null,
      'status': 'active',
      '__level': 0,
      '__isLeaf': false,
      '__isExpanded': true,
      '__isVisible': true,
    },
    {
      'id': '2',
      'name': 'Jane Doe',
      'age': 28,
      'parent': '1',
      'status': 'inactive',
      '__level': 1,
      '__isLeaf': true,
      '__isExpanded': false,
      '__isVisible': true,
    },
    {
      'id': '3',
      'name': 'Peter Pan',
      'age': 12,
      'parent': null,
      'status': 'pending',
      '__level': 0,
      '__isLeaf': false,
      '__isExpanded': true,
      '__isVisible': true,
    },
    {
      'id': '4',
      'name': 'Wendy Darling',
      'age': 10,
      'parent': '3',
      'status': 'active',
      '__level': 1,
      '__isLeaf': true,
      '__isExpanded': false,
      '__isVisible': true,
    },
  ];

  void _onToggleCustomTreeExpansion(String id) {
    setState(() {
      final node = _customTreeData.firstWhere((e) => e['id'] == id);
      final isExpanded = !(node['__isExpanded'] as bool);
      node['__isExpanded'] = isExpanded;

      void toggleChildrenVisibility(String parentId, bool parentVisible) {
        for (var child in _customTreeData.where(
          (e) => e['parent'] == parentId,
        )) {
          child['__isVisible'] = parentVisible;
          if (!(child['__isLeaf'] as bool)) {
            toggleChildrenVisibility(
              child['id'] as String,
              parentVisible && (child['__isExpanded'] as bool),
            );
          }
        }
      }

      toggleChildrenVisibility(id, isExpanded);
    });
  }

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

      if (!mounted) return;

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

    if (!mounted) return;

    setState(() {
      _savedViewState = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Saved view cleared. Restart the app to see the default view.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Theme.of(context).cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grid Settings',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                IconButton(
                  icon: Icon(
                    _isDocked ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDocked = !_isDocked;
                    });
                    if (!_isDocked) {
                      Navigator.of(context).pop(); // Close drawer if undocking
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Grid Type'),
            trailing: DropdownButton<int>(
              value: _currentGridTypeIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('UnifiedDataGrid')),
                DropdownMenuItem(value: 1, child: Text('ClientSideDataGrid')),
                DropdownMenuItem(value: 2, child: Text('ServerSideDataGrid')),
                DropdownMenuItem(value: 3, child: Text('CustomDataTable')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _currentGridTypeIndex = val);
              },
            ),
          ),
          ListTile(
            title: const Text('Dataset'),
            trailing: DropdownButton<int>(
              value: _currentExampleIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tree Grid')),
                DropdownMenuItem(value: 1, child: Text('Flat List')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _currentExampleIndex = val);
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Allow Filtering'),
            value: _allowFiltering,
            onChanged: (val) => setState(() => _allowFiltering = val),
          ),
          SwitchListTile(
            title: const Text('Allow Column Resize'),
            value: _allowColumnResize,
            onChanged: (val) => setState(() => _allowColumnResize = val),
          ),
          SwitchListTile(
            title: const Text('Show Checkboxes'),
            value: _showCheckboxColumn,
            onChanged: (val) => setState(() => _showCheckboxColumn = val),
          ),
          SwitchListTile(
            title: const Text('Show Footer'),
            value: _showFooter,
            onChanged: (val) => setState(() => _showFooter = val),
          ),
          SwitchListTile(
            title: const Text('Use Available Width Dist.'),
            value: _useAvailableWidthDistribution,
            onChanged: (val) =>
                setState(() => _useAvailableWidthDistribution = val),
          ),
          SwitchListTile(
            title: const Text('Show Filter Border'),
            value: _showFilterCellBorder,
            onChanged: (val) => setState(() => _showFilterCellBorder = val),
          ),
          const Divider(),
          _buildSlider(
            'Header Height',
            _headerHeight,
            20,
            100,
            (val) => setState(() => _headerHeight = val),
          ),
          _buildSlider(
            'Data Row Height',
            _dataRowHeight,
            20,
            100,
            (val) => setState(() => _dataRowHeight = val),
          ),
          _buildSlider(
            'Filter Row Height',
            _filterRowHeight,
            20,
            100,
            (val) => setState(() => _filterRowHeight = val),
          ),
          _buildSlider(
            'Scale',
            _scale,
            0.5,
            2.0,
            (val) => setState(() => _scale = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(1)}'),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlPanel = _buildControlPanel();

    return Scaffold(
      appBar: AppBar(
        title: Text(() {
          switch (_currentGridTypeIndex) {
            case 1:
              return 'Client-Side Grid Demo';
            case 2:
              return 'Server-Side Grid Demo';
            case 3:
              return 'Custom Data Table Demo';
            case 0:
            default:
              return 'Unified Data Grid Demo';
          }
        }()),
        leading: _isDocked
            ? IconButton(
                icon: const Icon(Icons.menu_open),
                onPressed: () => setState(() => _isDocked = false),
              )
            : null,
      ),
      drawer: _isDocked ? null : Drawer(child: controlPanel),
      body: Row(
        children: [
          if (_isDocked) SizedBox(width: 320, child: controlPanel),
          if (_isDocked) const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _isLoadingView
                ? const Center(child: CircularProgressIndicator())
                : _buildDataGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    const flatData = [
      {'id': '1', 'name': 'Item A', 'age': 45, 'status': 'active'},
      {'id': '2', 'name': 'Item B', 'age': 32, 'status': 'inactive'},
      {'id': '3', 'name': 'Item C', 'age': 28, 'status': 'pending'},
    ];

    final currentData = _currentExampleIndex == 0 ? _customTreeData : flatData;

    final columns = [
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
                  style: TextStyle(color: getContrastingTextColor(color)),
                ),
              ),
            ),
          );
        },
      ),
    ];

    final footerWidgets = [
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
    ];

    void handleRowTap(Map<String, dynamic> rowData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped on row ID: ${rowData['id']}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    switch (_currentGridTypeIndex) {
      case 1:
        return ClientSideDataGrid(
          key: _gridKey,
          headerHeight: _headerHeight,
          dataRowHeight: _dataRowHeight,
          filterRowHeight: _filterRowHeight,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          showCheckboxColumn: _showCheckboxColumn,
          showFooter: _showFooter,
          useAvailableWidthDistribution: _useAvailableWidthDistribution,
          showFilterCellBorder: _showFilterCellBorder,
          scale: _scale,
          onRowTap: handleRowTap,
          data: currentData,
          columnDefs: columns,
          toMap: (item) => item,
          footerLeadingWidgets: footerWidgets,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: _currentExampleIndex == 0 ? 'parent' : null,
        );
      case 2:
        return ServerSideDataGrid(
          key: _gridKey,
          headerHeight: _headerHeight,
          dataRowHeight: _dataRowHeight,
          filterRowHeight: _filterRowHeight,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          showCheckboxColumn: _showCheckboxColumn,
          useAvailableWidthDistribution: _useAvailableWidthDistribution,
          showFilterCellBorder: _showFilterCellBorder,
          scale: _scale,
          onRowTap: handleRowTap,
          fetchData: (options) async {
            // Mock network delay
            await Future.delayed(const Duration(milliseconds: 500));
            return PaginatedDataResponse(
              content: currentData,
              totalElements: currentData.length,
              totalPages: 1,
              first: true,
              last: true,
              size: 10,
              number: 0,
              numberOfElements: currentData.length,
              empty: currentData.isEmpty,
            );
          },
          columnDefs: columns,
          toMap: (item) => item,
          footerLeadingWidgets: footerWidgets,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: _currentExampleIndex == 0 ? 'parent' : null,
        );
      case 3:
        return CustomDataTable(
          rows: currentData,
          columns: columns,
          headerHeight: _headerHeight,
          dataRowHeight: _dataRowHeight,
          filterRowHeight: _filterRowHeight,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          showCheckboxColumn: _showCheckboxColumn,
          useAvailableWidthDistribution: _useAvailableWidthDistribution,
          scale: _scale,
          onRowTap: handleRowTap,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          onToggleExpansion: _onToggleCustomTreeExpansion,
          indentationLevelKey:
              '__level', // Note: CustomDataTable expects pre-computed tree metadata
          hasChildrenKey: '__isLeaf',
          isExpandedKey: '__isExpanded',
          isEffectivelyVisibleKey: '__isVisible',
          selectedRowIds: const {},
          onSelectionChanged: (selection) {},
        );
      case 0:
      default:
        return UnifiedDataGrid(
          key: _gridKey,
          headerHeight: _headerHeight,
          dataRowHeight: _dataRowHeight,
          filterRowHeight: _filterRowHeight,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          showCheckboxColumn: _showCheckboxColumn,
          showFooter: _showFooter,
          useAvailableWidthDistribution: _useAvailableWidthDistribution,
          showFilterCellBorder: _showFilterCellBorder,
          scale: _scale,
          initialViewState: _savedViewState,
          onRowTap: handleRowTap,
          mode: DataGridMode.client,
          clientData: currentData,
          columnDefs: columns,
          toMap: (item) => item,
          footerLeadingWidgets: footerWidgets,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: _currentExampleIndex == 0 ? 'parent' : null,
        );
    }
  }
}
