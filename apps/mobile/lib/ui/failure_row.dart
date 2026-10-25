// What the web's sheets say above their footer when a save did not go through: apps/web/app/features/
// add-transaction/AddTransactionSheet.tsx (the error line and its retry).
import 'package:flutter/widgets.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'press_button.dart';

/// A refused or failed save, said in the danger colour above a sheet's Guardar, with a small ghost
/// "Reintentar" beside it when sending the same thing again can work ([retryLabel] is null when it
/// cannot). A live region: it is read out when it appears.
class SaveFailureRow extends StatelessWidget {
  const SaveFailureRow({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.retryKey,
  });

  final String message;
  final String? retryLabel;
  final VoidCallback onRetry;

  /// Finds the retry button (tests).
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    return Row(
      spacing: LukitasTokens.space2,
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(message, style: LkText.label.copyWith(color: colors.over)),
          ),
        ),
        if (retryLabel != null)
          PressButton.text(
            retryLabel!,
            key: retryKey,
            tone: PressTone.ghost,
            size: PressSize.sm,
            onPressed: onRetry,
          ),
      ],
    );
  }
}
