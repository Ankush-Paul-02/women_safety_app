/// Minimal country-code model for the phone-auth picker.
///
/// A small curated list is used to keep the app dependency-free; the user can
/// still type any number and we normalize it to E.164 via the region code.
class CountryCode {
  const CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode; // e.g. "US"
  final String flag; // emoji

  @override
  String toString() => '$flag +$dialCode';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode &&
          runtimeType == other.runtimeType &&
          dialCode == other.dialCode;

  @override
  int get hashCode => dialCode.hashCode;
}

const List<CountryCode> supportedCountryCodes = [
  CountryCode(name: 'India', dialCode: '91', flag: '🇮🇳'),
  CountryCode(name: 'United States', dialCode: '1', flag: '🇺🇸'),
  CountryCode(name: 'United Kingdom', dialCode: '44', flag: '🇬🇧'),
  CountryCode(name: 'Canada', dialCode: '1', flag: '🇨🇦'),
  CountryCode(name: 'Australia', dialCode: '61', flag: '🇦🇺'),
  CountryCode(name: 'Pakistan', dialCode: '92', flag: '🇵🇰'),
  CountryCode(name: 'Bangladesh', dialCode: '880', flag: '🇧🇩'),
  CountryCode(name: 'Nigeria', dialCode: '234', flag: '🇳🇬'),
  CountryCode(name: 'South Africa', dialCode: '27', flag: '🇿🇦'),
  CountryCode(name: 'United Arab Emirates', dialCode: '971', flag: '🇦🇪'),
  CountryCode(name: 'Saudi Arabia', dialCode: '966', flag: '🇸🇦'),
  CountryCode(name: 'Philippines', dialCode: '63', flag: '🇵🇭'),
  CountryCode(name: 'Malaysia', dialCode: '60', flag: '🇲🇾'),
  CountryCode(name: 'Singapore', dialCode: '65', flag: '🇸🇬'),
  CountryCode(name: 'Indonesia', dialCode: '62', flag: '🇮🇩'),
  CountryCode(name: 'Brazil', dialCode: '55', flag: '🇧🇷'),
  CountryCode(name: 'Mexico', dialCode: '52', flag: '🇲🇽'),
  CountryCode(name: 'Turkey', dialCode: '90', flag: '🇹🇷'),
  CountryCode(name: 'France', dialCode: '33', flag: '🇫🇷'),
  CountryCode(name: 'Germany', dialCode: '49', flag: '🇩🇪'),
  CountryCode(name: 'Italy', dialCode: '39', flag: '🇮🇹'),
  CountryCode(name: 'Spain', dialCode: '34', flag: '🇪🇸'),
  CountryCode(name: 'China', dialCode: '86', flag: '🇨🇳'),
  CountryCode(name: 'Japan', dialCode: '81', flag: '🇯🇵'),
  CountryCode(name: 'South Korea', dialCode: '82', flag: '🇰🇷'),
];

CountryCode defaultCountryCode = supportedCountryCodes.first;
