// lib/presentation/controllers/auth_controller.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<AppUser?> appUser = Rx<AppUser?>(null);
  final RxBool isLoading = false.obs;

  static const _kUserKey = 'cached_user';

  /// Set to true by SplashScreen once it's ready to hand off navigation.
  bool splashComplete = false;

  @override
  void onInit() {
    super.onInit();
    _restoreCachedUser();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _handleAuthChange);
  }

  // ── Local storage helpers ────────────────────────────────────────────────

  Future<void> _saveUserLocally(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }

  void _restoreCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);
    if (raw != null) {
      try {
        appUser.value = AppUser.fromJson(jsonDecode(raw));
      } catch (_) {
        await prefs.remove(_kUserKey);
      }
    }
  }

  void _handleAuthChange(User? user) {
    // Don't navigate while splash is still showing
    if (!splashComplete) return;

    if (user != null) {
      if (!user.emailVerified) {
        Get.offAllNamed(AppRoutes.verifyEmail);
      } else {
        _loadUserData(user.uid);
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      appUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = AppUser.fromFirestore(doc);
        appUser.value = user;
        await _saveUserLocally(user);
      }
    } catch (e) {
      print('❌ Firestore _loadUserData failed: $e');
      // Fall back to cached user if already restored, otherwise build minimal one
      if (appUser.value == null) {
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          final user = AppUser(
            uid: firebaseUser.uid,
            fullName:
                firebaseUser.displayName ?? firebaseUser.email ?? 'Engineer',
            email: firebaseUser.email ?? '',
            phone: '',
            createdAt: DateTime.now(),
          );
          appUser.value = user;
          await _saveUserLocally(user);
        }
      }
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (cred.user != null && !cred.user!.emailVerified) {
        Get.offAllNamed(AppRoutes.verifyEmail);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(fullName);

      final user = AppUser(
        uid: cred.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
      );
      try {
        await _db
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toFirestore());
      } catch (e) {
        print('❌ Firestore register save failed: $e');
      }
      appUser.value = user;
      await _saveUserLocally(user);

      // Send verification email
      await cred.user?.sendEmailVerification();
      Get.snackbar(
        'Verify Your Email',
        'A verification link has been sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Registration Failed', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    isLoading.value = true;
    try {
      await _auth.currentUser?.sendEmailVerification();
      Get.snackbar('Email Sent', 'Verification email resent. Check your inbox.',
          snackPosition: SnackPosition.BOTTOM);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkEmailVerified() async {
    isLoading.value = true;
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        await _loadUserData(user.uid);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar(
          'Not Verified Yet',
          'Please check your inbox and click the verification link.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not check verification status.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email, {VoidCallback? onSuccess}) async {
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Email Sent',
        'Check your inbox for password reset instructions.',
        snackPosition: SnackPosition.BOTTOM,
      );
      onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _clearLocalUser();
    appUser.value = null;
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(fullName);

        final updatedUser = AppUser(
          uid: user.uid,
          fullName: fullName,
          email: user.email ?? '',
          phone: phone,
          role: appUser.value?.role ?? 'engineer',
          photoUrl: appUser.value?.photoUrl,
          createdAt: appUser.value?.createdAt ?? DateTime.now(),
        );

        await _db
            .collection('users')
            .doc(user.uid)
            .update(updatedUser.toFirestore());

        appUser.value = updatedUser;
        await _saveUserLocally(updatedUser);
        Get.snackbar('Success', 'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(newPassword);

        Get.snackbar('Success', 'Password changed successfully',
            snackPosition: SnackPosition.BOTTOM);
        Get.back();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        Get.snackbar('Error', 'Current password is incorrect',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', _authError(e.code),
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to change password: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
