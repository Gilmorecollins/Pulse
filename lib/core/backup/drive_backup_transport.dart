import 'dart:io';

import 'google_drive_service.dart';

/// The subset of GoogleDriveService that BackupRepository actually needs
/// — pulled out as an interface so tests can exercise BackupRepository
/// (snapshot → upload, download → restore) against a fake instead of
/// real Google auth/network. GoogleDriveService implements this
/// directly; nothing else needs to.
abstract class DriveBackupTransport {
  Future<void> uploadBackup(File file);
  Future<File> downloadBackup(File destination);
  Future<DriveBackupMetadata?> getBackupMetadata();
}
