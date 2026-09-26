import 'package:dio/dio.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

/// Fournit les deux clients Dio utilisés par l'app:
/// - [supabaseDio]: pointe sur l'API REST (PostgREST) de Supabase, avec
///   injection du token JWT + refresh automatique via [AuthInterceptor].
/// - [pokeApiDio]: pointe sur PokeAPI, une API publique qui ne nécessite
///   aucune authentification.
class DioClient {
  static Dio buildSupabaseDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.supabaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(supabaseUrl: Env.supabaseUrl, anonKey: Env.supabaseAnonKey),
    );
    return dio;
  }

  static Dio buildPokeApiDio() {
    return Dio(
      BaseOptions(
        baseUrl: 'https://pokeapi.co/api/v2/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
