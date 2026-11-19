import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneNumber {
  final AuthRepository repository;

  VerifyPhoneNumber(this.repository);

  Future<Either<Failure, PhoneVerificationResult>> call({
    required String phoneNumber,
    int? forceResendingToken,
  }) {
    return repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
    );
  }
}
