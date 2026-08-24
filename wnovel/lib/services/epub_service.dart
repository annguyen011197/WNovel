
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';

import 'worker/parser_service.dart';

class EpubService {
  static Future<Project?> importEpub({VoidCallback? onStartParsing}) async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result.isNotEmpty) {
        if (onStartParsing != null) onStartParsing();
        await Future.delayed(const Duration(milliseconds: 100));
        List<int> bytes = await result.first.readAsBytes();
        String title = result.first.name;

        await parserWorker.start();
        final projectJson = await parserWorker.parseEpub(bytes, title);
        return Project.fromJson(projectJson);
      }
    } catch (e) {
      debugPrint("Error importing EPUB: $e");
    }
    return null;
  }
}
