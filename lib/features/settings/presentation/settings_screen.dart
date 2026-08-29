import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ai/ai_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('AI', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            const _GeminiKeyCard(),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'More settings coming soon',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile, check-in frequency, and quiet hours will '
                      'live here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeminiKeyCard extends ConsumerStatefulWidget {
  const _GeminiKeyCard();

  @override
  ConsumerState<_GeminiKeyCard> createState() => _GeminiKeyCardState();
}

class _GeminiKeyCardState extends ConsumerState<_GeminiKeyCard> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(aiKeyRepositoryProvider).setKey(_controller.text);
    ref.invalidate(hasAiKeyProvider);
    _controller.clear();
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini key saved')),
      );
    }
  }

  Future<void> _clear() async {
    await ref.read(aiKeyRepositoryProvider).clearKey();
    ref.invalidate(hasAiKeyProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini key removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKeyAsync = ref.watch(hasAiKeyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Gemini API key', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Powers AI task splitting, activity clean-up, and daily '
              'summaries. Stored securely on this device only — never sent '
              'anywhere except directly to Google.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            hasKeyAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not check key status'),
              data: (hasKey) {
                if (hasKey && !_editing) {
                  return Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Gemini is configured')),
                      TextButton(
                        onPressed: () => setState(() => _editing = true),
                        child: const Text('Change'),
                      ),
                      TextButton(onPressed: _clear, child: const Text('Remove')),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Paste your Gemini API key',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                        if (hasKey) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() => _editing = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Get a free key from Google AI Studio'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
