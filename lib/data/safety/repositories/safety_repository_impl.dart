import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/failures.dart';
import '../../../domain/safety/entities/emergency_contact.dart';
import '../../../domain/safety/entities/sos_alert.dart';
import '../../../domain/safety/repositories/safety_repository.dart';
import '../models/emergency_contact_model.dart';
import '../services/location_service.dart';
import '../sources/safety_remote_source.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  final SafetyRemoteSource remoteSource;
  final LocationService locationService;

  SafetyRepositoryImpl({
    required this.remoteSource,
    required this.locationService,
  });

  @override
  Stream<List<EmergencyContact>> watchContacts(String uid) =>
      remoteSource.watchContacts(uid);

  @override
  Future<Either<Failure, Unit>> addContact(
    String uid,
    EmergencyContact contact,
  ) async {
    try {
      await remoteSource.addContact(
        uid,
        EmergencyContactModel.fromEntity(contact),
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Could not save contact: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeContact(
    String uid,
    String contactId,
  ) async {
    try {
      await remoteSource.removeContact(uid, contactId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Could not remove contact: $e'));
    }
  }

  @override
  Future<Either<Failure, SosAlert>> triggerSos({
    required String uid,
    required String triggeredPhrase,
    required List<EmergencyContact> contacts,
  }) async {
    try {
      final position = await locationService.getCurrentPosition();
      final numbers = contacts.map((c) => c.phoneNumber).toList();

      final alert = SosAlert(
        triggeredPhrase: triggeredPhrase,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        notifiedNumbers: numbers,
      );

      // 1. Persist to Firestore (triggers backend Cloud Function / FCM if configured)
      await remoteSource.logSosAlert(
        uid: uid,
        triggeredPhrase: alert.triggeredPhrase,
        latitude: alert.latitude,
        longitude: alert.longitude,
        googleMapsUrl: alert.googleMapsUrl,
        notifiedNumbers: numbers,
      );

      // 2. Open pre-filled group SMS to all emergency contacts
      if (numbers.isNotEmpty) {
        final message = Uri.encodeComponent(
          'EMERGENCY SOS! I need help immediately. '
          'My live location: ${alert.googleMapsUrl}',
        );
        final recipients = numbers.join(Platform.isIOS ? '&' : ',');
        final smsUri = Platform.isIOS
            ? Uri.parse(
                'sms:/open?addresses=${numbers.join(",")}&body=$message',
              )
            : Uri.parse('sms:$recipients?body=$message');

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }

      return Right(alert);
    } catch (e) {
      return Left(ServerFailure('SOS trigger failed: $e'));
    }
  }
}
