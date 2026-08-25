import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../providers/translation_provider.dart';
import '../../services/api_service.dart';
import '../../models/project.dart';
import '../widgets/reader_main_content.dart';

import '../widgets/batch_config_dialog.dart';
import 'login_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  String? _selectedChapterId;
  bool _isLibraryExpanded = true;
  bool _isGlossaryExpanded = false;
  bool _isSystemLogExpanded = true;
  int _overviewPage = 0;
  static const int _chaptersPerPage = 20;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TranslationState>(translationProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final project = ref.watch(activeProjectProvider);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('No project selected.')));
    }

    Chapter? chapter;
    if (_selectedChapterId != null) {
      final matches = project.chapters.where((c) => c.id == _selectedChapterId);
      if (matches.isNotEmpty) {
        chapter = matches.first;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildSidebar(context, project),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
          Expanded(
            child: SelectionArea(
              child: Column(
                children: [
                  _buildTopBar(project, chapter),
                  Expanded(
                    child: chapter == null
                        ? _buildProjectOverview(project)
                        : ReaderMainContent(chapter: chapter),
                  ),
                  _buildSystemLog(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, Project project) {
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

          // Library Section
          InkWell(
            onTap: () =>
                setState(() => _isLibraryExpanded = !_isLibraryExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isLibraryExpanded
                        ? Icons.arrow_drop_down
                        : Icons.arrow_right,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIBRARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLibraryExpanded)
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    project.chapters.length +
                    2, // Overview + Divider + chapters
                itemBuilder: (ctx, index) {
                  // Overview item
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedChapterId = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedChapterId == null
                              ? Colors.grey.shade200
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.dashboard_outlined,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Overview',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedChapterId == null
                                      ? Colors.black
                                      : Colors.grey.shade800,
                                  fontWeight: _selectedChapterId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Divider
                  if (index == 1) {
                    return const Divider(height: 12, indent: 16, endIndent: 16);
                  }
                  // Chapter items
                  final i = index - 2;
                  final ch = project.chapters[i];
                  final isSelected = ch.id == _selectedChapterId;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedChapterId = ch.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.grey.shade200
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${i + 1}.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ch.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade800,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildChapterStatusIcon(ch.status),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (!_isLibraryExpanded) const Spacer(),

          // Glossary Section
          InkWell(
            onTap: () =>
                setState(() => _isGlossaryExpanded = !_isGlossaryExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isGlossaryExpanded
                        ? Icons.arrow_drop_down
                        : Icons.arrow_right,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GLOSSARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Project Stats Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROJECT STATS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${project.chapters.where((c) => c.status == 'done').length}/${project.chapters.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tokens',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Text(
                      '1.2M',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cost',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Text(
                      '9,500 VNĐ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _sidebarItem(
            Icons.arrow_back,
            'Back to Home',
            onTap: () {
              ref.read(activeProjectIdProvider.notifier).state = null;
              Navigator.pop(context);
            },
          ),
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

  Widget _buildChapterStatusIcon(String status) {
    if (status == 'done') {
      return const Icon(Icons.check_circle, size: 14, color: Colors.green);
    } else if (status == 'translating') {
      return const Icon(Icons.sync, size: 14, color: Colors.blue);
    }
    return Icon(Icons.circle_outlined, size: 14, color: Colors.grey.shade400);
  }

  Widget _buildTopBar(Project project, Chapter? chapter) {
    final library = ref.watch(libraryProvider);
    final activeProject = ref.watch(activeProjectProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Switch Project / Return to Library',
            offset: const Offset(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if (value == '__home__') {
                ref.read(activeProjectIdProvider.notifier).state = null;
                Navigator.pop(context);
              } else {
                ref.read(activeProjectIdProvider.notifier).state = value;
                setState(() {
                  _selectedChapterId = null;
                  _overviewPage = 0;
                });
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem<String>(
                value: '__home__',
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('All Projects (Home)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (library.isNotEmpty) const PopupMenuDivider(),
              ...library.map(
                (p) => PopupMenuItem<String>(
                  value: p.id,
                  child: Row(
                    children: [
                      Icon(
                        p.id == activeProject?.id
                            ? Icons.check
                            : Icons.book_outlined,
                        size: 16,
                        color: p.id == activeProject?.id
                            ? Colors.blue
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: p.id == activeProject?.id
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Library',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _selectedChapterId = null;
              });
            },
            child: Text(
              project.title,
              style: TextStyle(
                fontWeight: chapter == null ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: chapter == null ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ),
          if (chapter != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              chapter.title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectOverview(Project project) {
    final totalChapters = project.chapters.length;
    final totalPages = totalChapters == 0
        ? 1
        : ((totalChapters + _chaptersPerPage - 1) ~/ _chaptersPerPage);
    final currentPage = _overviewPage.clamp(0, totalPages - 1);
    final startIndex = currentPage * _chaptersPerPage;
    final endIndex = (startIndex + _chaptersPerPage > totalChapters)
        ? totalChapters
        : startIndex + _chaptersPerPage;
    final pageChapters = totalChapters == 0
        ? <Chapter>[]
        : project.chapters.sublist(startIndex, endIndex);

    return CustomScrollView(
      slivers: [
        // Project details header (non-repeating content)
        SliverPadding(
          padding: const EdgeInsets.all(32.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'PROJECT DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Project Name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: ValueKey(project.id),
                        initialValue: project.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter project name...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          suffixIcon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                        onChanged: (newTitle) {
                          project.title = newTitle;
                          ref
                              .read(libraryProvider.notifier)
                              .updateProject(project);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Author',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project.author,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chapters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${project.chapters.length} chapters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
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
                                      fontSize: 11,
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapters ($totalChapters)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalChapters > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Showing ${startIndex + 1}–$endIndex of $totalChapters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (project.chapters.isNotEmpty)
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              if (!ApiService().isAuthenticated) {
                                final loggedIn = await Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                if (loggedIn != true) return;
                              }
                              final config =
                                  await showDialog<BatchConfigResult>(
                                    context: context,
                                    builder: (ctx) =>
                                        BatchConfigDialog(project: project),
                                  );
                              if (config != null) {
                                final startIndex = config.startIndex;
                                if (project.chapters[startIndex].status ==
                                    'done') {
                                  project.chapters[startIndex].status =
                                      'pending';
                                  ref
                                      .read(libraryProvider.notifier)
                                      .updateProject(project);
                                }
                                ref
                                    .read(translationProvider.notifier)
                                    .startBatchTranslation(
                                      project,
                                      config.startIndex,
                                      config.count,
                                    );
                              }
                            },
                            icon: const Icon(Icons.batch_prediction, size: 18),
                            label: const Text('Batch Translate'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedChapterId = project.chapters.first.id;
                              });
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Start Reading'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Chapter list (paginated)
        if (project.chapters.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Center(
                  child: Text(
                    'No chapters in this project yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            sliver: SliverList.builder(
              itemCount: pageChapters.length,
              itemBuilder: (ctx, i) {
                final ch = pageChapters[i];
                final chapterNumber = startIndex + i + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedChapterId = ch.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$chapterNumber.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              ch.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _buildChapterStatusIcon(ch.status),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (totalPages > 1)
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 32.0,
                top: 16.0,
                bottom: 40.0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page, size: 20),
                      tooltip: 'First Page',
                      onPressed: currentPage > 0
                          ? () => setState(() => _overviewPage = 0)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: 'Previous Page',
                      onPressed: currentPage > 0
                          ? () =>
                                setState(() => _overviewPage = currentPage - 1)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFFAFAFA),
                      ),
                      child: Text(
                        'Page ${currentPage + 1} of $totalPages',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      tooltip: 'Next Page',
                      onPressed: currentPage < totalPages - 1
                          ? () =>
                                setState(() => _overviewPage = currentPage + 1)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page, size: 20),
                      tooltip: 'Last Page',
                      onPressed: currentPage < totalPages - 1
                          ? () => setState(() => _overviewPage = totalPages - 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSystemLog() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _isSystemLogExpanded ? 120 : 36,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _isSystemLogExpanded = !_isSystemLogExpanded),
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isSystemLogExpanded
                        ? const Color(0xFFEEEEEE)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SYSTEM LOG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isSystemLogExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isSystemLogExpanded)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _logEntry(
                    '[10:42:05]',
                    'Model initialized: GPT-4-Turbo-Lit-v2. Context window: 128k.',
                  ),
                  _logEntry(
                    '[10:42:12]',
                    'Analyzing glossary terms for Chapter... Found 14 matched entities.',
                  ),
                  _logEntry(
                    '[10:42:15]',
                    "Processing Segment #4 (Char count: 125). Applying stylistic template 'Xianxia_Formal'.",
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _logEntry(String time, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 12,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$time ',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            TextSpan(text: message),
          ],
        ),
      ),
    );
  }
}
