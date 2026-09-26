import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/network_info.dart';
import '../domain/entities/favorite_pokemon.dart';
import '../domain/favorites_repository.dart';
import 'favorites_local_data_source.dart';
import 'favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource remote;
  final FavoritesLocalDataSource local;
  final NetworkInfo networkInfo;

  FavoritesRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  @override
  Future<List<FavoritePokemon>> getFavorites() async {
    if (await networkInfo.isConnected) {
      try {
        final favorites = await remote.fetchFavorites();
        await local.cacheFavorites(favorites);
        return favorites;
      } on DioException {
        final cached = local.getCachedFavorites();
        if (cached != null) return cached;
        throw AppException.unknown();
      }
    }

    final cached = local.getCachedFavorites();
    if (cached != null) return cached;
    throw AppException.network();
  }

  @override
  Future<void> addFavorite(FavoritePokemon favorite) async {
    if (!await networkInfo.isConnected) {
      throw AppException(
        'Impossible d\'ajouter un favori hors-ligne. Reconnecte-toi puis réessaie.',
      );
    }
    try {
      await remote.addFavorite(favorite);
      final cached = local.getCachedFavorites() ?? [];
      await local.cacheFavorites([favorite, ...cached]);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw AppException.unauthorized();
      throw AppException.server();
    }
  }

  @override
  Future<void> removeFavorite(int pokemonId) async {
    if (!await networkInfo.isConnected) {
      throw AppException(
        'Impossible de retirer un favori hors-ligne. Reconnecte-toi puis réessaie.',
      );
    }
    try {
      await remote.removeFavorite(pokemonId);
      final cached = local.getCachedFavorites() ?? [];
      await local.cacheFavorites(
        cached.where((f) => f.pokemonId != pokemonId).toList(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw AppException.unauthorized();
      throw AppException.server();
    }
  }
}
