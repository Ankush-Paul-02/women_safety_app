import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, PhoneVerificationResult>> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  });

  Future<Either<Failure, UserEntity>> confirmVerificationCode({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, Unit>> signOut();
}
