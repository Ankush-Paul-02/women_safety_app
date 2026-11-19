class UserEntity {
  final String uid;
  final String phoneNumber;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.phoneNumber,
    this.createdAt,
  });
}

class PhoneVerificationResult {
  final String? verificationId;
  final int? resendToken;
  final UserEntity? autoVerifiedUser;

  const PhoneVerificationResult({
    this.verificationId,
    this.resendToken,
    this.autoVerifiedUser,
  });

  bool get isAutoVerified => autoVerifiedUser != null;
}
