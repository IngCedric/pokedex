import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../pokemon/presentation/pokemon_list_provider.dart' show LoadStatus;
import '../domain/entities/favorite_pokemon.dart';
import '../domain/favorites_repository.dart';

/// Provider global (au-dessus du router) : partagé entre l'écran Pokédex
/// (icône coeur sur chaque carte) et l'écran Favoris.
class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository repository;

  FavoritesProvider(this.repository);

  List<FavoritePokemon> favorites = [];
  LoadStatus status = LoadStatus.initial;
  String? errorMessage;

  bool isFavorite(int pokemonId) =>
      favorites.any((f) => f.pokemonId == pokemonId);

  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      favorites = await repository.getFavorites();
      status = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> toggle({
    required int pokemonId,
    required String name,
    required String imageUrl,
  }) async {
    final wasFavorite = isFavorite(pokemonId);
    try {
      if (wasFavorite) {
        await repository.removeFavorite(pokemonId);
        favorites = favorites.where((f) => f.pokemonId != pokemonId).toList();
      } else {
        final favorite = FavoritePokemon(
          pokemonId: pokemonId,
          name: name,
          imageUrl: imageUrl,
          addedAt: DateTime.now(),
        );
        await repository.addFavorite(favorite);
        favorites = [favorite, ...favorites];
      }
      notifyListeners();
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
