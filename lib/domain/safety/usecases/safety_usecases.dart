import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../entities/emergency_contact.dart';
import '../entities/sos_alert.dart';
import '../repositories/safety_repository.dart';

class WatchEmergencyContacts {
  final SafetyRepository repository;

  WatchEmergencyContacts(this.repository);

  Stream<List<EmergencyContact>> call(String uid) =>
      repository.watchContacts(uid);
}

class AddEmergencyContact {
  final SafetyRepository repository;

  AddEmergencyContact(this.repository);

  Future<Either<Failure, Unit>> call(String uid, EmergencyContact contact) =>
      repository.addContact(uid, contact);
}

class RemoveEmergencyContact {
  final SafetyRepository repository;

  RemoveEmergencyContact(this.repository);

  Future<Either<Failure, Unit>> call(String uid, String contactId) =>
      repository.removeContact(uid, contactId);
}

class TriggerSosAlert {
  final SafetyRepository repository;

  TriggerSosAlert(this.repository);

  Future<Either<Failure, SosAlert>> call({
    required String uid,
    required String triggeredPhrase,
    required List<EmergencyContact> contacts,
  }) => repository.triggerSos(
    uid: uid,
    triggeredPhrase: triggeredPhrase,
    contacts: contacts,
  );
}
