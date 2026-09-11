import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';

class SuggestionResult {
  SuggestionResult({
    required this.techniqueName,
    required this.description,
    required this.steps,
    required this.showCrisisResources,
  });

  final String techniqueName;
  final String description;
  final List<String> steps;
  final bool showCrisisResources;

  factory SuggestionResult.fromJson(Map<String, dynamic> json) => SuggestionResult(
        techniqueName: json['technique_name'] as String,
        description: json['description'] as String,
        steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
        showCrisisResources: json['show_crisis_resources'] as bool,
      );
}

class SuggestionService {
  SuggestionService(this._client);
  final SupabaseClient _client;

  Future<SuggestionResult> generateSuggestion({
    required String moodLogId,
    required String userId,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'generate-suggestion',
        body: {'mood_log_id': moodLogId, 'user_id': userId},
      );
      final data = res.data as Map<String, dynamic>;
      return SuggestionResult.fromJson(data);
    } on FunctionException catch (_) {
      throw const AppException('Could not generate a suggestion. Please try again.');
    }
  }
}
