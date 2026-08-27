import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/translation_provider.dart';
import '../../services/api_service.dart';
import '../screens/login_screen.dart';

class ReaderMainContent extends ConsumerStatefulWidget {
  final Chapter chapter;

  const ReaderMainContent({super.key, required this.chapter});

  @override
  ConsumerState<ReaderMainContent> createState() => _ReaderMainContentState();
}

class _ReaderMainContentState extends ConsumerState<ReaderMainContent> {
  // Layout constants
  static const double _horizontalPadding = 32.0;
  static const double _dividerGapWidth = 24.0;
  static const double _totalHorizontalInset =
      _horizontalPadding * 2 + _dividerGapWidth; // 88

  double _splitRatio = 0.5;

  // Cached paragraph lists — recomputed only when chapter content changes
  List<String> _sourceParagraphs = const [];
  List<String> _targetParagraphs = const [];
  String _lastOriginalText = '';
  String _lastTranslatedText = '';

  @override
  void initState() {
    super.initState();
    _updateParagraphs(widget.chapter);
  }

  @override
  void didUpdateWidget(covariant ReaderMainContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.originalText != widget.chapter.originalText ||
        oldWidget.chapter.translatedText != widget.chapter.translatedText) {
      _updateParagraphs(widget.chapter);
    }
  }

  void _updateParagraphs(Chapter chapter) {
    if (chapter.originalText != _lastOriginalText) {
      _lastOriginalText = chapter.originalText;
      _sourceParagraphs = chapter.originalText
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    }
    if (chapter.translatedText != _lastTranslatedText) {
      _lastTranslatedText = chapter.translatedText;
      _targetParagraphs = chapter.translatedText
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TranslationState>(translationProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final chapter = widget.chapter;
    final isTranslating = ref.watch(translationProvider).isTranslating;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftFlex = (_splitRatio * 1000).toInt();
        final rightFlex = 1000 - leftFlex;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(_horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Translate Chapter',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.translate, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Translate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) async {
                      final project = ref.read(activeProjectProvider);
                      if (project == null) return;

                      if (!ApiService().isAuthenticated) {
                        final loggedIn = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        if (!context.mounted || loggedIn != true) return;
                      }

                      if (value == 'following') {
                        final isTranslating = ref
                            .read(translationProvider)
                            .isTranslating;
                        if (isTranslating) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A translation is already running. Please cancel it first.',
                              ),
                            ),
                          );
                          return;
                        }

                        if (chapter.status == ChapterStatus.translating) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chapter is already translating.'),
                            ),
                          );
                          return;
                        }
                        final index = project.chapters.indexWhere(
                          (c) => c.id == chapter.id,
                        );
                        if (index != -1) {
                          ref
                              .read(translationProvider.notifier)
                              .startBatchTranslation(project, index, 1);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Translation started.'),
                              ),
                            );
                        }
                      } else if (value == 'only') {
                        final isTranslating = ref
                            .read(translationProvider)
                            .isTranslating;
                        if (isTranslating) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A translation is already running. Please cancel it first.',
                              ),
                            ),
                          );
                          return;
                        }

                        ref
                            .read(translationProvider.notifier)
                            .translateChapterOnly(project, chapter);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Translation started.'),
                            ),
                          );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'following',
                        child: Text('Following Story (Affects context)'),
                      ),
                      const PopupMenuItem(
                        value: 'only',
                        child: Text('Translate Only (No context updates)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: leftFlex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOURCE TEXT (ZH)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          chapter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _dividerGapWidth),
                  Expanded(
                    flex: rightFlex,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TARGET TEXT (VI) - DRAFT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              chapter.translatedTitle.isEmpty
                                  ? '—'
                                  : chapter.translatedTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.undo,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.redo,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),

            // Side-by-side translation
            Expanded(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: leftFlex,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            _horizontalPadding,
                            16,
                            0,
                            32,
                          ),
                          itemCount: _sourceParagraphs.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 32),
                          itemBuilder: (ctx, i) => Text(
                            _sourceParagraphs[i],
                            style: const TextStyle(fontSize: 15, height: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: _dividerGapWidth),
                      Expanded(
                        flex: rightFlex,
                        child: Stack(
                          children: [
                            if (_targetParagraphs.isNotEmpty)
                              ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  16,
                                  _horizontalPadding,
                                  32,
                                ),
                                itemCount: _targetParagraphs.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 32),
                                itemBuilder: (ctx, i) => Text(
                                  _targetParagraphs[i],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.8,
                                  ),
                                ),
                              ),
                            if (_targetParagraphs.isEmpty)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isTranslating) ...[
                                          const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              semanticsLabel:
                                                  'Translation in progress',
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        Text(
                                          isTranslating
                                              ? 'Translation in progress...'
                                              : 'Waiting for translation...',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Continuous Split Pane Divider
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left:
                        _horizontalPadding +
                        (constraints.maxWidth - _totalHorizontalInset) *
                            _splitRatio,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _splitRatio +=
                                details.delta.dx /
                                (constraints.maxWidth - _totalHorizontalInset);
                            if (_splitRatio < 0.2) _splitRatio = 0.2;
                            if (_splitRatio > 0.8) _splitRatio = 0.8;
                          });
                        },
                        child: Container(
                          width: _dividerGapWidth,
                          color: Colors.transparent, // Expand hit area
                          child: Center(
                            child: Container(
                              width: 2,
                              color:
                                  Colors.grey.shade200, // Subtle vertical line
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
