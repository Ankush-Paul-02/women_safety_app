import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/auth/usecases/confirm_verification_code.dart';
import '../../../domain/auth/usecases/sign_out.dart';
import '../../../domain/auth/usecases/verify_phone_number.dart';
import '../widgets/country_code.dart';

enum AuthFlowStatus { initial, loading, codeSent, authenticated, error }

class AuthStateProvider extends ChangeNotifier {
  final VerifyPhoneNumber verifyPhoneNumberUseCase;
  final ConfirmVerificationCode confirmVerificationCodeUseCase;
  final SignOut signOutUseCase;
  final AuthRepository authRepository;

  AuthStateProvider({
    required this.verifyPhoneNumberUseCase,
    required this.confirmVerificationCodeUseCase,
    required this.signOutUseCase,
    required this.authRepository,
  }) {
    _authSub = authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _status = AuthFlowStatus.authenticated;
      } else if (_status == AuthFlowStatus.authenticated) {
        _status = AuthFlowStatus.initial;
      }
      notifyListeners();
    });
  }

  StreamSubscription<UserEntity?>? _authSub;
  Timer? _resendTimer;

  AuthFlowStatus _status = AuthFlowStatus.initial;
  UserEntity? _currentUser;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;
  String _formattedPhone = '';
  int _resendSecondsRemaining = 0;

  // Defaults to India (+91) from your supportedCountryCodes list
  CountryCode _selectedCountry = supportedCountryCodes.firstWhere(
    (c) => c.dialCode == '91',
    orElse: () => supportedCountryCodes.first,
  );

  AuthFlowStatus get status => _status;

  UserEntity? get currentUser => _currentUser;

  String? get errorMessage => _errorMessage;

  String get formattedPhone => _formattedPhone;

  int get resendSecondsRemaining => _resendSecondsRemaining;

  bool get canResend => _resendSecondsRemaining == 0;

  CountryCode get selectedCountry => _selectedCountry;

  bool get isLoading => _status == AuthFlowStatus.loading;

  void selectCountry(CountryCode country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String rawPhoneNumber) async {
    final digitsOnly = rawPhoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) {
      _errorMessage = 'Please enter a valid phone number.';
      _status = AuthFlowStatus.error;
      notifyListeners();
      return false;
    }

    _formattedPhone = '+${_selectedCountry.dialCode}$digitsOnly';
    _status = AuthFlowStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyPhoneNumberUseCase(
      phoneNumber: _formattedPhone,
      forceResendingToken: _resendToken,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _status = AuthFlowStatus.error;
        notifyListeners();
        return false;
      },
      (verification) {
        if (verification.isAutoVerified) {
          _currentUser = verification.autoVerifiedUser;
          _status = AuthFlowStatus.authenticated;
          notifyListeners();
          return true;
        }
        _verificationId = verification.verificationId;
        _resendToken = verification.resendToken;
        _status = AuthFlowStatus.codeSent;
        _startResendCooldown();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> resendOtp() async {
    if (!canResend || _formattedPhone.isEmpty) return false;

    _status = AuthFlowStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyPhoneNumberUseCase(
      phoneNumber: _formattedPhone,
      forceResendingToken: _resendToken,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _status = AuthFlowStatus.error;
        notifyListeners();
        return false;
      },
      (verification) {
        _verificationId = verification.verificationId;
        _resendToken = verification.resendToken;
        _status = AuthFlowStatus.codeSent;
        _startResendCooldown();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'Session expired. Please request a new code.';
      _status = AuthFlowStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthFlowStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await confirmVerificationCodeUseCase(
      verificationId: _verificationId!,
      smsCode: smsCode.trim(),
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _status = AuthFlowStatus.error;
        notifyListeners();
        return false;
      },
      (user) {
        _currentUser = user;
        _status = AuthFlowStatus.authenticated;
        _resendTimer?.cancel();
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> signOut() async {
    await signOutUseCase();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsRemaining = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        _resendSecondsRemaining = 0;
      } else {
        _resendSecondsRemaining--;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }
}
