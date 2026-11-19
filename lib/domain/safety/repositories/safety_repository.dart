import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../entities/emergency_contact.dart';
import '../entities/sos_alert.dart';

abstract class SafetyRepository {
  Stream<List<EmergencyContact>> watchContacts(String uid);

  Future<Either<Failure, Unit>> addContact(
    String uid,
    EmergencyContact contact,
  );

  Future<Either<Failure, Unit>> removeContact(String uid, String contactId);

  Future<Either<Failure, SosAlert>> triggerSos({
    required String uid,
    required String triggeredPhrase,
    required List<EmergencyContact> contacts,
  });
}
