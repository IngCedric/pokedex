import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;
  StreamSubscription<AppUser?>? _subscription;

  AuthProvider(this.repository) {
    currentUser = repository.currentUser;
    _subscription = repository.authStateChanges.listen((user) {
      currentUser = user;
      notifyListeners();
    });
  }

  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;

  Future<bool> login({required String email, required String password}) =>
      _run(() => repository.login(email: email, password: password));

  Future<bool> register({required String email, required String password}) =>
      _run(() => repository.register(email: email, password: password));

  Future<bool> _run(Future<AppUser> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await action();
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repository.logout();
    currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
