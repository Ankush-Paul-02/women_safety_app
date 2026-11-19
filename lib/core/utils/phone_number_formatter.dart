/// Formats a national phone number + region code into E.164 (+<cc><national>).
///
/// Used by the phone-auth flow so the number sent to Firebase is canonical.
class PhoneNumberFormatter {
  PhoneNumberFormatter._();

  /// Builds an E.164 string from [nationalNumber] and [regionCode] (e.g. "US").
  ///
  /// Returns [nationalNumber] unchanged if it already starts with `+` or if
  /// [regionCode] is empty (best-effort fallback).
  static String format({
    required String nationalNumber,
    required String regionCode,
  }) {
    final cleaned = nationalNumber.trim();
    if (cleaned.isEmpty) return cleaned;
    if (cleaned.startsWith('+')) return cleaned;
    if (regionCode.isEmpty) return cleaned;

    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    return '+$regionCode$digits';
  }
}