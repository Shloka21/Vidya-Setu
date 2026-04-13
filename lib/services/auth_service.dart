import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1016853804488-j5vh562u7jdk28kgoa5qdsvt0l5ie4tq.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name,
    String role,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
    );
    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toMap());

    // Update display name
    await credential.user!.updateDisplayName(name);

    return credential;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Check if user document exists
    final doc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!doc.exists) {
      // New Google user - create document (role will be set in role selection)
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
        role: '', // Will be set in role selection
        profileImageUrl: userCredential.user!.photoURL,
      );
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());
    }

    return userCredential;
  }

  // Get user model from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  // ─── Phone Authentication ────────────────────────────────
  // Send OTP to phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP and sign in
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    // Check if user already exists in Firestore
    final doc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!doc.exists) {
      // New phone user — create document (role will be set in role selection)
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? '',
        email: userCredential.user!.email ?? '',
        phone: userCredential.user!.phoneNumber,
        role: '', // Will be set in role selection
      );
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());
    }

    return userCredential;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Soft Delete Account (30-day grace period) ────────────
  /// Marks the user's Firestore document as deleted.
  /// The user is signed out. If they log back in within 30 days,
  /// they can restore their account.
  Future<void> softDeleteAccount(String uid) async {
    final deletionDate = DateTime.now().add(const Duration(days: 30));
    await _firestore.collection('users').doc(uid).update({
      'isDeleted': true,
      'scheduledDeleteAt': deletionDate.toIso8601String(),
      'deletedAt': DateTime.now().toIso8601String(),
    });
    await signOut();
  }

  /// Restores a soft-deleted account by clearing the deletion flags.
  Future<void> restoreAccount(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isDeleted': false,
      'scheduledDeleteAt': null,
      'deletedAt': null,
    });
  }

  /// Checks if a user account is marked as deleted.
  Future<bool> isAccountDeleted(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['isDeleted'] == true;
    }
    return false;
  }
}
