import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction sur l'état de la connexion réseau, pour permettre le mode
/// hors-ligne et être facilement mockable dans les tests de repository.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  final Connectivity _connectivity;

  ConnectivityNetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
