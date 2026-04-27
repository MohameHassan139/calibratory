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
      _loadUserData(user.uid);
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      appUser.value = AppUser.fromFirestore(doc);
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toFirestore());
      appUser.value = user;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Registration Failed', _authError(e.code),
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
