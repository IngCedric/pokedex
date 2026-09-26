import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'offline_banner.dart';

/// Enrobe [child] et affiche automatiquement [OfflineBanner] au-dessus dès
/// que l'appareil perd sa connexion réseau.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final results = snapshot.data;
            final isOffline = results != null && results.contains(ConnectivityResult.none);
            return isOffline ? const OfflineBanner() : const SizedBox.shrink();
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
