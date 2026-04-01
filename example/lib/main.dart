import 'package:flutter/material.dart';
import 'package:legacy_tree_grid/legacy_tree_grid.dart';
import 'package:legacy_context_menu/legacy_context_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legacy Tree Grid Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
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
  final GlobalKey<UnifiedDataGridState> _gridKey = GlobalKey<UnifiedDataGridState>();
  
  List<Map<String, dynamic>> _data = [];
  Set<String> _selectedIds = {};
  final Set<String> _expandedIds = {};
  bool _isLoadingView = true;
  GridViewState? _savedViewState;
  
  // Settings
  bool _isDocked = true;
  int _currentGridTypeIndex = 0; // 0: Unified, 1: Client, 2: Server, 3: Custom
  int _currentExampleIndex = 0; // 0: Tree, 1: Flat
  bool _allowFiltering = true;
  bool _allowSorting = true;
  bool _allowColumnResize = true;
  bool _showCheckboxColumn = true;
  bool _showFooter = true;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadSavedView();
  }

  void _loadInitialData() {
    if (_currentExampleIndex == 0) {
      _data = [
        {'id': '1', 'name': 'Project Alpha', 'age': 45, 'status': 'active', 'parent': null},
        {'id': '2', 'name': 'Task 1.1', 'age': 25, 'status': 'active', 'parent': '1'},
        {'id': '3', 'name': 'Task 1.2', 'age': 30, 'status': 'pending', 'parent': '1'},
        {'id': '4', 'name': 'Subtask 1.2.1', 'age': 20, 'status': 'active', 'parent': '3'},
        {'id': '5', 'name': 'Project Beta', 'age': 50, 'status': 'inactive', 'parent': null},
        {'id': '6', 'name': 'Task 2.1', 'age': 35, 'status': 'active', 'parent': '5'},
      ];
    } else {
      _data = List.generate(100, (i) => {
        'id': (i + 1).toString(),
        'name': 'User ${i + 1}',
        'age': 20 + (i % 40),
        'status': i % 3 == 0 ? 'active' : (i % 3 == 1 ? 'pending' : 'inactive'),
        'parent': null,
      });
    }
  }

  Future<void> _loadSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('my_grid_view');
    setState(() {
      if (savedJson != null) {
        _savedViewState = GridViewState.fromJsonString(savedJson);
      }
      _isLoadingView = false;
    });
  }

  Future<void> _saveView() async {
    final currentState = _gridKey.currentState?.getCurrentViewState();
    if (currentState != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_grid_view', currentState.toJsonString());
      setState(() => _savedViewState = currentState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View saved!'), backgroundColor: Colors.green));
      }
    }
  }

  void _restoreView() {
    if (_savedViewState != null) {
      _gridKey.currentState?.applyViewState(_savedViewState!);
    }
  }

  Future<void> _clearSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('my_grid_view');
    setState(() => _savedViewState = null);
  }

  // Mock Server Fetch
  Future<PaginatedDataResponse<Map<String, dynamic>>> _mockServerFetch(DataGridFetchOptions options) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Tree Logic: Filter only visible nodes (roots + expanded children)
    // In a real server, you'd probably return a slice of the visible tree.
    List<Map<String, dynamic>> treeAwareData = [];
    void addChildren(dynamic parentId) {
      final children = _data.where((d) => d['parent'] == parentId).toList();
      for (var child in children) {
        treeAwareData.add(child);
        if (options.expandedRowIds.contains(child['id'].toString())) {
          addChildren(child['id']);
        }
      }
    }
    
    if (_currentExampleIndex == 0) { // If it's a tree example
      addChildren(null);
    } else {
      treeAwareData = List.from(_data);
    }

    // Calculate hasChildren for all returned items
    final mappedData = treeAwareData.map((item) {
      final itemId = item['id'].toString();
      final hasChildren = _data.any((d) => d['parent'] == itemId);
      return {...item, 'hasChildren': hasChildren};
    }).toList();

    var filteredData = mappedData;
    
    // Filtering
    options.filters.forEach((colId, value) {
      filteredData = filteredData.where((row) => 
        row[colId].toString().toLowerCase().contains(value.toLowerCase())
      ).toList();
    });
    
    // Sorting
    if (options.sortBy != null) {
      filteredData.sort((a, b) {
        int cmp = a[options.sortBy].toString().compareTo(b[options.sortBy].toString());
        return options.sortAscending ? cmp : -cmp;
      });
    }
    
    // Pagination
    final start = (options.page - 1) * options.pageSize;
    final end = (start + options.pageSize).clamp(0, filteredData.length);
    final pagedData = filteredData.sublist(start, end);
    
    return PaginatedDataResponse(
      content: pagedData,
      totalElements: filteredData.length,
      totalPages: (filteredData.length / options.pageSize).ceil(),
      last: options.page >= (filteredData.length / options.pageSize).ceil(),
      first: options.page == 1,
      size: options.pageSize,
      number: options.page - 1,
      numberOfElements: pagedData.length,
      empty: pagedData.isEmpty,
    );
  }

  // Tree Processing for CustomDataTable (manual flattening)
  List<Map<String, dynamic>> _buildFlatTree(List<Map<String, dynamic>> data, Set<String> expandedIds) {
    if (_currentExampleIndex != 0) return data;
    List<Map<String, dynamic>> result = [];
    
    void addChildren(String? parentId, int level, bool parentVisible, bool parentExpanded) {
      final children = data.where((d) => d['parent'] == parentId).toList();
      for (var child in children) {
        final id = child['id'].toString();
        final hasChildren = data.any((d) => d['parent'] == id);
        final expanded = expandedIds.contains(id);
        
        final processed = Map<String, dynamic>.from(child);
        processed['_indentationLevel'] = level;
        processed['expanded'] = expanded;
        processed['hasChildren'] = hasChildren;
        processed['_isEffectivelyVisible'] = parentVisible && parentExpanded;
        
        result.add(processed);
        addChildren(id, level + 1, processed['_isEffectivelyVisible'], expanded);
      }
    }
    
    addChildren(null, 0, true, true);
    return result;
  }

  Widget _buildControlPanel() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text('Grid Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: const Text('Grid Implementation'),
            trailing: DropdownButton<int>(
              value: _currentGridTypeIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Unified')),
                DropdownMenuItem(value: 1, child: Text('ClientSide')),
                DropdownMenuItem(value: 2, child: Text('ServerSide')),
                DropdownMenuItem(value: 3, child: Text('CustomTable')),
              ],
              onChanged: (v) => setState(() => _currentGridTypeIndex = v!),
            ),
          ),
          ListTile(
            title: const Text('Dataset Type'),
            trailing: DropdownButton<int>(
              value: _currentExampleIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tree Hierarchy')),
                DropdownMenuItem(value: 1, child: Text('Flat List')),
              ],
              onChanged: (v) {
                setState(() {
                  _currentExampleIndex = v!;
                  _loadInitialData();
                });
              },
            ),
          ),
          const Divider(),
          SwitchListTile(title: const Text('Dock Settings Drawer'), value: _isDocked, onChanged: (v) => setState(() => _isDocked = v)),
          SwitchListTile(title: const Text('Allow Filtering'), value: _allowFiltering, onChanged: (v) => setState(() => _allowFiltering = v)),
          SwitchListTile(title: const Text('Allow Sorting'), value: _allowSorting, onChanged: (v) => setState(() => _allowSorting = v)),
          SwitchListTile(title: const Text('Allow Resize'), value: _allowColumnResize, onChanged: (v) => setState(() => _allowColumnResize = v)),
          SwitchListTile(title: const Text('Show Checkboxes'), value: _showCheckboxColumn, onChanged: (v) => setState(() => _showCheckboxColumn = v)),
          SwitchListTile(title: const Text('Show Footer'), value: _showFooter, onChanged: (v) => setState(() => _showFooter = v)),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Global Scale: ${_scale.toStringAsFixed(1)}'),
                Slider(value: _scale, min: 0.5, max: 2.0, onChanged: (v) => setState(() => _scale = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumnDef> _buildColumnDefs() {
    return [
      DataColumnDef.reorder(),
      DataColumnDef(id: 'name', caption: 'Name', flex: 1, isNameColumn: true, filterType: FilterType.string),
      DataColumnDef(id: 'age', caption: 'Age', width: 80, filterType: FilterType.numeric),
      DataColumnDef(
        id: 'status',
        caption: 'Status',
        width: 100,
        cellBuilder: (context, raw, display, scale, row) {
          final color = display == 'active' ? Colors.green : (display == 'pending' ? Colors.orange : Colors.grey);
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: Text(display.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
          );
        }
      ),
      DataColumnDef.actions(
        itemsBuilder: (context, row) => [
          ContextMenuItem(caption: 'Edit', childContent: const Text('Edit'), onTap: () {}),
          ContextMenuItem(caption: 'Delete', childContent: const Text('Delete'), onTap: () {}),
        ],
      ),
    ];
  }

  bool _isAncestor(String potentialAncestorId, String targetId) {
    try {
      var current = _data.firstWhere((d) => d['id'] == targetId);
      String? parentId = current['parent'];
      while (parentId != null) {
        if (parentId == potentialAncestorId) return true;
        current = _data.firstWhere((d) => d['id'] == parentId);
        parentId = current['parent'];
      }
    } catch (_) {}
    return false;
  }

  void _onReorder(String draggedId, String? targetId, bool isAfter) {
    if (targetId != null && (draggedId == targetId || _isAncestor(draggedId, targetId))) {
      return;
    }

    setState(() {
      final oldIdx = _data.indexWhere((d) => d['id'] == draggedId);
      if (oldIdx == -1) return;
      final item = _data.removeAt(oldIdx);
      if (targetId == null) {
        _data.add(item);
      } else {
        var newIdx = _data.indexWhere((d) => d['id'] == targetId);
        if (isAfter) newIdx++;
        _data.insert(newIdx.clamp(0, _data.length), item);
        final targetItem = _data.firstWhere((it) => it['id'] == targetId);
        item['parent'] = targetItem['parent'];
      }
    });
  }

  void _onNest(String draggedId, String targetParentId) {
    if (draggedId == targetParentId || _isAncestor(draggedId, targetParentId)) {
      return;
    }

    setState(() {
      final item = _data.firstWhere((d) => d['id'] == draggedId);
      item['parent'] = targetParentId;
      _expandedIds.add(targetParentId);
    });
    // For UnifiedDataGrid, also trigger the internal expansion
    _gridKey.currentState?.expandRow(targetParentId);
  }

  Widget _buildDataGrid() {
    final columnDefs = _buildColumnDefs();
    
    switch (_currentGridTypeIndex) {
      case 1: // ClientSideDataGrid
        return ClientSideDataGrid<Map<String, dynamic>>(
          key: _gridKey,
          data: _data,
          columnDefs: columnDefs,
          toMap: (i) => i,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: 'parent',
          showCheckboxColumn: _showCheckboxColumn,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          scale: _scale,
          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
          selectedRowIds: _selectedIds,
          onReorder: _onReorder,
          onNest: _onNest,
          showFooter: _showFooter,
        );
      case 2: // ServerSideDataGrid
        return ServerSideDataGrid<Map<String, dynamic>>(
          key: _gridKey,
          fetchData: _mockServerFetch,
          columnDefs: columnDefs,
          toMap: (i) => i,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: 'parent',
          showCheckboxColumn: _showCheckboxColumn,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          scale: _scale,
          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
          selectedRowIds: _selectedIds,
          onReorder: _onReorder,
          onNest: _onNest,
        );
      case 3: // CustomDataTable
        final treeRows = _buildFlatTree(_data, _expandedIds);
        final visibleRows = _currentExampleIndex == 0 
            ? treeRows.where((r) => r['_isEffectivelyVisible'] == true).toList()
            : _data;

        return CustomDataTable(
          columns: columnDefs,
          rows: visibleRows,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          onToggleExpansion: (rowId) {
            setState(() {
              if (_expandedIds.contains(rowId)) {
                _expandedIds.remove(rowId);
              } else {
                _expandedIds.add(rowId);
              }
            });
          },
          indentationLevelKey: '_indentationLevel',
          isEffectivelyVisibleKey: '_isEffectivelyVisible',
          isExpandedKey: 'expanded',
          hasChildrenKey: 'hasChildren',
          showCheckboxColumn: _showCheckboxColumn,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          scale: _scale,
          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
          selectedRowIds: _selectedIds,
          onReorder: (oldIdx, newIdx) {
            setState(() {
              final item = _data.removeAt(oldIdx);
              _data.insert(newIdx.clamp(0, _data.length), item);
            });
          },
          onNest: (dragId, targetId) => _onNest(dragId, targetId),
        );
      case 0:
      default: // UnifiedDataGrid
        return UnifiedDataGrid<Map<String, dynamic>>(
          key: _gridKey,
          mode: DataGridMode.client,
          clientData: _data,
          columnDefs: columnDefs,
          toMap: (item) => item,
          rowIdKey: 'id',
          isTree: _currentExampleIndex == 0,
          parentIdKey: 'parent',
          showCheckboxColumn: _showCheckboxColumn,
          allowFiltering: _allowFiltering,
          allowColumnResize: _allowColumnResize,
          scale: _scale,
          onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
          selectedRowIds: _selectedIds,
          onReorder: _onReorder,
          onNest: _onNest,
          showFooter: _showFooter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'Tree Grid Demo' : 'Selected: ${_selectedIds.length}'),
        actions: [
          if (_currentGridTypeIndex == 0) ...[
            IconButton(icon: const Icon(Icons.save), onPressed: _saveView, tooltip: 'Save View'),
            IconButton(icon: const Icon(Icons.restore), onPressed: _restoreView, tooltip: 'Restore View'),
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearSavedView, tooltip: 'Clear View'),
          ],
          IconButton(
            icon: Icon(_isDocked ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isDocked = !_isDocked),
          ),
        ],
      ),
      drawer: _isDocked ? null : _buildControlPanel(),
      body: Row(
        children: [
          if (_isDocked) SizedBox(width: 320, child: _buildControlPanel()),
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
}
