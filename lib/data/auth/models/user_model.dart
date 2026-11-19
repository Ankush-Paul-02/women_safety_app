import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/auth/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.phoneNumber,
    super.createdAt,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      createdAt: user.metadata.creationTime,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
