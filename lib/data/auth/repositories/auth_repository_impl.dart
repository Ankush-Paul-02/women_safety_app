import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../domain/auth/entities/user_entity.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../sources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource remoteSource;

  AuthRepositoryImpl({required this.remoteSource});

  @override
  Stream<UserEntity?> get authStateChanges => remoteSource.authStateChanges;

  @override
  Future<Either<Failure, PhoneVerificationResult>> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    try {
      final result = await remoteSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
      );
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      return Left(
        ServerFailure('Unable to send verification code. Try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> confirmVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = await remoteSource.confirmVerificationCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e)));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Database error: ${e.code}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await remoteSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Could not sign out.'));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'invalid-verification-code':
        return 'The 6-digit code is incorrect. Please check and try again.';
      case 'session-expired':
        return 'The verification code has expired. Request a new one.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
