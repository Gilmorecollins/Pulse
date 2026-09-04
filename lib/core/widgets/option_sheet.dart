import 'package:flutter/material.dart';

/// One selectable choice in an [showOptionPicker] dialog.
class OptionChoice<T> {
  const OptionChoice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A rounded dialog with a title, a plain radio-row list, and a Cancel
/// button — modeled after WhatsApp's "Automatic backups" picker. Shared
/// by every Settings row that picks one of a small set of named options
/// (backup frequency, theme) so they all look and feel the same — see
/// lib/features/backup/presentation/backup_card.dart and
/// lib/features/settings/presentation/settings_screen.dart.
Future<T?> showOptionPicker<T>(
  BuildContext context, {
  required String title,
  required List<OptionChoice<T>> choices,
  required T current,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => _OptionDialog<T>(
      title: title,
      choices: choices,
      current: current,
    ),
  );
}

class _OptionDialog<T> extends StatelessWidget {
  const _OptionDialog({
    required this.title,
    required this.choices,
    required this.current,
  });

  final String title;
  final List<OptionChoice<T>> choices;
  final T current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            for (final choice in choices)
              _RadioRow<T>(
                choice: choice,
                selected: choice.value == current,
                onTap: () => Navigator.pop(context, choice.value),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  const _RadioRow({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final OptionChoice<T> choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(choice.label, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
