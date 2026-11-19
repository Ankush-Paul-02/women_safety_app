import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';

import '../../../data/safety/services/voice_monitoring_service.dart';
import '../../../domain/safety/entities/emergency_contact.dart';
import '../../../domain/safety/entities/sos_alert.dart';
import '../../../domain/safety/usecases/safety_usecases.dart';

class HomeStateProvider extends ChangeNotifier {
  final WatchEmergencyContacts watchContactsUseCase;
  final AddEmergencyContact addContactUseCase;
  final RemoveEmergencyContact removeContactUseCase;
  final TriggerSosAlert triggerSosUseCase;
  final VoiceMonitoringService voiceService;

  HomeStateProvider({
    required this.watchContactsUseCase,
    required this.addContactUseCase,
    required this.removeContactUseCase,
    required this.triggerSosUseCase,
    required this.voiceService,
  });

  StreamSubscription<List<EmergencyContact>>? _contactsSub;
  String? _uid;

  List<EmergencyContact> _contacts = [];
  bool _isVoiceMonitoringActive = false;
  bool _isTriggeringSos = false;
  String _customKeyword = '';
  String? _statusMessage;
  SosAlert? _lastAlert;

  List<EmergencyContact> get contacts => _contacts;

  bool get isVoiceMonitoringActive => _isVoiceMonitoringActive;

  bool get isTriggeringSos => _isTriggeringSos;

  String get customKeyword => _customKeyword;

  String? get statusMessage => _statusMessage;

  SosAlert? get lastAlert => _lastAlert;

  List<String> get activePhrases => [
    'Help me',
    'Save me',
    if (_customKeyword.trim().isNotEmpty) _customKeyword.trim(),
  ];

  void bindUser(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _contactsSub?.cancel();
    _contactsSub = watchContactsUseCase(uid).listen((list) {
      _contacts = list;
      notifyListeners();
    });
  }

  void setCustomKeyword(String keyword) {
    _customKeyword = keyword.trim();
    if (_isVoiceMonitoringActive) {
      voiceService.updatePanicPhrases(activePhrases);
    }
    notifyListeners();
  }

  Future<void> pickAndAddContact() async {
    if (_uid == null) return;
    _statusMessage = null;

    // Request read permission (required on Android when passing properties to showPicker)
    final permStatus = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.read,
    );
    if (permStatus != fc.PermissionStatus.granted) {
      _statusMessage =
          'Contacts permission is required to add trusted contacts.';
      notifyListeners();
      return;
    }

    // Native picker returns the Contact directly with requested properties in v2.6.0
    final picked = await fc.FlutterContacts.native.showPicker(
      properties: {fc.ContactProperty.phone, fc.ContactProperty.photoThumbnail},
    );

    if (picked == null) return;

    if (picked.phones.isEmpty) {
      _statusMessage = 'Selected contact has no phone number.';
      notifyListeners();
      return;
    }

    final phone = picked.phones.first.number.replaceAll(RegExp(r'\s+'), '');
    final thumbnailBytes = picked.photo?.thumbnail;
    final photoBase64 = thumbnailBytes != null
        ? base64Encode(thumbnailBytes)
        : null;

    final displayName =
        (picked.displayName != null && picked.displayName!.trim().isNotEmpty)
        ? picked.displayName!.trim()
        : phone;

    final entity = EmergencyContact(
      id: phone.replaceAll(RegExp(r'[^\d+]'), ''),
      name: displayName,
      phoneNumber: phone,
      photoBase64: photoBase64,
    );

    final result = await addContactUseCase(_uid!, entity);
    result.fold(
      (failure) => _statusMessage = failure.message,
      (_) => _statusMessage = null,
    );
    notifyListeners();
  }

  Future<void> removeContact(String contactId) async {
    if (_uid == null) return;
    final result = await removeContactUseCase(_uid!, contactId);
    result.fold((failure) {
      _statusMessage = failure.message;
      notifyListeners();
    }, (_) {});
  }

  Future<void> toggleVoiceSafety(bool enable) async {
    _statusMessage = null;

    if (!enable) {
      await voiceService.stopMonitoring();
      _isVoiceMonitoringActive = false;
      notifyListeners();
      return;
    }

    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();
    final locStatus = await Permission.locationWhenInUse.request();
    await Permission.notification.request();

    if (!micStatus.isGranted || !speechStatus.isGranted) {
      _statusMessage = 'Microphone and Speech permissions are required.';
      notifyListeners();
      return;
    }

    if (!locStatus.isGranted) {
      _statusMessage =
          'Location permission is required to share GPS in an SOS.';
      notifyListeners();
      return;
    }

    final started = await voiceService.startMonitoring(
      panicPhrases: activePhrases,
      onPanicDetected: (phrase) => triggerSos(phrase: phrase),
      onError: (err) {
        _statusMessage = err;
        _isVoiceMonitoringActive = false;
        notifyListeners();
      },
    );

    _isVoiceMonitoringActive = started;
    notifyListeners();
  }

  Future<void> triggerSos({String phrase = 'Manual SOS'}) async {
    if (_uid == null || _isTriggeringSos) return;

    if (_contacts.isEmpty) {
      _statusMessage = 'Add at least one emergency contact first.';
      notifyListeners();
      return;
    }

    _isTriggeringSos = true;
    _statusMessage = null;
    notifyListeners();

    final result = await triggerSosUseCase(
      uid: _uid!,
      triggeredPhrase: phrase,
      contacts: _contacts,
    );

    result.fold((failure) => _statusMessage = failure.message, (alert) {
      _lastAlert = alert;
      _statusMessage = 'SOS triggered ("$phrase") with live GPS location.';
    });

    _isTriggeringSos = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _contactsSub?.cancel();
    voiceService.stopMonitoring();
    super.dispose();
  }
}
