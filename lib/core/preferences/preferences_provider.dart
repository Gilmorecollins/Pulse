import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_repository.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});

/// The user's display name, once onboarding has set it. Null until then.
final userNameProvider = FutureProvider<String?>((ref) {
  return ref.watch(preferencesRepositoryProvider).getName();
});
