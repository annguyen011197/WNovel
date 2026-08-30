enum ChapterStatus {
  pending,
  translating,
  done;

  String toJson() => name;

  static ChapterStatus fromJson(String? value) {
    switch (value) {
      case 'translating':
        return ChapterStatus.translating;
      case 'done':
        return ChapterStatus.done;
      default:
        return ChapterStatus.pending;
    }
  }
}

class Chapter {
  final String id;
  final String title;
  String translatedTitle;
  final String originalText;
  String translatedText;
  String summary;
  ChapterStatus status;
  bool skipTranslation;

  Chapter({
    required this.id,
    required this.title,
    required this.originalText,
    this.translatedTitle = '',
    this.translatedText = '',
    this.summary = '',
    this.status = ChapterStatus.pending,
    this.skipTranslation = false,
  });

  Chapter copyWith({
    String? id,
    String? title,
    String? originalText,
    String? translatedTitle,
    String? translatedText,
    String? summary,
    ChapterStatus? status,
    bool? skipTranslation,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedText: translatedText ?? this.translatedText,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      skipTranslation: skipTranslation ?? this.skipTranslation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'originalText': originalText,
    'translatedTitle': translatedTitle,
    'translatedText': translatedText,
    'summary': summary,
    'status': status.toJson(),
    'skipTranslation': skipTranslation,
  };

  factory Chapter.fromJson(Map<dynamic, dynamic> json) => Chapter(
    id: json['id'],
    title: json['title'],
    originalText: json['originalText'],
    translatedTitle: json['translatedTitle'] ?? '',
    translatedText: json['translatedText'] ?? '',
    summary: json['summary'] ?? '',
    status: ChapterStatus.fromJson(json['status']),
    skipTranslation: json['skipTranslation'] ?? false,
  );
}

class Character {
  final String id;
  String originalName;
  String translatedName;
  String description;

  Character({
    required this.id,
    required this.originalName,
    required this.translatedName,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalName': originalName,
    'translatedName': translatedName,
    'description': description,
  };

  factory Character.fromJson(Map<dynamic, dynamic> json) => Character(
    id: json['id'],
    originalName: json['originalName'],
    translatedName: json['translatedName'],
    description: json['description'],
  );
}

class Relation {
  final String id;
  String charA;
  String charB;
  String relationship;

  Relation({
    required this.id,
    required this.charA,
    required this.charB,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'charA': charA,
    'charB': charB,
    'relationship': relationship,
  };

  factory Relation.fromJson(Map<dynamic, dynamic> json) => Relation(
    id: json['id'],
    charA: json['charA'],
    charB: json['charB'],
    relationship: json['relationship'],
  );
}

class Project {
  final String id;
  String title;
  String author;
  String? coverUrl;
  String targetLanguage;
  List<Chapter> chapters;
  List<Character> characters;
  List<Relation> relations;

  Project({
    required this.id,
    this.title = 'Untitled Draft',
    this.author = 'Unknown Author',
    this.coverUrl,
    this.targetLanguage = 'Vietnamese',
    this.chapters = const [],
    this.characters = const [],
    this.relations = const [],
  });

  Project copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? targetLanguage,
    List<Chapter>? chapters,
    List<Character>? characters,
    List<Relation>? relations,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      chapters: chapters ?? this.chapters,
      characters: characters ?? this.characters,
      relations: relations ?? this.relations,
    );
  }

  double get progress {
    if (chapters.isEmpty) return 0.0;
    int completed = chapters
        .where((c) => c.status == ChapterStatus.done || c.skipTranslation)
        .length;
    return completed / chapters.length;
  }

  String get status {
    if (chapters.isEmpty) return 'DRAFT';
    if (progress == 1.0) return 'COMPLETED';
    if (progress > 0.0) return 'IN PROGRESS';
    return 'DRAFT';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'targetLanguage': targetLanguage,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'characters': characters.map((c) => c.toJson()).toList(),
    'relations': relations.map((r) => r.toJson()).toList(),
  };

  factory Project.fromJson(Map<dynamic, dynamic> json) => Project(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] ?? 'Untitled Draft',
    author: json['author'] ?? 'Unknown Author',
    coverUrl: json['coverUrl'],
    targetLanguage: json['targetLanguage'] ?? 'Vietnamese',
    chapters:
        (json['chapters'] as List?)?.map((c) => Chapter.fromJson(c)).toList() ??
        [],
    characters:
        (json['characters'] as List?)
            ?.map((c) => Character.fromJson(c))
            .toList() ??
        [],
    relations:
        (json['relations'] as List?)
            ?.map((r) => Relation.fromJson(r))
            .toList() ??
        [],
  );
}
