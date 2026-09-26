import 'entities/pokemon.dart';
import 'entities/pokemon_detail.dart';

/// Contrat d'accès aux données pokémon, indépendant de la source
/// (API distante ou cache local).
abstract class PokemonRepository {
  Future<List<Pokemon>> getPokemonList({int offset = 0, int limit = 20});

  Future<PokemonDetail> getPokemonDetail(int id);
}
