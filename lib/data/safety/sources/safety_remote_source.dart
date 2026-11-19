import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_contact_model.dart';

abstract class SafetyRemoteSource {
  Stream<List<EmergencyContactModel>> watchContacts(String uid);

  Future<void> addContact(String uid, EmergencyContactModel contact);

  Future<void> removeContact(String uid, String contactId);

  Future<void> logSosAlert({
    required String uid,
    required String triggeredPhrase,
    required double latitude,
    required double longitude,
    required String googleMapsUrl,
    required List<String> notifiedNumbers,
  });
}

class SafetyRemoteSourceImpl implements SafetyRemoteSource {
  final FirebaseFirestore firestore;

  SafetyRemoteSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) =>
      firestore.collection('users').doc(uid).collection('emergency_contacts');

  @override
  Stream<List<EmergencyContactModel>> watchContacts(String uid) {
    return _contactsRef(uid).snapshots().map(
      (snap) => snap.docs
          .map((doc) => EmergencyContactModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> addContact(String uid, EmergencyContactModel contact) async {
    await _contactsRef(uid).doc(contact.id).set(contact.toFirestore());
  }

  @override
  Future<void> removeContact(String uid, String contactId) async {
    await _contactsRef(uid).doc(contactId).delete();
  }

  @override
  Future<void> logSosAlert({
    required String uid,
    required String triggeredPhrase,
    required double latitude,
    required double longitude,
    required String googleMapsUrl,
    required List<String> notifiedNumbers,
  }) async {
    await firestore.collection('users').doc(uid).collection('sos_alerts').add({
      'triggeredPhrase': triggeredPhrase,
      'latitude': latitude,
      'longitude': longitude,
      'googleMapsUrl': googleMapsUrl,
      'notifiedNumbers': notifiedNumbers,
      'status': 'dispatched',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
