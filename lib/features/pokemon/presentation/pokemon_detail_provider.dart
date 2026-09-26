import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/pokemon_detail.dart';
import '../domain/pokemon_repository.dart';
import 'pokemon_list_provider.dart' show LoadStatus;

class PokemonDetailProvider extends ChangeNotifier {
  final PokemonRepository repository;
  final int pokemonId;

  PokemonDetailProvider(this.repository, this.pokemonId);

  PokemonDetail? detail;
  LoadStatus status = LoadStatus.initial;
  String? errorMessage;

  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      detail = await repository.getPokemonDetail(pokemonId);
      status = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }
}
