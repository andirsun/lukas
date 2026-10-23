import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/server_url.dart';
import '../api/session.dart';
import '../capture/models_download.dart';
import '../feedback/feedback.dart';
import '../home/toast.dart';
import '../l10n/app_localizations.dart';
import '../progress/guest_warning.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'preferences.dart';
import 'url_opener.dart';

/// Whether a voice model is downloaded (so there is something to delete).
final voiceModelsInstalledProvider = FutureProvider.autoDispose<bool>((ref) async {
  final models = ref.watch(modelStoreProvider);
  for (final locale in voiceModels.keys) {
    if (await models.installedPath(locale) != null) return true;
  }
  return false;
});

/// Settings (spec section 6.1.6): language, theme, sound, vibration, the two local notices, hiding
/// the amount in the widget, the voice models, the server, About, "Más en la web" and sign out.
/// A guest also finds "Guarda tu progreso" at the top, and is warned before anything that would
/// leave their account behind (signing out, changing server).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Signing out or changing server is under way (the old server is told, if it answers).
  bool _busy = false;

  LukitasColors get _colors => Theme.of(context).extension<LukitasTheme>()!.colors;

  void _toast(String message, {bool error = false}) =>
      showToast(ScaffoldMessenger.of(context), _colors, message, error: error);

  // -- sign out ------------------------------------------------------------------------------

  Future<void> _signOut() async {
    final session = ref.read(sessionProvider.notifier);
    if (ref.read(sessionProvider).isGuest) {
      final choice = await warnGuestLeaving(context, GuestLeaving.signOut);
      if (!mounted || choice == null) return;
      if (choice == GuestWarning.saveInstead) {
        unawaited(context.push('/progress'));
        return;
      }
    }
    setState(() => _busy = true);
    try {
      await session.signOut(discardGuest: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -- server --------------------------------------------------------------------------------

  Future<void> _changeServer() async {
    final next = await showDialog<Uri>(
      context: context,
      builder: (context) => _ServerDialog(current: ref.read(serverUrlProvider)),
    );
    if (!mounted || next == null) return;
    if (ref.read(sessionProvider).isGuest && next != ref.read(serverUrlProvider)) {
      final choice = await warnGuestLeaving(context, GuestLeaving.changeServer);
      if (!mounted || choice == null) return;
      if (choice == GuestWarning.saveInstead) {
        unawaited(context.push('/progress'));
        return;
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = _colors;
    setState(() => _busy = true);
    try {
      final changed = await ref.read(serverUrlProvider.notifier).change(next.toString());
      if (changed) {
        showToast(messenger, colors, l10n.settingsServerChanged(next.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -- the rest ------------------------------------------------------------------------------

  Future<void> _openWeb() async {
    final l10n = AppLocalizations.of(context);
    final opened = await ref.read(urlOpenerProvider).open(ref.read(serverUrlProvider));
    if (!opened && mounted) _toast(l10n.settingsWebFailed, error: true);
  }

  Future<void> _deleteVoice() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteVoiceTitle),
        content: Text(l10n.settingsDeleteVoiceBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('settings.deleteVoice.confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsDeleteVoiceConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(modelStoreProvider).deleteModels();
      if (mounted) _toast(l10n.settingsDeleteVoiceDone);
    } on Object {
      if (mounted) _toast(l10n.settingsDeleteVoiceFailed, error: true);
    }
    ref.invalidate(voiceModelsInstalledProvider);
  }

  // -- build ---------------------------------------------------------------------------------

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      LukitasTokens.space4,
      LukitasTokens.space5,
      LukitasTokens.space4,
      LukitasTokens.space1,
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _colors.brand),
    ),
  );

  Widget _switch(String key, String title, String hint, StoredFlagProvider provider) {
    final on = ref.watch(provider);
    return SwitchListTile(
      key: Key(key),
      title: Text(title),
      subtitle: Text(hint),
      value: on,
      onChanged: (value) => unawaited(ref.read(provider.notifier).set(value)),
    );
  }

  Widget _choice<T>({
    required String title,
    required String hint,
    required T selected,
    required List<ButtonSegment<T>> segments,
    required void Function(T) onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: LukitasTokens.space4,
      vertical: LukitasTokens.space2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: LukitasTokens.space2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: segments,
            selected: {selected},
            onSelectionChanged: (values) => onChanged(values.first),
          ),
        ),
        const SizedBox(height: LukitasTokens.space1),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final guest = ref.watch(sessionProvider.select((s) => s.isGuest));
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeOverrideProvider);
    final server = ref.watch(serverUrlProvider);
    final voiceInstalled = ref.watch(voiceModelsInstalledProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                if (_busy) const LinearProgressIndicator(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: LukitasTokens.space6),
                    children: [
                      if (guest) ...[
                        _heading(l10n.settingsAccount),
                        ListTile(
                          key: const Key('settings.saveProgress'),
                          leading: Icon(Icons.bookmark_add_outlined, color: _colors.brand),
                          title: Text(l10n.progressTitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(l10n.settingsGuestAccount), Text(l10n.progressLead)],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/progress'),
                        ),
                      ],
                      _heading(l10n.settingsPreferences),
                      _choice<ThemeMode>(
                        title: l10n.settingsTheme,
                        hint: l10n.settingsThemeHint,
                        selected: themeMode,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(
                              l10n.settingsThemeAuto,
                              key: const Key('settings.theme.auto'),
                            ),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(
                              l10n.settingsThemeDay,
                              key: const Key('settings.theme.day'),
                            ),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(
                              l10n.settingsThemeNight,
                              key: const Key('settings.theme.night'),
                            ),
                          ),
                        ],
                        onChanged: (mode) =>
                            unawaited(ref.read(themeModeProvider.notifier).set(mode)),
                      ),
                      _choice<String>(
                        title: l10n.settingsLanguage,
                        hint: l10n.settingsLanguageHint,
                        selected: locale?.languageCode ?? 'auto',
                        segments: [
                          ButtonSegment(
                            value: 'auto',
                            label: Text(
                              l10n.settingsLanguageAuto,
                              key: const Key('settings.language.auto'),
                            ),
                          ),
                          ButtonSegment(
                            value: 'es',
                            label: Text(
                              l10n.settingsLanguageEs,
                              key: const Key('settings.language.es'),
                            ),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(
                              l10n.settingsLanguageEn,
                              key: const Key('settings.language.en'),
                            ),
                          ),
                        ],
                        onChanged: (code) => unawaited(
                          ref
                              .read(localeOverrideProvider.notifier)
                              .set(code == 'auto' ? null : Locale(code)),
                        ),
                      ),
                      _switch(
                        'settings.sound',
                        l10n.settingsSound,
                        l10n.settingsSoundHint,
                        soundEnabledProvider,
                      ),
                      _switch(
                        'settings.vibration',
                        l10n.settingsVibration,
                        l10n.settingsVibrationHint,
                        vibrationEnabledProvider,
                      ),
                      _heading(l10n.settingsNotices),
                      _switch(
                        'settings.dueNotice',
                        l10n.settingsDueNotice,
                        l10n.settingsDueNoticeHint,
                        dueNoticeEnabledProvider,
                      ),
                      _switch(
                        'settings.guestNotice',
                        l10n.settingsGuestNotice,
                        l10n.settingsGuestNoticeHint,
                        guestNoticeEnabledProvider,
                      ),
                      _heading(l10n.settingsWidget),
                      _switch(
                        'settings.hideAmount',
                        l10n.settingsHideAmount,
                        l10n.settingsHideAmountHint,
                        hideWidgetAmountProvider,
                      ),
                      if (voiceInstalled) ...[
                        _heading(l10n.settingsVoice),
                        ListTile(
                          key: const Key('settings.deleteVoice'),
                          leading: const Icon(Icons.delete_outline),
                          title: Text(l10n.settingsDeleteVoice),
                          subtitle: Text(l10n.settingsDeleteVoiceHint),
                          onTap: _deleteVoice,
                        ),
                      ],
                      _heading(l10n.settingsServer),
                      ListTile(
                        key: const Key('settings.server'),
                        leading: const Icon(Icons.dns_outlined),
                        title: Text(l10n.settingsServer),
                        subtitle: Text(server.toString()),
                        trailing: const Icon(Icons.edit_outlined),
                        enabled: !_busy,
                        onTap: _changeServer,
                      ),
                      const Divider(),
                      ListTile(
                        key: const Key('settings.about'),
                        leading: const Icon(Icons.info_outline),
                        title: Text(l10n.settingsAbout),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/about'),
                      ),
                      ListTile(
                        key: const Key('settings.web'),
                        leading: const Icon(Icons.open_in_new),
                        title: Text(l10n.settingsWeb),
                        subtitle: Text(l10n.settingsWebHint),
                        onTap: _openWeb,
                      ),
                      ListTile(
                        key: const Key('settings.signOut'),
                        leading: Icon(Icons.logout, color: theme.colorScheme.error),
                        title: Text(
                          l10n.settingsSignOut,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        enabled: !_busy,
                        onTap: _signOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The server address, asked for: [current] to start with. Pops the checked address, or null.
class _ServerDialog extends StatefulWidget {
  const _ServerDialog({required this.current});

  final Uri current;

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  late final _field = TextEditingController(text: widget.current.toString());
  bool _invalid = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final url = parseServerUrl(_field.text);
    if (url == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsServerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsServerLead),
            const SizedBox(height: LukitasTokens.space3),
            TextField(
              key: const Key('settings.server.field'),
              controller: _field,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_invalid) setState(() => _invalid = false);
              },
              decoration: InputDecoration(
                labelText: l10n.settingsServerField,
                border: const OutlineInputBorder(),
                errorText: _invalid ? l10n.settingsServerInvalid : null,
                errorMaxLines: 3,
              ),
            ),
            TextButton(
              key: const Key('settings.server.default'),
              onPressed: () => setState(() {
                _field.text = defaultServerUrl.toString();
                _invalid = false;
              }),
              child: Text(l10n.settingsServerUseDefault),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('settings.server.change'),
          onPressed: _submit,
          child: Text(l10n.settingsServerChange),
        ),
      ],
    );
  }
}
