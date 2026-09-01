import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/core/backup/drive_backup_transport.dart';
import 'package:pulse/core/backup/google_drive_service.dart';
import 'package:pulse/core/database/database.dart';
import 'package:pulse/features/backup/data/backup_repository.dart';
import 'package:pulse/features/today/data/today_repository.dart';

/// In-memory stand-in for GoogleDriveService — lets BackupRepository be
/// exercised without real Google auth/network. See
/// core/backup/drive_backup_transport.dart.
class FakeDriveBackupTransport implements DriveBackupTransport {
  Uint8List? _bytes;

  @override
  Future<void> uploadBackup(File file) async {
    _bytes = await file.readAsBytes();
  }

  @override
  Future<File> downloadBackup(File destination) async {
    final bytes = _bytes;
    if (bytes == null) {
      throw StateError('No backup found on Drive.');
    }
    await destination.writeAsBytes(bytes);
    return destination;
  }

  @override
  Future<DriveBackupMetadata?> getBackupMetadata() async {
    final bytes = _bytes;
    if (bytes == null) return null;
    return DriveBackupMetadata(
      modifiedTime: DateTime.now(),
      sizeBytes: bytes.length,
    );
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late Directory tempDir;
  late PulseDatabase db;
  late TodayRepository today;
  late FakeDriveBackupTransport transport;
  late BackupRepository backup;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pulse_backup_test');
    db = PulseDatabase.forTesting(NativeDatabase.memory());
    today = TodayRepository(db);
    transport = FakeDriveBackupTransport();
    backup = BackupRepository(
      db,
      transport,
      tempDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('backUpNow uploads a valid SQLite snapshot via VACUUM INTO', () async {
    final plan = await today.getOrCreateTodayPlan();
    await today.addTask(dailyPlanId: plan.id, title: 'Seed task');

    await backup.backUpNow();

    final info = await backup.remoteBackupInfo();
    expect(info, isNotNull);
    expect(info!.sizeBytes, greaterThan(0));
  });

  test('a snapshot -> restore round-trip preserves row counts', () async {
    final plan = await today.getOrCreateTodayPlan();
    await today.addTask(dailyPlanId: plan.id, title: 'Task one');
    await today.addTask(dailyPlanId: plan.id, title: 'Task two');

    await backup.backUpNow();
    final downloaded = await backup.fetchRemoteBackup();

    final restoredDb = PulseDatabase.forTesting(
      NativeDatabase(downloaded, logStatements: false),
    );
    final restoredTasks = await restoredDb.select(restoredDb.tasks).get();
    expect(restoredTasks, hasLength(2));
    expect(
      restoredTasks.map((t) => t.title),
      containsAll(['Task one', 'Task two']),
    );
    await restoredDb.close();
  });

  test('fetchRemoteBackup throws when nothing has been backed up yet', () async {
    expect(backup.fetchRemoteBackup(), throwsStateError);
  });
}
