import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/backup/backup_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/preferences/preferences_provider.dart';
import 'backup_providers.dart';

/// Google Drive backup/restore section for Settings — see
/// docs/ARCHITECTURE.md's "Backup" section. Manual only (no continuous
/// background sync, no auto-restore): one person, one device at a time,
/// so there's no conflict to resolve, and a silent restore would be
/// destructive without the user asking for it.
class BackupCard extends StatelessWidget {
  const BackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          _DriveAccountRow(),
          Divider(height: 1),
          _BackupNowRow(),
          Divider(height: 1),
          _RestoreRow(),
        ],
      ),
    );
  }
}

class _DriveAccountRow extends ConsumerStatefulWidget {
  const _DriveAccountRow();

  @override
  ConsumerState<_DriveAccountRow> createState() => _DriveAccountRowState();
}

class _DriveAccountRowState extends ConsumerState<_DriveAccountRow> {
  bool _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      await ref.read(googleDriveServiceProvider).signIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await ref.read(googleDriveServiceProvider).signOut();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(driveAccountProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Google Drive'),
                Text(
                  account?.email ?? 'Not connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: account == null ? _connect : _disconnect,
                  child: Text(account == null ? 'Connect' : 'Disconnect'),
                ),
        ],
      ),
    );
  }
}

class _BackupNowRow extends ConsumerStatefulWidget {
  const _BackupNowRow();

  @override
  ConsumerState<_BackupNowRow> createState() => _BackupNowRowState();
}

class _BackupNowRowState extends ConsumerState<_BackupNowRow> {
  bool _busy = false;

  Future<void> _backUp() async {
    setState(() => _busy = true);
    try {
      await ref.read(backupRepositoryProvider).backUpNow();
      await ref
          .read(preferencesRepositoryProvider)
          .setLastSyncedAt(DateTime.now());
      ref.invalidate(lastSyncedAtProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(driveAccountProvider).valueOrNull != null;
    final lastSynced = ref.watch(lastSyncedAtProvider).valueOrNull;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.cloud_upload_outlined),
      title: const Text('Back up now'),
      subtitle: Text(
        lastSynced == null
            ? 'Never backed up'
            : 'Last synced ${DateFormat('d MMM, HH:mm').format(lastSynced)}',
      ),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      enabled: signedIn,
      onTap: (!signedIn || _busy) ? null : _backUp,
    );
  }
}

class _RestoreRow extends ConsumerStatefulWidget {
  const _RestoreRow();

  @override
  ConsumerState<_RestoreRow> createState() => _RestoreRowState();
}

class _RestoreRowState extends ConsumerState<_RestoreRow> {
  bool _busy = false;

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text(
          'This replaces everything on this device with the backup from '
          'Drive. Your current data is saved as a local backup file '
          'first, but anything added since the last backup will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final downloaded = await ref
          .read(backupRepositoryProvider)
          .fetchRemoteBackup();
      await _assertValidSqlite(downloaded);

      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'pulse.sqlite'));
      if (await dbFile.exists()) {
        await dbFile.copy(p.join(dir.path, 'pulse.sqlite.bak'));
      }

      // Close the live connection before replacing the file it holds
      // open — a hot-swap via provider invalidation would also need
      // every screen's live stream (Today/Week/etc.) to gracefully
      // survive the underlying db closing mid-watch, which isn't worth
      // the risk for a rare, explicitly-confirmed destructive action.
      // Simpler and safer: replace the file, then ask for a restart.
      await ref.read(databaseProvider).close();
      await downloaded.copy(dbFile.path);
      await ref
          .read(preferencesRepositoryProvider)
          .setLastSyncedAt(DateTime.now());

      if (mounted) {
        setState(() => _busy = false);
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Restore complete'),
            content: const Text(
              'Close and reopen Pulse to see your restored data.',
            ),
            actions: [
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Close app'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  Future<void> _assertValidSqlite(File file) async {
    final raf = await file.open();
    try {
      final header = await raf.read(16);
      final text = String.fromCharCodes(header.take(15));
      if (text != 'SQLite format 3') {
        throw const FormatException(
          'Downloaded file is not a valid Pulse backup.',
        );
      }
    } finally {
      await raf.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(driveAccountProvider).valueOrNull != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.cloud_download_outlined),
      title: const Text('Restore from Drive'),
      subtitle: const Text('Overwrites everything on this device'),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      enabled: signedIn,
      onTap: (!signedIn || _busy) ? null : _restore,
    );
  }
}
