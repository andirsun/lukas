import 'package:flutter/services.dart';

/// How many digits a sign-in code has (the API's `otpLength`).
const codeLength = 6;

/// The code field's rule: digits only, at most [codeLength].
///
/// A code pasted or autofilled at once is the whole code: whatever separates its digits (spaces, a
/// dash, a line break) or surrounds them ("Tu código: 123 456") is dropped, and it replaces any
/// digits already in the field instead of being cut off after them. Typed one digit at a time,
/// the digits simply stop at [codeLength].
class CodeFormatter extends TextInputFormatter {
  const CodeFormatter();

  static final _notDigit = RegExp(r'\D');

  static String _digits(String text) => text.replaceAll(_notDigit, '');

  /// What [next] added to [previous]: the text between their common start and common end.
  static String _inserted(String previous, String next) {
    var start = 0;
    while (start < previous.length && start < next.length && previous[start] == next[start]) {
      start++;
    }
    var end = 0;
    while (end < previous.length - start &&
        end < next.length - start &&
        previous[previous.length - 1 - end] == next[next.length - 1 - end]) {
      end++;
    }
    return next.substring(start, next.length - end);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final pasted = _digits(_inserted(oldValue.text, newValue.text));
    final digits = pasted.length >= codeLength
        ? pasted.substring(0, codeLength)
        : _digits(newValue.text);
    final text = digits.length > codeLength ? digits.substring(0, codeLength) : digits;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
