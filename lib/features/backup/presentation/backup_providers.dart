import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/backup/backup_frequency.dart';
import '../../../core/backup/backup_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../data/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    ref.watch(databaseProvider),
    ref.watch(googleDriveServiceProvider),
  );
});

/// The signed-in Drive account, or null when signed out. Starts with
/// whatever GoogleDriveService already knows from the silent sign-in
/// done at startup (see lib/main.dart), then reacts to sign-in/out.
final driveAccountProvider = StreamProvider<GoogleSignInAccount?>((ref) async* {
  final service = ref.watch(googleDriveServiceProvider);
  yield service.currentAccount;
  yield* service.onAccountChanged;
});

/// Invalidated by the automatic-backup row after the user changes it.
final backupScheduleProvider = FutureProvider<BackupSchedule>((ref) {
  return ref.watch(preferencesRepositoryProvider).getBackupSchedule();
});
