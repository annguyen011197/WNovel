import 'dart:async';
import 'dart:convert';
import 'package:squadron/squadron.dart';
import 'package:epubx/epubx.dart';
import 'package:archive/archive.dart';

import '../../models/project.dart';

import 'parser_service.activator.g.dart';
part 'parser_service.worker.g.dart';

final parserWorker = ParserServiceWorker();

@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.all)
base class ParserService {
  @SquadronMethod()
  FutureOr<Map<String, dynamic>> parseEpub(List<int> bytes, String title) async {
    EpubBook epubBook = await EpubReader.readBook(bytes);
    
    List<Map<String, dynamic>> chapters = [];
    
    if (epubBook.Chapters != null) {
      int index = 1;
      for (var epubChapter in epubBook.Chapters!) {
        chapters.addAll(_flattenChapters(epubChapter, refIndex: index));
        index += 100;
      }
    }

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': epubBook.Title ?? title,
      'author': epubBook.Author ?? 'Unknown Author',
      'chapters': chapters,
      'characters': [],
      'relations': [],
    };
  }

  List<Map<String, dynamic>> _flattenChapters(EpubChapter epubChapter, {int refIndex = 0}) {
    List<Map<String, dynamic>> list = [];
    final id = DateTime.now().millisecondsSinceEpoch.toString() + refIndex.toString();
    
    String text = epubChapter.HtmlContent ?? '';
    text = text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n\n', '\n').trim();

    if (text.isNotEmpty) {
      list.add({
        'id': id,
        'title': epubChapter.Title ?? 'Chapter',
        'originalText': text,
        'translatedText': '',
        'summary': '',
        'status': ChapterStatus.pending.name,
      });
    }

    if (epubChapter.SubChapters != null) {
      int subIndex = 1;
      for (var sub in epubChapter.SubChapters!) {
        list.addAll(_flattenChapters(sub, refIndex: refIndex + subIndex));
        subIndex++;
      }
    }
    
    return list;
  }

  @SquadronMethod()
  FutureOr<Map<String, dynamic>?> decodeProjectZip(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      if (file.isFile && file.name == 'project.json') {
        final data = file.content as List<int>;
        final jsonStr = utf8.decode(data);
        return jsonDecode(jsonStr);
      }
    }
    return null;
  }

  @SquadronMethod()
  FutureOr<List<int>?> encodeProjectZip(Map<String, dynamic> projectJson) {
    final jsonStr = jsonEncode(projectJson);
    final bytes = utf8.encode(jsonStr);

    final archive = Archive();
    archive.addFile(ArchiveFile('project.json', bytes.length, bytes));
    return ZipEncoder().encode(archive);
  }
}
