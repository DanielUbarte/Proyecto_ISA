import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/module_model.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/module_card.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<ModuleModel> _allModules = [];
  List<ModuleModel> _filteredModules = [];
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final list = await _dbService.getModules();
    setState(() {
      _allModules = list;
      _filteredModules = list;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Todos') {
        _filteredModules = _allModules;
      } else if (filter == 'Descargados') {
        _filteredModules = _allModules
            .where((m) => m.status == ModuleStatus.downloaded)
            .toList();
      } else if (filter == 'En curso') {
        _filteredModules = _allModules
            .where((m) =>
                m.status == ModuleStatus.downloading ||
                m.status == ModuleStatus.available)
            .toList();
      } else if (filter == 'Bloqueados') {
        _filteredModules =
            _allModules.where((m) => m.status == ModuleStatus.locked).toList();
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _filteredModules = _allModules
          .where((m) =>
              m.title.toLowerCase().contains(query.toLowerCase()) ||
              m.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos de Historia'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar tema o módulo...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['Todos', 'Descargados', 'En curso', 'Bloqueados']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _selectedFilter == f,
                          selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primaryTeal,
                          labelStyle: TextStyle(
                            color: _selectedFilter == f
                                ? AppColors.primaryTeal
                                : AppColors.textDark,
                            fontWeight: _selectedFilter == f
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) _applyFilter(f);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Module Cards List
          Expanded(
            child: _filteredModules.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron módulos',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredModules.length,
                    itemBuilder: (context, index) {
                      final module = _filteredModules[index];
                      return ModuleCard(
                        module: module,
                        onTap: () {
                          if (module.status == ModuleStatus.downloaded) {
                            Navigator.pushNamed(context, AppRoutes.content);
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.moduleDetail,
                              arguments: module,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
