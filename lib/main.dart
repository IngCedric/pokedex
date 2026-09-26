import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/local/hive_boxes.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'features/auth/data/auth_remote_data_source.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/favorites/data/favorites_local_data_source.dart';
import 'features/favorites/data/favorites_remote_data_source.dart';
import 'features/favorites/data/favorites_repository_impl.dart';
import 'features/favorites/domain/favorites_repository.dart';
import 'features/favorites/presentation/favorites_provider.dart';
import 'features/pokemon/data/pokemon_local_data_source.dart';
import 'features/pokemon/data/pokemon_remote_data_source.dart';
import 'features/pokemon/data/pokemon_repository_impl.dart';
import 'features/pokemon/domain/pokemon_repository.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await HiveBoxes.init();
  await Supabase.initialize(url: Env.supabaseBaseUrl, anonKey: Env.supabaseAnonKey);

  final networkInfo = ConnectivityNetworkInfo();

  final pokemonRepository = PokemonRepositoryImpl(
    remote: PokeApiRemoteDataSource(DioClient.buildPokeApiDio()),
    local: HivePokemonLocalDataSource(
      listBox: Hive.box(HiveBoxes.pokemonList),
      detailBox: Hive.box(HiveBoxes.pokemonDetail),
    ),
    networkInfo: networkInfo,
  );

  final supabaseDio = DioClient.buildSupabaseDio();
  final favoritesRepository = FavoritesRepositoryImpl(
    remote: SupabaseFavoritesRemoteDataSource(supabaseDio),
    local: HiveFavoritesLocalDataSource(box: Hive.box(HiveBoxes.favorites)),
    networkInfo: networkInfo,
  );

  final authRepository = AuthRepositoryImpl(
    SupabaseAuthDataSource(Supabase.instance.client),
  );
  final authProvider = AuthProvider(authRepository);
  final router = buildAppRouter(authProvider);

  runApp(PokedexApp(
    pokemonRepository: pokemonRepository,
    favoritesRepository: favoritesRepository,
    authProvider: authProvider,
    router: router,
  ));
}

class PokedexApp extends StatelessWidget {
  final PokemonRepository pokemonRepository;
  final FavoritesRepository favoritesRepository;
  final AuthProvider authProvider;
  final GoRouter router;

  const PokedexApp({
    super.key,
    required this.pokemonRepository,
    required this.favoritesRepository,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PokemonRepository>.value(value: pokemonRepository),
        Provider<FavoritesRepository>.value(value: favoritesRepository),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(favoritesRepository)),
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
