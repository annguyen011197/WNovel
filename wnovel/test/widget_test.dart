import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wnovel/models/project.dart';
import 'package:wnovel/providers/project_provider.dart';
import 'package:wnovel/ui/screens/ebook_reader_screen.dart';
import 'package:wnovel/ui/widgets/batch_config_dialog.dart';

Project _project() => Project(
  id: 'project-1',
  title: 'The Long Road Home',
  chapters: [
    Chapter(
      id: 'chapter-1',
      title: 'Chapter One',
      originalText: '原文段落',
      translatedTitle: 'The First Step',
      translatedText: 'The road began beneath a pale morning sky.',
      status: ChapterStatus.done,
    ),
    Chapter(id: 'chapter-2', title: 'Chapter Two', originalText: '未翻译的原文'),
    Chapter(
      id: 'chapter-3',
      title: 'Appendix',
      originalText: 'A source-only appendix.',
      skipTranslation: true,
    ),
  ],
);

Widget _reader(Project project, {String? initialChapterId}) {
  return ProviderScope(
    overrides: [activeProjectProvider.overrideWithValue(project)],
    child: MaterialApp(
      home: EbookReaderScreen(initialChapterId: initialChapterId),
    ),
  );
}

void main() {
  test('persists the source-only chapter setting', () {
    final chapter = Chapter(
      id: 'chapter-1',
      title: 'Appendix',
      originalText: 'Source content',
      skipTranslation: true,
    );

    final restored = Chapter.fromJson(chapter.toJson());

    expect(restored.skipTranslation, isTrue);
  });

  testWidgets('batch dialog starts at the last translated chapter', (
    tester,
  ) async {
    final project = Project(
      id: 'batch-project',
      chapters: [
        Chapter(
          id: 'one',
          title: 'Chapter One',
          originalText: 'One',
          status: ChapterStatus.done,
        ),
        Chapter(
          id: 'two',
          title: 'Chapter Two',
          originalText: 'Two',
          status: ChapterStatus.done,
        ),
        Chapter(id: 'three', title: 'Chapter Three', originalText: 'Three'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BatchConfigDialog(project: project),
            ),
            child: const Text('Open batch dialog'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open batch dialog'));
    await tester.pumpAndSettle();

    expect(find.text('2. Chapter Two'), findsOneWidget);
  });

  testWidgets('renders translated content and navigates chapters', (
    tester,
  ) async {
    await tester.pumpWidget(_reader(_project()));

    expect(find.text('The First Step'), findsWidgets);
    expect(
      find.text('The road began beneath a pale morning sky.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next chapter'));
    await tester.pumpAndSettle();

    expect(find.text('Translation not ready'), findsOneWidget);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('opens at the requested chapter', (tester) async {
    await tester.pumpWidget(_reader(_project(), initialChapterId: 'chapter-2'));

    expect(find.text('CHAPTER 02'), findsOneWidget);
    expect(find.text('Translation not ready'), findsOneWidget);
  });

  testWidgets('keeps navigation changes after an initial chapter is provided', (
    tester,
  ) async {
    await tester.pumpWidget(_reader(_project(), initialChapterId: 'chapter-1'));

    await tester.tap(find.byTooltip('Next chapter'));
    await tester.pumpAndSettle();

    expect(find.text('CHAPTER 02'), findsOneWidget);
    expect(find.text('Translation not ready'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous chapter'));
    await tester.pumpAndSettle();

    expect(find.text('CHAPTER 01'), findsOneWidget);
  });

  testWidgets('shows source-only chapters without the translation prompt', (
    tester,
  ) async {
    await tester.pumpWidget(_reader(_project(), initialChapterId: 'chapter-3'));

    expect(find.text('A source-only appendix.'), findsOneWidget);
    expect(find.text('Translation not ready'), findsNothing);
    expect(find.text('Open editor'), findsNothing);
  });
}
