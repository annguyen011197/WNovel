import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/translation_provider.dart';
import '../../services/api_service.dart';

class ReaderMainContent extends ConsumerStatefulWidget {
  final Chapter chapter;

  const ReaderMainContent({super.key, required this.chapter});

  @override
  ConsumerState<ReaderMainContent> createState() => _ReaderMainContentState();
}

class _ReaderMainContentState extends ConsumerState<ReaderMainContent> {
  double _splitRatio = 0.5;

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

    final chapter = widget.chapter;
    final sourceParagraphs = chapter.originalText
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final targetParagraphs = chapter.translatedText
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftFlex = (_splitRatio * 1000).toInt();
        final rightFlex = 1000 - leftFlex;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(32.0),
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

                      if (value == 'following') {
                        if (chapter.status == 'translating') {
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
                          if (chapter.status == 'done') {
                            // Reset status to allow re-translation
                            chapter.status = 'pending';
                            ref
                                .read(libraryProvider.notifier)
                                .updateProject(project);
                          }
                          ref
                              .read(translationProvider.notifier)
                              .startBatchTranslation(project, index, 1);
                        }
                      } else if (value == 'only') {
                        // Implement translate only
                        setState(() {
                          chapter.status = 'translating';
                          ref
                              .read(libraryProvider.notifier)
                              .updateProject(project);
                        });
                        try {
                          final result = await ApiService().translateOnly(
                            chapter.originalText,
                          );
                          setState(() {
                            chapter.translatedText =
                                result['translatedText'] ?? '';
                            chapter.status = 'done';
                            ref
                                .read(libraryProvider.notifier)
                                .updateProject(project);
                          });
                        } catch (e) {
                          setState(() {
                            chapter.status = 'pending';
                            ref
                                .read(libraryProvider.notifier)
                                .updateProject(project);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Translation failed: \$e')),
                          );
                        }
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  Expanded(
                    flex: leftFlex,
                    child: Text(
                      'SOURCE TEXT (ZH)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: rightFlex,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    itemCount: sourceParagraphs.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 32),
                    itemBuilder: (ctx, i) {
                      final source = sourceParagraphs[i];
                      final target = i < targetParagraphs.length
                          ? targetParagraphs[i]
                          : '';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: leftFlex,
                            child: Text(
                              source,
                              style: const TextStyle(fontSize: 15, height: 1.8),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: rightFlex,
                            child: target.isEmpty
                                ? const SizedBox()
                                : Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      target,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (targetParagraphs.isEmpty)
                    Positioned(
                      top: 16,
                      bottom: 16,
                      left: 32 + (constraints.maxWidth - 88) * _splitRatio + 24,
                      right: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'Waiting for translation...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Continuous Split Pane Divider
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 32 + (constraints.maxWidth - 88) * _splitRatio,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _splitRatio +=
                                details.delta.dx / (constraints.maxWidth - 88);
                            if (_splitRatio < 0.2) _splitRatio = 0.2;
                            if (_splitRatio > 0.8) _splitRatio = 0.8;
                          });
                        },
                        child: Container(
                          width: 24,
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
