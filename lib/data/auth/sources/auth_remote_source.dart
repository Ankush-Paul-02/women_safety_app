import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/auth/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteSource {
  Stream<UserModel?> get authStateChanges;

  Future<PhoneVerificationResult> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  });

  Future<UserModel> confirmVerificationCode({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}

class AuthRemoteSourceImpl implements AuthRemoteSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteSourceImpl({required this.firebaseAuth, required this.firestore});

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map(
      (user) => user != null ? UserModel.fromFirebaseUser(user) : null,
    );
  }

  @override
  Future<PhoneVerificationResult> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final completer = Completer<PhoneVerificationResult>();

    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await firebaseAuth.signInWithCredential(
            credential,
          );
          final user = userCredential.user;
          if (user != null) {
            final model = UserModel.fromFirebaseUser(user);
            await _syncUserToFirestore(model);
            if (!completer.isCompleted) {
              completer.complete(
                PhoneVerificationResult(autoVerifiedUser: model),
              );
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationResult(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handled silently if user hasn't submitted OTP yet
      },
    );

    return completer.future;
  }

  @override
  Future<UserModel> confirmVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Authentication succeeded but user data was unavailable.',
      );
    }

    final userModel = UserModel.fromFirebaseUser(user);
    await _syncUserToFirestore(userModel);
    return userModel;
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> _syncUserToFirestore(UserModel user) async {
    final docRef = firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        ...user.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set(user.toFirestore(), SetOptions(merge: true));
    }
  }
}
