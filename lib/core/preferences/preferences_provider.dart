import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_repository.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});

/// The user's display name, once onboarding has set it. Null until then.
final userNameProvider = FutureProvider<String?>((ref) {
  return ref.watch(preferencesRepositoryProvider).getName();
});

/// Overridden in main.dart with the stored value read at startup (same
/// pattern as notificationServiceProvider) so the whole app can watch it
/// reactively — Settings updates this and persists in the same action.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  throw UnimplementedError(
    'themeModeProvider must be overridden in main() with the stored theme.',
  );
});
