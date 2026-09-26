import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/pokemon.dart';
import '../domain/pokemon_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

class PokemonListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final PokemonRepository repository;

  PokemonListProvider(this.repository);

  final List<Pokemon> pokemons = [];
  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  bool hasMore = true;
  bool isLoadingMore = false;
  int _offset = 0;

  Future<void> loadFirstPage() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final page = await repository.getPokemonList(offset: 0, limit: _pageSize);
      pokemons
        ..clear()
        ..addAll(page);
      _offset = page.length;
      hasMore = page.length == _pageSize;
      status = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || status != LoadStatus.loaded) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final page = await repository.getPokemonList(offset: _offset, limit: _pageSize);
      pokemons.addAll(page);
      _offset += page.length;
      hasMore = page.length == _pageSize;
    } on AppException {
      // On garde silencieusement la liste déjà chargée : l'erreur de
      // pagination n'empêche pas de consulter ce qui est déjà affiché.
      hasMore = false;
    }
    isLoadingMore = false;
    notifyListeners();
  }
}
