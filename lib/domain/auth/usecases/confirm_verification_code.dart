import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ConfirmVerificationCode {
  final AuthRepository repository;

  ConfirmVerificationCode(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String verificationId,
    required String smsCode,
  }) {
    return repository.confirmVerificationCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}
