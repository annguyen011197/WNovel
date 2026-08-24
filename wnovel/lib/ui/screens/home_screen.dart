import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../models/project.dart';
import '../../services/epub_service.dart';
import '../../services/project_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _filter = 'All'; // All, In Progress, Completed
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              _buildSidebar(context),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFEEEEEE),
              ),
              Expanded(child: _buildMainContent(context, library)),
            ],
          ),
          if (_isImporting)
            Container(
              color: Colors.white.withAlpha(204),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Importing EPUB...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFFF9F9F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _sidebarItem(Icons.search, 'Search'),
          _sidebarItem(Icons.access_time, 'Updates'),
          _sidebarItem(Icons.settings, 'Settings'),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'LIBRARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // We can list active projects here later

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'GLOSSARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const Spacer(),
          _sidebarItem(Icons.add, 'Import File', onTap: _importMenu),
          _sidebarItem(Icons.delete_outline, 'Trash'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _importMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('New Blank Draft'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(libraryProvider.notifier)
                      .addProject(
                        Project(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Import EPUB'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = await EpubService.importEpub(
                    onStartParsing: () {
                      if (mounted) setState(() => _isImporting = true);
                    },
                  );
                  if (p != null) {
                    ref.read(libraryProvider.notifier).addProject(p);
                  }
                  if (mounted) {
                    setState(() => _isImporting = false);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Import .wnovel Project'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = await ProjectService.importProject(
                    onStartParsing: () {
                      if (mounted) setState(() => _isImporting = true);
                    },
                  );
                  if (p != null) {
                    ref.read(libraryProvider.notifier).addProject(p);
                  }
                  if (mounted) {
                    setState(() => _isImporting = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, List<Project> library) {
    List<Project> filtered = library;
    if (_filter == 'In Progress') {
      filtered = library.where((p) => p.status == 'IN PROGRESS').toList();
    } else if (_filter == 'Completed') {
      filtered = library.where((p) => p.status == 'COMPLETED').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topbar
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              const Icon(Icons.home_outlined, size: 20),
              const SizedBox(width: 8),
              const Text(
                '/ Library',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                width: 200,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Search projects...',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Projects',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage your translation library.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      _filterChip('All'),
                      const SizedBox(width: 8),
                      _filterChip('In Progress'),
                      const SizedBox(width: 8),
                      _filterChip('Completed'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Project List
              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No projects found.'),
                  ),
                )
              else
                ...filtered.map((p) => _buildProjectCard(p)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Cover placeholder
          Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.book, color: Colors.grey),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.author,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // Progress
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: project.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(project.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chapters
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CHAPTERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.chapters.where((c) => c.status == 'done').length} / ${project.chapters.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: project.status == 'COMPLETED'
                        ? Colors.green.shade100
                        : (project.status == 'IN PROGRESS'
                              ? Colors.blue.shade100
                              : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    project.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: project.status == 'COMPLETED'
                          ? Colors.green.shade800
                          : (project.status == 'IN PROGRESS'
                                ? Colors.blue.shade800
                                : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
