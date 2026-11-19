class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? photoBase64;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photoBase64,
  });
}
