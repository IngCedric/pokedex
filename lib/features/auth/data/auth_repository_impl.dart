import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/errors/app_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  @override
  AppUser? get currentUser => remote.currentUser;

  @override
  Stream<AppUser?> get authStateChanges => remote.authStateChanges;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    try {
      return await remote.signIn(email: email, password: password);
    } on AuthException catch (e) {
      throw AppException(_friendlyMessage(e));
    }
  }

  @override
  Future<AppUser> register({required String email, required String password}) async {
    try {
      return await remote.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AppException(_friendlyMessage(e));
    }
  }

  @override
  Future<void> logout() => remote.signOut();

  String _friendlyMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (message.contains('password') && message.contains('least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return e.message;
  }
}
