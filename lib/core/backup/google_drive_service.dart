import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'drive_backup_transport.dart';

/// Metadata about the backup file currently stored on Drive, for the
/// "a newer backup is available" indicator — never used to trigger an
/// automatic restore.
class DriveBackupMetadata {
  DriveBackupMetadata({required this.modifiedTime, required this.sizeBytes});

  final DateTime modifiedTime;
  final int sizeBytes;
}

/// Google Drive backup/restore for the local database file — see
/// docs/ARCHITECTURE.md's "Backup" section. Uses the Drive App Data
/// folder scope (hidden from the user's normal Drive UI, avoids the
/// OAuth-verification burden broader scopes trigger) and stores exactly
/// one file, found-or-created by name on each upload rather than
/// tracking a file id across app restarts.
///
/// One instance for the app's lifetime, silently signed in during
/// startup (see lib/main.dart) — mirrors NotificationService's
/// initialize-once-before-runApp pattern.
class GoogleDriveService implements DriveBackupTransport {
  GoogleDriveService()
      : _googleSignIn = GoogleSignIn(
          scopes: [drive.DriveApi.driveAppdataScope],
        );

  static const _backupFileName = 'pulse_backup.sqlite';

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  Stream<GoogleSignInAccount?> get onAccountChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// No prompt shown — a no-op if there's no previously-granted session.
  Future<void> initializeSilentSignIn() async {
    await _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _driveApi() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw StateError('Not signed in to Google Drive.');
    }
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Could not obtain an authenticated Drive client.');
    }
    return drive.DriveApi(client);
  }

  Future<drive.File?> _findBackupFile(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      $fields: 'files(id, name, modifiedTime, size)',
      q: "name = '$_backupFileName'",
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  /// Uploads [file]'s current bytes as the single backup, replacing
  /// whatever was there before. Callers are responsible for [file] being
  /// a consistent snapshot (see BackupRepository — VACUUM INTO, never a
  /// raw copy of the live database).
  @override
  Future<void> uploadBackup(File file) async {
    final api = await _driveApi();
    final existing = await _findBackupFile(api);
    final media = drive.Media(file.openRead(), await file.length());
    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      final metadata = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
      await api.files.create(metadata, uploadMedia: media);
    }
  }

  /// Downloads the backup to [destination], overwriting it. Throws a
  /// [StateError] if no backup exists yet on Drive.
  @override
  Future<File> downloadBackup(File destination) async {
    final api = await _driveApi();
    final existing = await _findBackupFile(api);
    if (existing == null) {
      throw StateError('No backup found on Drive.');
    }
    final media =
        await api.files.get(
              existing.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final sink = destination.openWrite();
    await sink.addStream(media.stream);
    await sink.close();
    return destination;
  }

  @override
  Future<DriveBackupMetadata?> getBackupMetadata() async {
    final api = await _driveApi();
    final existing = await _findBackupFile(api);
    if (existing == null) return null;
    return DriveBackupMetadata(
      modifiedTime: existing.modifiedTime ?? DateTime.now(),
      sizeBytes: int.tryParse(existing.size ?? '0') ?? 0,
    );
  }
}
