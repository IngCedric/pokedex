import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Intercepteur qui:
/// 1. injecte le token JWT courant (session Supabase) dans chaque requête
///    adressée à Supabase ;
/// 2. si le serveur répond 401 (token expiré), tente un `refreshSession()`
///    puis rejoue la requête une seule fois avec le nouveau token.
class AuthInterceptor extends Interceptor {
  final String supabaseUrl;
  final String anonKey;
  final Dio _retryDio = Dio();

  AuthInterceptor({required this.supabaseUrl, required this.anonKey});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['apikey'] = anonKey;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final result = await Supabase.instance.client.auth.refreshSession();
      final newToken = result.session?.accessToken;
      if (newToken == null) {
        handler.next(err);
        return;
      }

      final options = err.requestOptions;
      options.extra['retried'] = true;
      options.headers['Authorization'] = 'Bearer $newToken';
      options.headers['apikey'] = anonKey;

      final response = await _retryDio.fetch(options);
      handler.resolve(response);
    } catch (_) {
      // Le refresh a échoué (session vraiment expirée) : on laisse
      // l'erreur remonter, la couche repository la traduira en AppException.
      handler.next(err);
    }
  }
}
