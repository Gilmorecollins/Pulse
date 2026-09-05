import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../backup/presentation/backup_card.dart';
import '../../backup/presentation/backup_providers.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../checkin/presentation/checkin_scheduling.dart';
import '../../today/presentation/today_providers.dart';
import 'profile_providers.dart';

/// Styled after the user's own settings mockup (rounded profile card,
/// gray section labels, icon + label + trailing control/value row
/// pattern) — but only the rows that map to something Pulse actually
/// has. The mockup's account/email, "PRO" badge, and language/region
/// rows are dropped rather than shipped as decoration: Pulse has no
/// subscription and no i18n (see docs/PRODUCT.md — never imply a
/// capability that doesn't exist). "Cloud sync" is the one row the
/// mockup had that Pulse eventually did add for real — see the Backup
/// section — but scoped to the user's own Google Drive App Data folder
/// for backup/restore, never a Pulse-owned account or backend.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _ProfileCard(),
            SizedBox(height: 28),
            _SectionLabel('Preferences'),
            SizedBox(height: 8),
            _PreferencesCard(),
            SizedBox(height: 28),
            _SectionLabel('Backup'),
            SizedBox(height: 8),
            BackupCard(),
            SizedBox(height: 28),
            _SectionLabel('General'),
            SizedBox(height: 8),
            _GeneralCard(),
            SizedBox(height: 28),
            _SectionLabel('Privacy'),
            SizedBox(height: 8),
            _PrivacyCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final photo = await ref.read(profilePhotoProvider.future);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ProfileEditSheet(name: name, photo: photo),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider).valueOrNull ?? '';
    final photo = ref.watch(profilePhotoProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditSheet(context, ref, name),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              CircleAvatar(
                radius: 40,
                backgroundColor: scheme.secondaryContainer,
                backgroundImage: photo != null ? FileImage(photo) : null,
                child: photo == null
                    ? Text(
                        _initialsFor(name.isEmpty ? '?' : name),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                name.isEmpty ? 'Add your name' : name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LOCAL',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({required this.name, required this.photo});

  final String name;
  final File? photo;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final _controller = TextEditingController(text: widget.name);
  File? _pickedPhoto;
  bool _removePhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  File? get _displayedPhoto => _removePhoto ? null : (_pickedPhoto ?? widget.photo);

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickedPhoto = File(picked.path);
      _removePhoto = false;
    });
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    await ref.read(preferencesRepositoryProvider).setName(name);
    if (_pickedPhoto != null) {
      await ref.read(profilePhotoRepositoryProvider).setPhoto(_pickedPhoto!);
    } else if (_removePhoto) {
      await ref.read(profilePhotoRepositoryProvider).clearPhoto();
    }
    ref.invalidate(userNameProvider);
    ref.invalidate(profilePhotoProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = _displayedPhoto;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.secondaryContainer,
                    backgroundImage: photo != null ? FileImage(photo) : null,
                    child: photo == null
                        ? Text(
                            _initialsFor(widget.name.isEmpty ? '?' : widget.name),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surfaceContainerHigh, width: 2),
                      ),
                      child: Icon(Icons.camera_alt, size: 16, color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (photo != null)
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _pickedPhoto = null;
                  _removePhoto = true;
                }),
                child: const Text('Remove photo'),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: widget.name.isEmpty,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          _ThemeRow(),
          Divider(height: 1),
          _NotificationsRow(),
          Divider(height: 1),
          _ReportTimeRow(),
        ],
      ),
    );
  }
}

const _themeChoices = [
  OptionChoice(value: ThemeMode.system, label: 'Auto'),
  OptionChoice(value: ThemeMode.light, label: 'Light'),
  OptionChoice(value: ThemeMode.dark, label: 'Dark'),
];

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  String _subtitleFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Auto',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final chosen = await showOptionPicker<ThemeMode>(
      context,
      title: 'Theme',
      choices: _themeChoices,
      current: current,
    );
    if (chosen == null) return;

    ref.read(themeModeProvider.notifier).state = chosen;
    await ref.read(preferencesRepositoryProvider).setThemeMode(chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.dark_mode_outlined),
      title: const Text('Theme'),
      subtitle: Text(_subtitleFor(mode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openPicker(context, ref),
    );
  }
}

