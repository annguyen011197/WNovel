import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/project.dart';
import '../services/api_service.dart';
import 'project_provider.dart';

class TranslationState {
  final bool isTranslating;
  final int currentChapterIndex;
  final int startChapterIndex;
  final int targetChapterCount;
  final String? errorMessage;

  TranslationState({
    this.isTranslating = false,
    this.currentChapterIndex = -1,
    this.startChapterIndex = -1,
    this.targetChapterCount = 0,
    this.errorMessage,
  });

  TranslationState copyWith({
    bool? isTranslating,
    int? currentChapterIndex,
    int? startChapterIndex,
    int? targetChapterCount,
    String? errorMessage,
  }) {
    return TranslationState(
      isTranslating: isTranslating ?? this.isTranslating,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      startChapterIndex: startChapterIndex ?? this.startChapterIndex,
      targetChapterCount: targetChapterCount ?? this.targetChapterCount,
      errorMessage:
          errorMessage, // We don't use ?? here to allow clearing the error
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final Ref _ref;
  bool _cancelRequested = false;

  TranslationNotifier(this._ref) : super(TranslationState());

  Future<void> startBatchTranslation(
    Project project,
    int startIndex,
    int count,
  ) async {
    if (state.isTranslating) return;

    _cancelRequested = false;

    // If the start chapter is already done, reset it to allow re-translation.
    // This lets callers simply call startBatchTranslation without needing to
    // mutate project state themselves.
    if (startIndex < project.chapters.length &&
        project.chapters[startIndex].status == ChapterStatus.done) {
      project.chapters[startIndex] = project.chapters[startIndex].copyWith(
        status: ChapterStatus.pending,
      );
      _updateProject(project);
    }

    state = state.copyWith(
      isTranslating: true,
      startChapterIndex: startIndex,
      currentChapterIndex: startIndex,
      targetChapterCount: count,
      errorMessage: null,
    );

    int translatedCount = 0;

    while (translatedCount < count &&
        state.currentChapterIndex < project.chapters.length) {
      if (_cancelRequested) {
        break;
      }

      final chapterIndex = state.currentChapterIndex;
      final chapter = project.chapters[chapterIndex];

      // Sequential check: Is previous chapter done?
      // We bypass this check for the very first chapter of the batch (startIndex)
      // because the user explicitly chose to start there.
      if (chapterIndex > 0 && chapterIndex > startIndex) {
        if (project.chapters[chapterIndex - 1].status != ChapterStatus.done) {
          state = state.copyWith(
            isTranslating: false,
            errorMessage: 'Translation halted: Previous chapter is not done.',
          );
          return;
        }
      }

      if (chapter.status == ChapterStatus.done) {
        // Skip already translated chapters
        state = state.copyWith(
          currentChapterIndex: state.currentChapterIndex + 1,
        );
        continue;
      }

      // We found a pending chapter — immutable update via copyWith
      project.chapters[chapterIndex] = chapter.copyWith(
        status: ChapterStatus.translating,
      );
      _updateProject(project);

      try {
        // Assemble Context
        List<String> previousSummaries = [];
        for (
          int i = chapterIndex - 1;
          i >= 0 && previousSummaries.length < 2;
          i--
        ) {
          if (project.chapters[i].status == ChapterStatus.done &&
              project.chapters[i].summary.isNotEmpty) {
            previousSummaries.insert(0, project.chapters[i].summary);
          }
        }

        List<Map<String, dynamic>> glossary = project.characters
            .map(
              (c) => {
                'originalName': c.originalName,
                'translatedName': c.translatedName,
                'description': c.description,
              },
            )
            .toList();

        // API Call
        final result = await _ref.read(apiServiceProvider).translateChapter(
          chapter.originalText,
          glossary,
          previousSummaries,
        );

        // Update chapter — immutable update via copyWith
        project.chapters[chapterIndex] = project.chapters[chapterIndex].copyWith(
          translatedText: result['translatedText'] ?? '',
          summary: result['summary'] ?? '',
          status: ChapterStatus.done,
        );

        // Add new characters (dummy parsing logic for now)
        final newCharactersList = result['newCharacters'] as List?;
        if (newCharactersList != null) {
          for (var charMap in newCharactersList) {
            project.characters.add(
              Character(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    charMap['originalName'],
                originalName: charMap['originalName'],
                translatedName: charMap['translatedName'],
                description: charMap['description'] ?? '',
              ),
            );
          }
        }

        // Similarly for relations (skip for brevity unless needed)

        _updateProject(project);

        translatedCount++;

        // RPM Throttle Limit (4 requests / min = 15 seconds)
        if (translatedCount < count) {
          debugPrint("Waiting 15 seconds for RPM limit...");
          await Future.delayed(const Duration(seconds: 15));
        }
      } catch (e) {
        project.chapters[chapterIndex] = project.chapters[chapterIndex].copyWith(
          status: ChapterStatus.pending,
        ); // revert
        _updateProject(project);
        state = state.copyWith(
          isTranslating: false,
          errorMessage: 'Failed at chapter ${chapter.title}: $e',
        );
        return;
      }

      // Move to next chapter
      state = state.copyWith(
        currentChapterIndex: state.currentChapterIndex + 1,
      );
    }

    state = state.copyWith(isTranslating: false);
  }

  /// Translates a single chapter without context ("translate only" mode).
  /// Sets status -> translating, calls API, sets result or reverts on error.
  Future<void> translateChapterOnly(Project project, Chapter chapter) async {
    if (state.isTranslating) {
      state = state.copyWith(
        errorMessage: 'A translation is already in progress.',
      );
      return;
    }

    final chapterIndex = project.chapters.indexWhere((c) => c.id == chapter.id);
    if (chapterIndex == -1) return;

    // Mark as translating
    project.chapters[chapterIndex] = chapter.copyWith(
      status: ChapterStatus.translating,
    );
    _updateProject(project);

    try {
      final result = await _ref.read(apiServiceProvider).translateOnly(
        chapter.originalText,
      );

      project.chapters[chapterIndex] = project.chapters[chapterIndex].copyWith(
        translatedText: result['translatedText'] ?? '',
        status: ChapterStatus.done,
      );
      _updateProject(project);
    } catch (e) {
      // Revert status on error
      project.chapters[chapterIndex] = project.chapters[chapterIndex].copyWith(
        status: ChapterStatus.pending,
      );
      _updateProject(project);
      state = state.copyWith(
        errorMessage: 'Translation failed: $e',
      );
    }
  }

  void cancelTranslation() {
    _cancelRequested = true;
  }

  void _updateProject(Project project) {
    _ref.read(libraryProvider.notifier).updateProject(project);
  }
}

final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
      return TranslationNotifier(ref);
    });
