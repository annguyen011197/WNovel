import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_provider.dart';
import 'reader_screen.dart';

class EbookReaderScreen extends ConsumerStatefulWidget {
  final String? initialChapterId;

  const EbookReaderScreen({super.key, this.initialChapterId});

  @override
  ConsumerState<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends ConsumerState<EbookReaderScreen> {
  static const _ink = Color(0xFF272421);
  static const _mutedInk = Color(0xFF817B74);
  static const _paper = Color(0xFFF7F4EF);
  static const _accent = Color(0xFF9A5B3D);

  late int _chapterIndex;
  bool _hasAppliedInitialChapter = false;
  double _fontSize = 18;
  bool _darkMode = false;
  bool _showChapterList = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chapterIndex = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setChapter(Project project, int index) {
    if (index < 0 || index >= project.chapters.length) return;
    setState(() => _chapterIndex = index);
    _scrollController.jumpTo(0);
  }

  void _openEditor(Chapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(initialChapterId: chapter.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    if (project == null || project.chapters.isEmpty) {
      return Scaffold(
        backgroundColor: _paper,
        body: Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Return to library'),
          ),
        ),
      );
    }

    if (!_hasAppliedInitialChapter) {
      final requestedIndex = project.chapters.indexWhere(
        (chapter) => chapter.id == widget.initialChapterId,
      );
      if (requestedIndex >= 0) {
        _chapterIndex = requestedIndex;
      }
      _hasAppliedInitialChapter = true;
    }

    final chapter = project.chapters[_chapterIndex];
    final isDark = _darkMode;
    final background = isDark ? const Color(0xFF211F1D) : _paper;
    final foreground = isDark ? const Color(0xFFF3EEE7) : _ink;
    final secondary = isDark ? const Color(0xFFB8AEA3) : _mutedInk;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Column(
              children: [
                _buildHeader(project, chapter, foreground, secondary),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide && _showChapterList)
                        _buildChapterRail(project, foreground, secondary),
                      Expanded(
                        child: _buildReaderBody(
                          project,
                          chapter,
                          foreground,
                          secondary,
                          background,
                          wide,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFooter(project, chapter, foreground, secondary),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    Project project,
    Chapter chapter,
    Color foreground,
    Color secondary,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: foreground.withAlpha(25))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to editor',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: foreground),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chapter.translatedTitle.isEmpty
                      ? chapter.title
                      : chapter.translatedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chapter list',
            onPressed: () =>
                setState(() => _showChapterList = !_showChapterList),
            icon: Icon(Icons.menu_book_outlined, color: foreground),
          ),
          IconButton(
            tooltip: 'Decrease text size',
            onPressed: _fontSize <= 14
                ? null
                : () => setState(() => _fontSize -= 1),
            icon: Icon(Icons.text_decrease, color: foreground),
          ),
          IconButton(
            tooltip: 'Increase text size',
            onPressed: _fontSize >= 26
                ? null
                : () => setState(() => _fontSize += 1),
            icon: Icon(Icons.text_increase, color: foreground),
          ),
          IconButton(
            tooltip: _darkMode ? 'Use light theme' : 'Use dark theme',
            onPressed: () => setState(() => _darkMode = !_darkMode),
            icon: Icon(
              _darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterRail(Project project, Color foreground, Color secondary) {
    return Container(
      width: 256,
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 20),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: foreground.withAlpha(20))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHAPTERS',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: project.chapters.length,
              itemBuilder: (context, index) {
                final chapter = project.chapters[index];
                final selected = index == _chapterIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: selected,
                    selectedTileColor: _accent.withAlpha(22),
                    onTap: () => _setChapter(project, index),
                    leading: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        color: selected ? _accent : secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(
                      chapter.translatedTitle.isEmpty
                          ? chapter.title
                          : chapter.translatedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: chapter.skipTranslation
                        ? Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: secondary,
                          )
                        : chapter.translatedText.isNotEmpty
                        ? Icon(Icons.check, size: 15, color: secondary)
                        : Icon(Icons.more_horiz, size: 16, color: secondary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderBody(
    Project project,
    Chapter chapter,
    Color foreground,
    Color secondary,
    Color background,
    bool wide,
  ) {
    final translated = chapter.translatedText.trim();
    final showOriginal = chapter.skipTranslation || translated.isEmpty;
    final paragraphs = (showOriginal ? chapter.originalText : translated)
        .split(RegExp(r'\n\s*\n|\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 22, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHAPTER ${(_chapterIndex + 1).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                chapter.translatedTitle.isEmpty
                    ? chapter.title
                    : chapter.translatedTitle,
                style: TextStyle(
                  color: foreground,
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 28),
              Divider(color: foreground.withAlpha(28)),
              const SizedBox(height: 30),
              if (translated.isEmpty && !chapter.skipTranslation)
                _buildUntranslatedContent(
                  chapter,
                  paragraphs,
                  foreground,
                  secondary,
                  background,
                )
              else
                ...paragraphs.map(
                  (paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        color: foreground,
                        fontSize: _fontSize,
                        height: 1.75,
                        letterSpacing: .1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUntranslatedContent(
    Chapter chapter,
    List<String> paragraphs,
    Color foreground,
    Color secondary,
    Color background,
  ) {
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraphs
                .map(
                  (paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        color: foreground,
                        fontSize: _fontSize,
                        height: 1.75,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: background.withAlpha(190),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withAlpha(24)),
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined, color: _accent, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      'Translation not ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Translate this chapter in the editor to read it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondary, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _openEditor(chapter),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Open editor'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(
    Project project,
    Chapter chapter,
    Color foreground,
    Color secondary,
  ) {
    final progress = (_chapterIndex + 1) / project.chapters.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: foreground.withAlpha(25))),
      ),
      child: Row(
        children: [
          Text(
            '${_chapterIndex + 1} of ${project.chapters.length}',
            style: TextStyle(color: secondary, fontSize: 12),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: foreground.withAlpha(20),
                valueColor: const AlwaysStoppedAnimation(_accent),
              ),
            ),
          ),
          const SizedBox(width: 18),
          IconButton(
            tooltip: 'Previous chapter',
            onPressed: _chapterIndex == 0
                ? null
                : () => _setChapter(project, _chapterIndex - 1),
            icon: Icon(Icons.chevron_left, color: foreground),
          ),
          IconButton(
            tooltip: 'Next chapter',
            onPressed: _chapterIndex == project.chapters.length - 1
                ? null
                : () => _setChapter(project, _chapterIndex + 1),
            icon: Icon(Icons.chevron_right, color: foreground),
          ),
        ],
      ),
    );
  }
}
