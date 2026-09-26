import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_user.dart';

/// Enrobe le SDK Supabase pour que [AuthRepositoryImpl] reste testable
/// (mockable) sans dépendre directement d'un client Supabase concret.
abstract class AuthRemoteDataSource {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String email, required String password});
  Future<void> signOut();
}

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  final SupabaseClient client;

  SupabaseAuthDataSource(this.client);

  AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email ?? '');

  @override
  AppUser? get currentUser => _toAppUser(client.auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges =>
      client.auth.onAuthStateChange.map((state) => _toAppUser(state.session?.user));

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final response =
        await client.auth.signInWithPassword(email: email, password: password);
    final user = _toAppUser(response.user);
    if (user == null) {
      throw const AuthException('Identifiants invalides.');
    }
    return user;
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    final response = await client.auth.signUp(email: email, password: password);
    final user = _toAppUser(response.user);
    if (user == null) {
      throw const AuthException("La création du compte a échoué.");
    }
    return user;
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}
