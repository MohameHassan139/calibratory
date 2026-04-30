// lib/presentation/controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<AppUser?> appUser = Rx<AppUser?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _handleAuthChange);
  }

  void _handleAuthChange(User? user) {
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
        appUser.value = AppUser.fromFirestore(doc);
      }
    } catch (e) {
      print('❌ Firestore _loadUserData failed: $e');
      // Build a minimal AppUser from Firebase Auth so the app still works
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        appUser.value = AppUser(
          uid: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? firebaseUser.email ?? 'Engineer',
          email: firebaseUser.email ?? '',
          phone: '',
          createdAt: DateTime.now(),
        );
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

  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Email Sent', 'Check your inbox for password reset instructions.',
          snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _authError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
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
