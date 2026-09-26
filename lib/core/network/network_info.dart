import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../config/env.dart';

/// Abstraction sur l'état de la connexion réseau, pour permettre le mode
/// hors-ligne et être facilement mockable dans les tests de repository.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Combine deux vérifications :
/// 1. l'état de l'interface réseau (wifi/données mobiles/aucune) via
///    `connectivity_plus` — rapide, mais une interface "active" ne garantit
///    pas un accès internet réel (portail captif, wifi sans internet...) ;
/// 2. une requête HTTP légère vers le backend de l'app (avec un timeout
///    court), qui ne conclut à un accès réseau que si une vraie réponse HTTP
///    est reçue, peu importe son statut.
class ConnectivityNetworkInfo implements NetworkInfo {
  final Connectivity _connectivity;
  final Dio _pingClient;

  ConnectivityNetworkInfo({Connectivity? connectivity, Dio? pingClient})
      : _connectivity = connectivity ?? Connectivity(),
        _pingClient = pingClient ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ));

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;
    return _hasRealInternetAccess();
  }

  Future<bool> _hasRealInternetAccess() async {
    try {
      // N'importe quelle réponse HTTP (même une 401/404) prouve qu'il y a un
      // accès réseau réel jusqu'au backend ; seule une erreur de connexion
      // (timeout, DNS, hôte injoignable) doit être traitée comme "hors-ligne".
      await _pingClient.get(
        Env.supabaseUrl,
        options: Options(validateStatus: (_) => true),
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
