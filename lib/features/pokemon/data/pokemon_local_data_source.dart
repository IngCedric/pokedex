import 'package:hive/hive.dart';

import '../domain/entities/pokemon.dart';
import '../domain/entities/pokemon_detail.dart';

abstract class PokemonLocalDataSource {
  List<Pokemon>? getCachedList({required int offset, required int limit});
  Future<void> cacheList(List<Pokemon> pokemons, {required int offset, required int limit});

  PokemonDetail? getCachedDetail(int id);
  Future<void> cacheDetail(PokemonDetail detail);
}

class HivePokemonLocalDataSource implements PokemonLocalDataSource {
  final Box listBox;
  final Box detailBox;

  HivePokemonLocalDataSource({required this.listBox, required this.detailBox});

  String _listKey(int offset, int limit) => '${offset}_$limit';

  @override
  List<Pokemon>? getCachedList({required int offset, required int limit}) {
    final raw = listBox.get(_listKey(offset, limit));
    if (raw == null) return null;
    final list = List<Map>.from(raw as List);
    return list
        .map((e) => Pokemon.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> cacheList(List<Pokemon> pokemons, {required int offset, required int limit}) {
    return listBox.put(
      _listKey(offset, limit),
      pokemons.map((p) => p.toJson()).toList(),
    );
  }

  @override
  PokemonDetail? getCachedDetail(int id) {
    final raw = detailBox.get(id);
    if (raw == null) return null;
    return PokemonDetail.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> cacheDetail(PokemonDetail detail) {
    return detailBox.put(detail.id, detail.toJson());
  }
}
