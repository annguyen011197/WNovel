import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/translation_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project.dart';

class TranslationOverlayWidget extends ConsumerWidget {
  const TranslationOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(translationProvider);
    if (!state.isTranslating) return const SizedBox.shrink();

    final library = ref.watch(libraryProvider);
    Project? project;
    try {
      project = library.firstWhere((p) => p.id == state.projectId);
    } catch (_) {}

    if (project == null) return const SizedBox.shrink();

    final total = state.targetChapterCount;
    final current = state.currentChapterIndex - state.startChapterIndex + 1;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    final currentChapterTitle =
        state.currentChapterIndex >= 0 &&
            state.currentChapterIndex < project.chapters.length
        ? project.chapters[state.currentChapterIndex].title
        : 'Unknown Chapter';

    if (state.isMinimized) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              ref.read(translationProvider.notifier).toggleMinimize();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Translating $current/$total',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      ref
                          .read(translationProvider.notifier)
                          .cancelTranslation();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Material(
            elevation: 24,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Translating',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_fullscreen),
                        onPressed: () {
                          ref
                              .read(translationProvider.notifier)
                              .toggleMinimize();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          semanticsLabel: 'Translation progress',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chapter $current of $total',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentChapterTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () {
                        ref
                            .read(translationProvider.notifier)
                            .cancelTranslation();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
