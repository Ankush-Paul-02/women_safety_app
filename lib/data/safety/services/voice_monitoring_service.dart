import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceMonitoringService {
  final SpeechToText _speech = SpeechToText();

  bool _isMonitoring = false;
  bool _isListeningCycle = false;
  Timer? _restartTimer;
  List<String> _panicPhrases = const ['help me', 'save me'];
  void Function(String detectedPhrase)? _onPanicDetected;
  void Function(String error)? _onError;

  bool get isMonitoring => _isMonitoring;

  Future<void> initForegroundService() async {
    if (!Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'voice_safety_channel',
        channelName: 'Voice Safety Monitoring',
        channelDescription: 'Active while listening for emergency keywords.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<bool> startMonitoring({
    required List<String> panicPhrases,
    required void Function(String detectedPhrase) onPanicDetected,
    required void Function(String error) onError,
  }) async {
    if (_isMonitoring) return true;

    _panicPhrases = panicPhrases
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toList();
    _onPanicDetected = onPanicDetected;
    _onError = onError;

    final available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        // Recover gracefully from silence timeouts without stopping monitoring
        if (_isMonitoring && error.errorMsg != 'error_permission') {
          _scheduleNextListenCycle(delay: const Duration(seconds: 2));
        } else if (error.errorMsg == 'error_permission') {
          _onError?.call('Microphone permission is required.');
          stopMonitoring();
        }
      },
    );

    if (!available) {
      _onError?.call('On-device speech recognition is unavailable.');
      return false;
    }

    if (Platform.isAndroid) {
      await initForegroundService();
      await FlutterForegroundTask.startService(
        notificationTitle: 'Voice Safety Active',
        notificationText: 'Listening locally for your emergency keyword.',
      );
    }

    _isMonitoring = true;
    _startListenCycle();
    return true;
  }

  void updatePanicPhrases(List<String> phrases) {
    _panicPhrases = phrases
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _isListeningCycle = false;
    _restartTimer?.cancel();
    _restartTimer = null;

    if (_speech.isListening) {
      await _speech.stop();
    }

    if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  void _startListenCycle() {
    if (!_isMonitoring || _isListeningCycle) return;
    _isListeningCycle = true;

    _speech.listen(
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        onDevice: true, // Strictly on-device: zero audio uploaded
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
      onResult: (result) {
        final spoken = result.recognizedWords.toLowerCase();
        for (final phrase in _panicPhrases) {
          if (spoken.contains(phrase)) {
            debugPrint('Panic phrase detected: $phrase');
            _onPanicDetected?.call(phrase);
            // Pause briefly after trigger to prevent duplicate SOS spam
            _speech.stop();
            _isListeningCycle = false;
            _scheduleNextListenCycle(delay: const Duration(seconds: 15));
            return;
          }
        }
      },
    );
  }

  void _handleStatus(String status) {
    if ((status == 'done' || status == 'notListening') && _isMonitoring) {
      _isListeningCycle = false;
      // Duty-cycle pause (1.5s) reduces battery draw between windows
      _scheduleNextListenCycle(delay: const Duration(milliseconds: 1500));
    }
  }

  void _scheduleNextListenCycle({required Duration delay}) {
    _restartTimer?.cancel();
    if (!_isMonitoring) return;
    _restartTimer = Timer(delay, () {
      if (_isMonitoring) _startListenCycle();
    });
  }
}
