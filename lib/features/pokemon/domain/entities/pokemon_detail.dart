import 'package:equatable/equatable.dart';

/// Détail complet d'un pokémon (écran de détail).
class PokemonDetail extends Equatable {
  final int id;
  final String name;
  final String imageUrl;
  final int heightDm;
  final int weightHg;
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.heightDm,
    required this.weightHg,
    required this.types,
    required this.abilities,
    required this.stats,
  });

  double get heightMeters => heightDm / 10;
  double get weightKg => weightHg / 10;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'heightDm': heightDm,
        'weightHg': weightHg,
        'types': types,
        'abilities': abilities,
        'stats': stats,
      };

  factory PokemonDetail.fromJson(Map<String, dynamic> json) => PokemonDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        heightDm: json['heightDm'] as int,
        weightHg: json['weightHg'] as int,
        types: List<String>.from(json['types'] as List),
        abilities: List<String>.from(json['abilities'] as List),
        stats: Map<String, int>.from(json['stats'] as Map),
      );

  @override
  List<Object?> get props =>
      [id, name, imageUrl, heightDm, weightHg, types, abilities, stats];
}
