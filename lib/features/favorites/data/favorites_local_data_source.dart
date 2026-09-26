import 'package:hive/hive.dart';

import '../domain/entities/favorite_pokemon.dart';

abstract class FavoritesLocalDataSource {
  List<FavoritePokemon>? getCachedFavorites();
  Future<void> cacheFavorites(List<FavoritePokemon> favorites);
}

class HiveFavoritesLocalDataSource implements FavoritesLocalDataSource {
  static const _key = 'favorites';

  final Box box;

  HiveFavoritesLocalDataSource({required this.box});

  @override
  List<FavoritePokemon>? getCachedFavorites() {
    final raw = box.get(_key);
    if (raw == null) return null;
    final list = List<Map>.from(raw as List);
    return list
        .map((e) => FavoritePokemon.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> cacheFavorites(List<FavoritePokemon> favorites) {
    return box.put(_key, favorites.map((f) => f.toJson()).toList());
  }
}
