import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// A message at the bottom of the screen (the web's toast). With [actionLabel] it stays 8 seconds
/// (the `--undo` token) for Deshacer; [extraLabel] is a second action beside it ("Ponerle
/// nombre"), used with an [actionLabel]. An [error] has a red outline.
void showToast(
  ScaffoldMessengerState messenger,
  LukitasColors colors,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  String? extraLabel,
  VoidCallback? onExtra,
  bool error = false,
}) {
  final text = Text(
    message,
    style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
  );
  Widget button(String label, VoidCallback onPressed) => TextButton(
    onPressed: () {
      messenger.hideCurrentSnackBar();
      onPressed();
    },
    style: TextButton.styleFrom(foregroundColor: colors.gold),
    child: Text(label),
  );
  // Two actions do not fit beside the message: they go under it.
  final both = extraLabel != null && actionLabel != null;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: both
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  text,
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: [button(extraLabel, onExtra!), button(actionLabel, onAction!)],
                  ),
                ],
              )
            : text,
        // Deshacer stays 8 seconds; a SnackBar with an action would otherwise stay until
        // dismissed.
        duration: actionLabel != null ? LukitasTokens.durationUndo : const Duration(seconds: 5),
        persist: false,
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
          side: error ? BorderSide(color: colors.over, width: 2) : BorderSide.none,
        ),
        action: actionLabel == null || both
            ? null
            : SnackBarAction(label: actionLabel, textColor: colors.gold, onPressed: onAction!),
      ),
    );
}
