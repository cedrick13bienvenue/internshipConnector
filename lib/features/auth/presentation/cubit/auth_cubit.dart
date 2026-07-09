import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSub;

  AuthCubit(this._repository) : super(AuthInitial()) {
    _authSub = _repository.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signIn(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_formatError(e)));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_formatError(e)));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _repository.sendPasswordReset(email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(_formatError(e)));
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _repository.sendEmailVerification();
    } catch (_) {}
  }

  Future<void> checkEmailVerification() async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final isVerified = await _repository.checkEmailVerification();
      if (isVerified) {
        emit(AuthAuthenticated(current.user.copyWith(isEmailVerified: true)));
      }
    } catch (_) {}
  }

  Future<void> completeStudentOnboarding({
    required String bio,
    required List<String> skills,
    String? program,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    emit(AuthLoading());
    try {
      final updated = await _repository.completeStudentOnboarding(
        uid: current.user.uid,
        bio: bio,
        skills: skills,
        program: program,
      );
      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError(_formatError(e)));
    }
  }

  Future<void> completeStartupOnboarding({
    required String startupName,
    required String description,
    required List<String> categories,
    String? websiteUrl,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    emit(AuthLoading());
    try {
      final updated = await _repository.completeStartupOnboarding(
        uid: current.user.uid,
        startupName: startupName,
        description: description,
        categories: categories,
        websiteUrl: websiteUrl,
      );
      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError(_formatError(e)));
    }
  }

  Future<String> uploadProfilePhoto(List<int> bytes, String mimeType) async {
    final current = state;
    if (current is! AuthAuthenticated) throw Exception('Not authenticated');
    final photoUrl = await _repository.uploadProfilePhoto(
      current.user.uid,
      bytes,
      mimeType,
    );
    final updated = await _repository.updateProfilePhoto(current.user.uid, photoUrl);
    emit(AuthAuthenticated(updated));
    return photoUrl;
  }

  Future<void> updateStudentProfile({
    required String fullName,
    String? bio,
    List<String>? skills,
    String? program,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final updated = await _repository.updateStudentProfile(
        uid: current.user.uid,
        fullName: fullName,
        bio: bio,
        skills: skills,
        program: program,
      );
      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError(_formatError(e)));
      emit(current);
    }
  }

  String _formatError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('email-already-in-use')) return 'An account already exists with this email.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (msg.contains('network-request-failed')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
