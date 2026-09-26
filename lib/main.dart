import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/di/service_locator.dart';
import 'core/local/hive_boxes.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/favorites/domain/favorites_repository.dart';
import 'features/favorites/presentation/favorites_provider.dart';
import 'features/pokemon/domain/pokemon_repository.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await HiveBoxes.init();
  await Supabase.initialize(url: Env.supabaseBaseUrl, anonKey: Env.supabaseAnonKey);
  await setupServiceLocator();

  final authProvider = AuthProvider(getIt<AuthRepository>());
  final router = buildAppRouter(authProvider);

  runApp(PokedexApp(authProvider: authProvider, router: router));
}

class PokedexApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const PokedexApp({super.key, required this.authProvider, required this.router});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PokemonRepository>.value(value: getIt<PokemonRepository>()),
        Provider<FavoritesRepository>.value(value: getIt<FavoritesRepository>()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(getIt<FavoritesRepository>())),
      ],
      child: MaterialApp.router(
        title: 'PokéDex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
        routerConfig: router,
      ),
    );
  }
}
