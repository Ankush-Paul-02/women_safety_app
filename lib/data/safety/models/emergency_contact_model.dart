import '../../../domain/safety/entities/emergency_contact.dart';

class EmergencyContactModel extends EmergencyContact {
  const EmergencyContactModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.photoBase64,
  });

  factory EmergencyContactModel.fromEntity(EmergencyContact entity) {
    return EmergencyContactModel(
      id: entity.id,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      photoBase64: entity.photoBase64,
    );
  }

  factory EmergencyContactModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return EmergencyContactModel(
      id: id,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      photoBase64: data['photoBase64'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      if (photoBase64 != null) 'photoBase64': photoBase64,
    };
  }
}
