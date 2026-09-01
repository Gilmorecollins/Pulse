import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/backup/drive_backup_transport.dart';
import '../../../core/backup/google_drive_service.dart';
import '../../../core/database/database.dart';

/// Backs up and restores the local database file via Google Drive. See
/// docs/ARCHITECTURE.md's "Backup" section for the design: whole-file
/// snapshots (not per-table export), so this stays correct across future
/// schema changes with no code changes here. Depends on the
/// DriveBackupTransport interface, not GoogleDriveService directly, so
/// tests can exercise it against a fake instead of real Google auth.
class BackupRepository {
  BackupRepository(
    this._db,
    this._driveService, {
    Future<Directory> Function()? tempDirectoryProvider,
  }) : _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory;

  final PulseDatabase _db;
  final DriveBackupTransport _driveService;
  // Overridable in tests — the real path_provider platform channel isn't
  // available under plain `flutter_test`.
  final Future<Directory> Function() _tempDirectoryProvider;

  /// Snapshots the live database via `VACUUM INTO` (atomic, consistent —
  /// never a raw copy of a file that may be mid-write) and uploads it.
  Future<void> backUpNow() async {
    final tempDir = await _tempDirectoryProvider();
    final snapshotFile = File(
      p.join(tempDir.path, 'pulse_backup_snapshot.sqlite'),
    );
    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }

    await _db.customStatement("VACUUM INTO '${snapshotFile.path}'");

    try {
      await _driveService.uploadBackup(snapshotFile);
    } finally {
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
    }
  }

  /// Downloads the remote backup to a temp file. Callers own deciding
  /// whether/how to apply it to the live database (see _RestoreRow in
  /// backup_card.dart) — this method never touches the live db file.
  Future<File> fetchRemoteBackup() async {
    final tempDir = await _tempDirectoryProvider();
    final destination = File(
      p.join(tempDir.path, 'pulse_backup_downloaded.sqlite'),
    );
    return _driveService.downloadBackup(destination);
  }

  Future<DriveBackupMetadata?> remoteBackupInfo() =>
      _driveService.getBackupMetadata();
}
