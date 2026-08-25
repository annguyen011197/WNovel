import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketbase/pocketbase.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late PocketBase pb;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    final url = dotenv.env['PB_URL'] ?? 'http://127.0.0.1:8090';
    pb = PocketBase(url);
  }

  Future<RecordAuth> login(String email, String password) async {
    return await pb.collection('users').authWithPassword(email, password);
  }

  Future<RecordModel> signUp(String email, String password) async {
    final body = <String, dynamic>{
      "email": email,
      "password": password,
      "passwordConfirm": password,
    };
    final record = await pb.collection('users').create(body: body);
    // Automatically login after successful sign up
    await login(email, password);
    return record;
  }

  void logout() {
    pb.authStore.clear();
  }

  bool get isAuthenticated => pb.authStore.isValid;
  String? get currentUserId => pb.authStore.model?.id;

  Future<Map<String, dynamic>> translateChapter(
    String rawText,
    List<Map<String, dynamic>> glossary,
    List<String> previousSummaries,
  ) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated.');
    }

    final body = {
      'rawText': rawText,
      'glossary': glossary,
      'previousSummaries': previousSummaries,
      'provider':
          'gemini', // or openrouter, depending on settings, hardcoded for now
    };

    final result = await pb.send('/api/translate', method: 'POST', body: body);

    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> translateOnly(String rawText) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated.');
    }

    // Call the translation API without previous context
    final body = {
      'rawText': rawText,
      'glossary': [], // Empty glossary
      'previousSummaries': [], // Empty previous summaries
      'provider': 'gemini', // or openrouter
      'translateOnly':
          true, // Optional flag if the backend wants to handle it differently
    };

    final result = await pb.send('/api/translate', method: 'POST', body: body);

    return result as Map<String, dynamic>;
  }
}
