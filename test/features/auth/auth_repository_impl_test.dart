import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokedex/core/errors/app_exception.dart';
import 'package:pokedex/features/auth/data/auth_remote_data_source.dart';
import 'package:pokedex/features/auth/data/auth_repository_impl.dart';
import 'package:pokedex/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = AuthRepositoryImpl(remote);
  });

  group('login', () {
    test('returns an AppUser on success', () async {
      const user = AppUser(id: '1', email: 'ash@pokemon.test');
      when(() => remote.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => user);

      final result = await repository.login(email: 'ash@pokemon.test', password: 'pikachu1');

      expect(result, user);
    });

    test('translates invalid credentials into a friendly AppException', () async {
      when(() => remote.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => repository.login(email: 'ash@pokemon.test', password: 'wrong'),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', contains('incorrect')),
        ),
      );
    });

    test('passes through an unmapped AuthException message unchanged', () async {
      when(() => remote.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('Email not confirmed'));

      expect(
        () => repository.login(email: 'ash@pokemon.test', password: 'pikachu1'),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', 'Email not confirmed'),
        ),
      );
    });
  });

  group('register', () {
    test('translates a duplicate account error into a friendly AppException', () async {
      when(() => remote.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('User already registered'));

      expect(
        () => repository.register(email: 'ash@pokemon.test', password: 'pikachu1'),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', contains('existe déjà')),
        ),
      );
    });

    test('translates a weak password error into a friendly AppException', () async {
      when(() => remote.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('Password should be at least 6 characters'));

      expect(
        () => repository.register(email: 'ash@pokemon.test', password: '123'),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', contains('6 caractères')),
        ),
      );
    });

    test('returns an AppUser on success', () async {
      const user = AppUser(id: '2', email: 'misty@pokemon.test');
      when(() => remote.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => user);

      final result = await repository.register(email: 'misty@pokemon.test', password: 'starmie1');

      expect(result, user);
    });
  });

  test('logout delegates to the remote data source', () async {
    when(() => remote.signOut()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => remote.signOut()).called(1);
  });
}
