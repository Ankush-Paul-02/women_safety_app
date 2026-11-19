class SosAlert {
  final String triggeredPhrase;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<String> notifiedNumbers;

  const SosAlert({
    required this.triggeredPhrase,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.notifiedNumbers,
  });

  String get googleMapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';
}
