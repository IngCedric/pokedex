import 'entities/favorite_pokemon.dart';

abstract class FavoritesRepository {
  Future<List<FavoritePokemon>> getFavorites();
  Future<void> addFavorite(FavoritePokemon favorite);
  Future<void> removeFavorite(int pokemonId);
}
