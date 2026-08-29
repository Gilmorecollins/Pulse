import 'gemini_client.dart';

/// One task extracted from a free-text description of the day, before
/// the user has confirmed it — see docs/ARCHITECTURE.md's AI flow:
/// input → AI → structured response → user confirmation → database.
class ExtractedTask {
  ExtractedTask({required this.title, this.estimatedDurationMinutes});

  final String title;
  final int? estimatedDurationMinutes;
}

/// Feature-level AI operations, each a thin prompt over [GeminiClient].
/// Every method can throw [GeminiNotConfiguredException] or
/// [GeminiRequestException] — callers are expected to catch both and fall
/// back to the equivalent non-AI behavior, never block on them.
class GeminiService {
  GeminiService(this._client);

  final GeminiClient _client;

  Future<List<ExtractedTask>> extractTasks(String text) async {
    final json = await _client.generateJson(
      prompt:
          '''You help split a free-text description of a day's plan into a
list of concrete, actionable tasks. Each task title should be short,
specific, and start with a verb. Only include tasks the user actually
described — never invent extra ones. If a duration is clearly implied
(e.g. "spend two hours on X"), include estimatedDurationMinutes; omit it
otherwise.

Text: "${text.trim()}"''',
      responseSchema: const {
        'type': 'OBJECT',
        'properties': {
          'tasks': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'title': {'type': 'STRING'},
                'estimatedDurationMinutes': {'type': 'INTEGER'},
              },
              'required': ['title'],
            },
          },
        },
        'required': ['tasks'],
      },
    );

    final tasks = json['tasks'] as List<dynamic>? ?? [];
    return tasks
        .map(
          (t) => ExtractedTask(
            title: t['title'] as String,
            estimatedDurationMinutes: t['estimatedDurationMinutes'] as int?,
          ),
        )
        .where((t) => t.title.trim().isNotEmpty)
        .toList();
  }

  /// Cleans up a short free-text account of something the user just did
  /// (logged during a check-in) into a clear title — corrects grammar and
  /// tightens phrasing, but never adds detail the user didn't state.
  Future<String> interpretActivity(String text) async {
    final json = await _client.generateJson(
      prompt:
          '''Rewrite the following into a short, clear activity title (like
a to-do item written in past tense), fixing grammar and trimming filler
words. Do not add any information that isn't in the original text.

Text: "${text.trim()}"''',
      responseSchema: const {
        'type': 'OBJECT',
        'properties': {
          'title': {'type': 'STRING'},
        },
        'required': ['title'],
      },
    );

    final title = (json['title'] as String?)?.trim();
    return (title == null || title.isEmpty) ? text.trim() : title;
  }

  /// A short, honest, second-person summary of the day — grounded only in
  /// what's passed in, never fabricated. Labeled as AI-generated wherever
  /// it's shown (see docs/PRODUCT.md's stance against overclaiming).
  Future<String> summarizeDay({
    required List<String> completedTasks,
    required List<String> notCompletedTasks,
    required List<String> activities,
    required String mood,
    String? biggestWin,
    String? carryForward,
  }) async {
    final json = await _client.generateJson(
      prompt:
          '''Write a short (2-3 sentence), honest, second-person summary of
this person's day, based only on the facts below. Don't invent anything
not listed. Be warm but grounded, not falsely upbeat if the day was
difficult.

Completed tasks: ${completedTasks.isEmpty ? 'none' : completedTasks.join(', ')}
Not completed: ${notCompletedTasks.isEmpty ? 'none' : notCompletedTasks.join(', ')}
Other things logged during the day: ${activities.isEmpty ? 'none' : activities.join(', ')}
Mood: $mood
Biggest win: ${biggestWin ?? 'not stated'}
Carried forward to tomorrow: ${carryForward ?? 'not stated'}''',
      responseSchema: const {
        'type': 'OBJECT',
        'properties': {
          'summary': {'type': 'STRING'},
        },
        'required': ['summary'],
      },
    );

    return (json['summary'] as String).trim();
  }
}
