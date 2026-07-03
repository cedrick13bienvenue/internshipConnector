import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().asyncMap(
    (user) async {
      if (user == null) return null;
      try {
        return await _fetchUser(user.uid);
      } catch (_) {
        await _auth.signOut();
        return null;
      }
    },
  );

  Future<UserModel> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('User profile not found.');
    }
    final user = UserModel.fromFirestore(doc);
    return user.copyWith(
      isEmailVerified: _auth.currentUser?.emailVerified ?? false,
    );
  }

  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUser(cred.user!.uid);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.sendEmailVerification();
    final user = UserModel(
      uid: cred.user!.uid,
      email: email,
      fullName: fullName,
      role: role,
      createdAt: DateTime.now(),
      isOnboarded: false,
    );
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<UserModel> completeStudentOnboarding({
    required String uid,
    required String bio,
    required List<String> skills,
    String? program,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isOnboarded': true,
      'bio': bio,
      'skills': skills,
      'program': program,
    });
    return _fetchUser(uid);
  }

  Future<UserModel> completeStartupOnboarding({
    required String uid,
    required String startupName,
    required String description,
    required List<String> categories,
    String? websiteUrl,
  }) async {
    await _db.collection('startups').add({
      'ownerId': uid,
      'name': startupName,
      'description': description,
      'categories': categories,
      'websiteUrl': websiteUrl,
      'verificationStatus': 'pending',
      'createdAt': Timestamp.now(),
      'activeOpportunities': 0,
    });
    await _db.collection('users').doc(uid).update({'isOnboarded': true});
    return _fetchUser(uid);
  }

  Future<UserModel> updateStudentProfile({
    required String uid,
    required String fullName,
    String? bio,
    List<String>? skills,
    String? program,
  }) async {
    await _db.collection('users').doc(uid).update({
      'fullName': fullName,
      'bio': bio,
      'skills': skills ?? [],
      'program': program,
    });
    return _fetchUser(uid);
  }

  Future<UserModel> completeOnboarding(String uid) async {
    await _db.collection('users').doc(uid).update({'isOnboarded': true});
    return _fetchUser(uid);
  }
}
