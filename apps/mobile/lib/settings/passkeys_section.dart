// "Entrar con tu huella" of the web's Settings (apps/web/app/features/settings/PasskeysSection.tsx):
// the person's passkeys, each with its name and when it was made, and its own "Eliminar" after
// asking; "Agregar una huella" where the phone can make one. Closing the phone's prompt is silent,
// as on sign-in.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture/parser/dates.dart';
import '../l10n/app_localizations.dart';
import '../recurring/recurring_row.dart' show formatRecurringDate;
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/confirm_sheet.dart';
import '../ui/css_text.dart';
import '../ui/lk_icons.dart';
import '../ui/lk_theme.dart';
import '../ui/offset_underline.dart';
import '../ui/pressable.dart' show PressSurface;
import '../ui/press_button.dart';
import '../ui/toast.dart';
import 'passkeys_settings.dart';
import 'settings_parts.dart';

/// The account's passkeys, read when Settings opens and again after an add or a delete.
final settingsPasskeyListProvider = FutureProvider.autoDispose<List<PasskeyItem>>(
  (ref) => ref.watch(settingsPasskeysProvider).list(),
  // The web's card says it could not load them; opening Settings again asks again.
  retry: (_, _) => null,
);

/// Whether this phone can make a passkey, asked once.
final _passkeysCanBeMadeProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(settingsPasskeysProvider).supported(),
);

/// A day as `2 oct 2026` (es) or `Oct 2, 2026` (en), in the person's time zone.
String passkeyDay(DateTime at, String locale, String timeZone) =>
    formatRecurringDate(todayIn(timeZone, at.toUtc()), locale);

class PasskeysSection extends ConsumerStatefulWidget {
  const PasskeysSection({super.key, required this.timeZone, required this.guest});

  /// The profile's zone: a passkey is dated in it.
  final String timeZone;

  /// A guest cannot add a passkey from here: they save their progress with an email first.
  final bool guest;

  @override
  ConsumerState<PasskeysSection> createState() => _PasskeysSectionState();
}

class _PasskeysSectionState extends ConsumerState<PasskeysSection> {
  var _adding = false;

  Future<void> _add() async {
    if (_adding) return;
    final l10n = AppLocalizations.of(context);
    final toasts = ToastHost.of(context);
    setState(() => _adding = true);
    try {
      final outcome = await ref.read(settingsPasskeysProvider).add();
      switch (outcome) {
        case PasskeyOutcome.added:
          toasts.say(l10n.settingsPasskeysAdded);
          ref.invalidate(settingsPasskeyListProvider);
        case PasskeyOutcome.failed:
          toasts.say(l10n.settingsPasskeysAddFailed, error: true);
        case PasskeyOutcome.cancelled:
          break;
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _remove(PasskeyItem item) async {
    final l10n = AppLocalizations.of(context);
    final toasts = ToastHost.of(context);
    final removed = await ConfirmSheet.show(
      context,
      title: l10n.settingsPasskeysRemoveTitle,
      body: l10n.settingsPasskeysRemoveBody,
      confirmLabel: l10n.settingsPasskeysRemoveConfirm,
      confirmKey: const Key('settings.passkeys.remove.confirm'),
      onConfirm: () async {
        try {
          await ref.read(settingsPasskeysProvider).remove(item.id);
        } on Object {
          // The sheet stays for another try, and says why.
          toasts.say(l10n.settingsPasskeysRemoveFailed, error: true);
          rethrow;
        }
        toasts.say(l10n.settingsPasskeysRemoved);
      },
    );
    if (removed) ref.invalidate(settingsPasskeyListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final list = ref.watch(settingsPasskeyListProvider);
    final canMake = ref.watch(_passkeysCanBeMadeProvider).value ?? true;
    final mutedSm = LkText.bodySm.copyWith(color: colors.inkMuted);
    final items = list.value;
    final addLabel = _adding ? l10n.settingsPasskeysAdding : l10n.settingsPasskeysAdd;
    final guest = widget.guest;

    return SettingsSection(
      key: const Key('settings.card.passkeys'),
      title: l10n.settingsPasskeysTitle,
      lead: l10n.settingsPasskeysLead,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LukitasTokens.space2,
          children: [
            if (list.hasError && items == null)
              CssParagraph(l10n.settingsPasskeysListFailed, style: mutedSm),
            if (items != null && items.isEmpty)
              CssParagraph(
                l10n.settingsPasskeysEmpty,
                style: LkText.bodySm.copyWith(color: colors.ink),
              ),
            if (items != null && items.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LukitasTokens.space2,
                children: [
                  for (final item in items)
                    _PasskeyRow(
                      item: item,
                      day: passkeyDay(item.createdAt, l10n.localeName, widget.timeZone),
                      onRemove: () => unawaited(_remove(item)),
                    ),
                ],
              ),
          ],
        ),
        if (!canMake)
          CssParagraph(l10n.settingsPasskeysUnsupported, style: mutedSm)
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: PressButton(
              key: const Key('settings.passkeys.add'),
              tone: PressTone.secondary,
              onPressed: _adding || guest ? null : () => unawaited(_add()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: LukitasTokens.space2,
                children: [
                  const FingerprintIcon(),
                  Flexible(child: Text(LkText.upperCase(addLabel))),
                ],
              ),
            ),
          ),
          if (guest) CssParagraph(l10n.settingsPasskeysGuest, style: mutedSm),
        ],
      ],
    );
  }
}

/// One passkey: `lk-rowcard justify-between`, the fingerprint in `brand-glow`, its name (or
/// "Huella") over "Creada el…" and "Sincronizada", and its "Eliminar".
class _PasskeyRow extends StatelessWidget {
  const _PasskeyRow({required this.item, required this.day, required this.onRemove});

  final PasskeyItem item;
  final String day;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lk = context.lk;
    final colors = lk.colors;
    final name = item.name;
    final removeLabel = name == null
        ? l10n.settingsPasskeysRemoveLabel(day)
        : l10n.settingsPasskeysRemoveNamedLabel(name, day);
    final muted = LkText.fieldLabel.copyWith(color: colors.inkMuted);
    return PressSurface(
      minSize: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: LkSurface.rowCard(lk),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                spacing: LukitasTokens.space3,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(color: colors.brandGlow),
                    child: const FingerprintIcon(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CssBlinkLines(
                          style: LkText.body,
                          child: Text(
                            name ?? l10n.settingsPasskeysDefaultName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LkText.body.copyWith(color: colors.ink),
                          ),
                        ),
                        Wrap(
                          spacing: LukitasTokens.space2,
                          children: [
                            CssBlinkLines(
                              style: LkText.fieldLabel,
                              child: Text(l10n.settingsPasskeysCreated(day), style: muted),
                            ),
                            if (item.synced)
                              CssBlinkLines(
                                style: LkText.fieldLabel,
                                child: Text(l10n.settingsPasskeysSynced, style: muted),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PressButton(
              key: Key('settings.passkeys.remove.${item.id}'),
              tone: PressTone.ghost,
              size: PressSize.sm,
              semanticLabel: removeLabel,
              onPressed: onRemove,
              child: OffsetUnderline(LkText.upperCase(l10n.settingsPasskeysRemove)),
            ),
          ],
        ),
      ),
    );
  }
}
