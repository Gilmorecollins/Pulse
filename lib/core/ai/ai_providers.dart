import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_key_repository.dart';
import 'gemini_client.dart';
import 'gemini_service.dart';

final aiKeyRepositoryProvider = Provider<AiKeyRepository>((ref) {
  return AiKeyRepository();
});

/// Whether an API key is currently stored. Watched by screens that only
/// show AI affordances once Gemini is actually configured — no dangling
/// buttons that fail the moment they're tapped.
final hasAiKeyProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(aiKeyRepositoryProvider).getKey();
  return key != null && key.isNotEmpty;
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(GeminiClient(ref.watch(aiKeyRepositoryProvider)));
});
