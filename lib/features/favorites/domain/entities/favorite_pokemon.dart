class FavoritePokemon {
  final int pokemonId;
  final String name;
  final String imageUrl;
  final DateTime addedAt;

  const FavoritePokemon({
    required this.pokemonId,
    required this.name,
    required this.imageUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'pokemonId': pokemonId,
        'name': name,
        'imageUrl': imageUrl,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoritePokemon.fromJson(Map<String, dynamic> json) => FavoritePokemon(
        pokemonId: json['pokemonId'] as int,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );

  /// Mapping depuis une ligne PostgREST (table `favorites` de Supabase).
  factory FavoritePokemon.fromSupabase(Map<String, dynamic> row) => FavoritePokemon(
        pokemonId: row['pokemon_id'] as int,
        name: row['pokemon_name'] as String,
        imageUrl: row['image_url'] as String,
        addedAt: DateTime.parse(row['created_at'] as String),
      );
}
