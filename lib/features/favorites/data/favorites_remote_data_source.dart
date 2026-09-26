import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/favorite_pokemon.dart';

/// Accède à la table `favorites` de Supabase via son API REST (PostgREST),
/// en passant par notre propre [Dio] (donc par [AuthInterceptor]) plutôt que
/// par le query builder du SDK supabase_flutter.
abstract class FavoritesRemoteDataSource {
  Future<List<FavoritePokemon>> fetchFavorites();
  Future<void> addFavorite(FavoritePokemon favorite);
  Future<void> removeFavorite(int pokemonId);
}

class SupabaseFavoritesRemoteDataSource implements FavoritesRemoteDataSource {
  final Dio dio;

  SupabaseFavoritesRemoteDataSource(this.dio);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Future<List<FavoritePokemon>> fetchFavorites() async {
    final response = await dio.get(
      'favorites',
      queryParameters: {'select': '*', 'order': 'created_at.desc'},
    );
    final rows = List<Map<String, dynamic>>.from(response.data as List);
    return rows.map(FavoritePokemon.fromSupabase).toList();
  }

  @override
  Future<void> addFavorite(FavoritePokemon favorite) async {
    await dio.post(
      'favorites',
      options: Options(headers: {'Prefer': 'return=minimal'}),
      data: {
        'user_id': _userId,
        'pokemon_id': favorite.pokemonId,
        'pokemon_name': favorite.name,
        'image_url': favorite.imageUrl,
      },
    );
  }

  @override
  Future<void> removeFavorite(int pokemonId) async {
    await dio.delete(
      'favorites',
      queryParameters: {'pokemon_id': 'eq.$pokemonId'},
    );
  }
}
