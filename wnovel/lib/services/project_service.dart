import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
// Note: For web downloading, we need dart:html or url_launcher, but since we are targeting cross-platform,
// we can use a plugin like file_saver or just cross_file if possible.
// For now, let's implement basic export assuming desktop/mobile first, or just save to path.
// For now, let's implement basic export assuming desktop/mobile first.
import '../models/project.dart';

import 'worker/parser_service.dart';

class ProjectService {
  static Future<void> exportProject(Project project) async {
    try {
      await parserWorker.start();
      final zipData = await parserWorker.encodeProjectZip(project.toJson());

      if (zipData == null) return;

      if (!kIsWeb) {
        Uri? outputFile = await FilePicker.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: '${project.title}.wnovel',
          bytes: Uint8List.fromList(zipData),
        );

        if (outputFile != null && outputFile.scheme == 'file') {
          debugPrint("Project saved to $outputFile");
        }
      } else {
        debugPrint("Web export not fully implemented here without dart:html wrapper");
      }
    } catch (e) {
      debugPrint("Error exporting: $e");
    }
  }

  static Future<Project?> importProject({VoidCallback? onStartParsing}) async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wnovel', 'zip'],
      );

      if (result.isNotEmpty) {
        if (onStartParsing != null) onStartParsing();
        await Future.delayed(const Duration(milliseconds: 100));
        List<int> bytes = await result.first.readAsBytes();

        await parserWorker.start();
        final projectJson = await parserWorker.decodeProjectZip(bytes);
        if (projectJson != null) {
          return Project.fromJson(projectJson);
        }
      }
    } catch (e) {
      debugPrint("Error importing: $e");
    }
    return null;
  }
}
