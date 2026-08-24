import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/project.dart';

// Provides the list of all projects (the library)
class LibraryNotifier extends StateNotifier<List<Project>> {
  LibraryNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box('app_state');
    final libraryJson = box.get('library');
    if (libraryJson != null) {
      final List decoded = jsonDecode(libraryJson);
      state = decoded.map((e) => Project.fromJson(e)).toList();
    }
  }

  Future<void> _saveToHive() async {
    final box = Hive.box('app_state');
    await box.put('library', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void addProject(Project project) {
    state = [...state, project];
    _saveToHive();
  }

  void updateProject(Project project) {
    state = state.map((p) => p.id == project.id ? project : p).toList();
    _saveToHive();
  }

  void deleteProject(String id) {
    state = state.where((p) => p.id != id).toList();
    _saveToHive();
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, List<Project>>((ref) {
  return LibraryNotifier();
});

// Provides the currently active project ID (if viewing a specific project)
final activeProjectIdProvider = StateProvider<String?>((ref) => null);

// A computed provider that yields the currently active Project
final activeProjectProvider = Provider<Project?>((ref) {
  final library = ref.watch(libraryProvider);
  final activeId = ref.watch(activeProjectIdProvider);
  
  if (activeId == null) return null;
  try {
    return library.firstWhere((p) => p.id == activeId);
  } catch (_) {
    return null;
  }
});