class _NotificationsRow extends ConsumerStatefulWidget {
  const _NotificationsRow();

  @override
  ConsumerState<_NotificationsRow> createState() => _NotificationsRowState();
}

class _NotificationsRowState extends ConsumerState<_NotificationsRow> {
  bool? _enabled;
  bool _busy = false;

  Future<void> _setEnabled(bool enabled) async {
    setState(() {
      _enabled = enabled;
      _busy = true;
    });

    final prefs = ref.read(preferencesRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);
    await prefs.setNotificationsEnabled(enabled);

    if (enabled) {
      final reportTime = await prefs.getReportTime();
      if (reportTime != null) {
        await notifications.scheduleDailyReflection(reportTime);
      }
      final today = ref.read(todayRepositoryProvider);
      for (final task in await today.getTasksWithPendingCheckIn()) {
        final time = task.expectedCompletionTime;
        if (time == null) continue;
        await scheduleTaskCheckIn(
          ref,
          taskId: task.id,
          taskTitle: task.title,
          dailyPlanId: task.dailyPlanId,
          completionTime: time,
        );
      }
    } else {
      await notifications.cancelReflection();
      final today = ref.read(todayRepositoryProvider);
      final checkIns = ref.read(checkInRepositoryProvider);
      for (final task in await today.getTasksWithPendingCheckIn()) {
        await notifications.cancelTaskCheckIn(task.id);
        await checkIns.skipPendingCheckIn(task.id);
      }
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ref.read(preferencesRepositoryProvider).getNotificationsEnabled(),
      builder: (context, snapshot) {
        final enabled = _enabled ?? snapshot.data ?? true;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined),
              const SizedBox(width: 16),
              const Expanded(child: Text('Notifications')),
              Switch(
                value: enabled,
                onChanged: _busy ? null : _setEnabled,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportTimeRow extends ConsumerStatefulWidget {
  const _ReportTimeRow();

  @override
  ConsumerState<_ReportTimeRow> createState() => _ReportTimeRowState();
}

class _ReportTimeRowState extends ConsumerState<_ReportTimeRow> {
  TimeOfDay? _time;
  bool _saving = false;

  Future<void> _pickAndSave() async {
    final current = _time ??
        await ref.read(preferencesRepositoryProvider).getReportTime() ??
        const TimeOfDay(hour: 20, minute: 0);
    if (!mounted) return;

    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;

    setState(() {
      _time = picked;
      _saving = true;
    });
    await ref.read(preferencesRepositoryProvider).setReportTime(picked);
    await ref.read(notificationServiceProvider).scheduleDailyReflection(picked);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TimeOfDay?>(
      future: ref.read(preferencesRepositoryProvider).getReportTime(),
      builder: (context, snapshot) {
        final time = _time ?? snapshot.data;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: const Icon(Icons.nightlight_round),
          title: const Text('Daily report time'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time == null ? 'Not set' : time.format(context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
              _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
            ],
          ),
          onTap: _saving ? null : _pickAndSave,
        );
      },
    );
  }
}

class _GeneralCard extends StatelessWidget {
  const _GeneralCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          _StorageRow(),
          Divider(height: 1),
          _AboutRow(),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow();

  Future<String> _dbSize() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulse.sqlite'));
    if (!await file.exists()) return '0 KB';
    final bytes = await file.length();
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _dbSize(),
      builder: (context, snapshot) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Storage'),
          trailing: Text(
            snapshot.data ?? '—',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          trailing: Text(version == null ? '—' : 'v$version'),
        );
      },
    );
  }
}

class _PrivacyCard extends ConsumerWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(driveAccountProvider).valueOrNull != null;
    final text = connected
        ? 'Everything lives on this device by default. The only thing '
              'that leaves it is a backup you trigger yourself, sent to '
              'your own Google Drive — Pulse has no accounts or backend '
              'of its own, and nothing else is shared unless you choose '
              'to send a report.'
        : 'Everything stays on this device — no accounts, no cloud, '
              'nothing sent anywhere except when you choose to share a '
              'report or turn on Drive backup.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
