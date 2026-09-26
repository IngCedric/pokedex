import 'package:hive_flutter/hive_flutter.dart';

/// Noms des boxes Hive utilisées pour le cache local (mode hors-ligne).
///
/// On stocke volontairement des `Map<String, dynamic>` bruts (JSON) plutôt
/// que des objets typés générés par build_runner: cela évite d'ajouter un
/// TypeAdapter par entité pour un besoin de cache simple.
class HiveBoxes {
  static const pokemonList = 'pokemon_list_cache';
  static const pokemonDetail = 'pokemon_detail_cache';
  static const favorites = 'favorites_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(pokemonList),
      Hive.openBox(pokemonDetail),
      Hive.openBox(favorites),
    ]);
  }
}
