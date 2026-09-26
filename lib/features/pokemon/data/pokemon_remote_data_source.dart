import 'package:dio/dio.dart';

import '../domain/entities/pokemon.dart';
import '../domain/entities/pokemon_detail.dart';

abstract class PokemonRemoteDataSource {
  Future<List<Pokemon>> fetchList({required int offset, required int limit});
  Future<PokemonDetail> fetchDetail(int id);
}

class PokeApiRemoteDataSource implements PokemonRemoteDataSource {
  final Dio dio;

  PokeApiRemoteDataSource(this.dio);

  static String spriteUrlFor(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  static int _idFromUrl(String url) {
    final match = RegExp(r'/pokemon/(\d+)/?$').firstMatch(url);
    return int.parse(match!.group(1)!);
  }

  @override
  Future<List<Pokemon>> fetchList({required int offset, required int limit}) async {
    final response = await dio.get(
      'pokemon',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    final results = response.data['results'] as List;
    return results.map((raw) {
      final id = _idFromUrl(raw['url'] as String);
      return Pokemon(
        id: id,
        name: raw['name'] as String,
        imageUrl: spriteUrlFor(id),
      );
    }).toList();
  }

  @override
  Future<PokemonDetail> fetchDetail(int id) async {
    final response = await dio.get('pokemon/$id');
    final data = response.data as Map<String, dynamic>;

    final types = (data['types'] as List)
        .map((t) => t['type']['name'] as String)
        .toList();
    final abilities = (data['abilities'] as List)
        .map((a) => a['ability']['name'] as String)
        .toList();
    final stats = <String, int>{
      for (final s in data['stats'] as List)
        s['stat']['name'] as String: s['base_stat'] as int,
    };

    final sprites = data['sprites'] as Map<String, dynamic>;
    final imageUrl = (sprites['front_default'] as String?) ?? spriteUrlFor(id);

    return PokemonDetail(
      id: data['id'] as int,
      name: data['name'] as String,
      imageUrl: imageUrl,
      heightDm: data['height'] as int,
      weightHg: data['weight'] as int,
      types: types,
      abilities: abilities,
      stats: stats,
    );
  }
}
