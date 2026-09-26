import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/favorites/data/favorites_local_data_source.dart';
import '../../features/favorites/data/favorites_remote_data_source.dart';
import '../../features/favorites/data/favorites_repository_impl.dart';
import '../../features/favorites/domain/favorites_repository.dart';
import '../../features/pokemon/data/pokemon_local_data_source.dart';
import '../../features/pokemon/data/pokemon_remote_data_source.dart';
import '../../features/pokemon/data/pokemon_repository_impl.dart';
import '../../features/pokemon/domain/pokemon_repository.dart';
import '../local/hive_boxes.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';

final getIt = GetIt.instance;

const _supabaseDio = 'supabaseDio';
const _pokeApiDio = 'pokeApiDio';

/// Enregistre toutes les dépendances "services/data" de l'app (réseau, cache
/// local, data sources, repositories) dans le service locator [getIt].
///
/// Les ChangeNotifier exposés à l'arbre de widgets (AuthProvider,
/// FavoritesProvider, ...) restent gérés par `provider`, pas par `get_it` :
/// get_it centralise la construction des dépendances "métier", tandis que
/// `provider` reste responsable du cycle de vie Flutter (dispose, rebuilds).
///
/// Doit être appelé après `Hive` et `Supabase` initialisés.
Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<NetworkInfo>(() => ConnectivityNetworkInfo());

  getIt.registerLazySingleton<Dio>(
    () => DioClient.buildSupabaseDio(),
    instanceName: _supabaseDio,
  );
  getIt.registerLazySingleton<Dio>(
    () => DioClient.buildPokeApiDio(),
    instanceName: _pokeApiDio,
  );

  getIt.registerLazySingleton<PokemonRemoteDataSource>(
    () => PokeApiRemoteDataSource(getIt<Dio>(instanceName: _pokeApiDio)),
  );
  getIt.registerLazySingleton<PokemonLocalDataSource>(
    () => HivePokemonLocalDataSource(
      listBox: Hive.box(HiveBoxes.pokemonList),
      detailBox: Hive.box(HiveBoxes.pokemonDetail),
    ),
  );
  getIt.registerLazySingleton<PokemonRepository>(
    () => PokemonRepositoryImpl(
      remote: getIt<PokemonRemoteDataSource>(),
      local: getIt<PokemonLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton<FavoritesRemoteDataSource>(
    () => SupabaseFavoritesRemoteDataSource(getIt<Dio>(instanceName: _supabaseDio)),
  );
  getIt.registerLazySingleton<FavoritesLocalDataSource>(
    () => HiveFavoritesLocalDataSource(box: Hive.box(HiveBoxes.favorites)),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      remote: getIt<FavoritesRemoteDataSource>(),
      local: getIt<FavoritesLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthDataSource(Supabase.instance.client),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );
}
