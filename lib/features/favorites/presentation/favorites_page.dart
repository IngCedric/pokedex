import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/connectivity_banner.dart';
import '../../../core/widgets/error_view.dart';
import '../../pokemon/presentation/pokemon_detail_page.dart';
import '../../pokemon/presentation/pokemon_list_provider.dart' show LoadStatus;
import 'favorites_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: ConnectivityBanner(
        child: Consumer<FavoritesProvider>(
          builder: (context, provider, _) {
            switch (provider.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LoadStatus.error:
                return ErrorView(
                  message: provider.errorMessage ?? 'Erreur inconnue',
                  onRetry: provider.load,
                );
              case LoadStatus.loaded:
                if (provider.favorites.isEmpty) {
                  return const Center(child: Text('Aucun favori pour le moment.'));
                }
                return RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    itemCount: provider.favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = provider.favorites[index];
                      return ListTile(
                        leading: Image.network(
                          favorite.imageUrl,
                          width: 48,
                          errorBuilder: (_, _, _) => const Icon(Icons.catching_pokemon),
                        ),
                        title: Text(
                          '#${favorite.pokemonId} ${favorite.name[0].toUpperCase()}${favorite.name.substring(1)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.redAccent),
                          onPressed: () => provider.toggle(
                            pokemonId: favorite.pokemonId,
                            name: favorite.name,
                            imageUrl: favorite.imageUrl,
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PokemonDetailPage(pokemonId: favorite.pokemonId),
                          ),
                        ),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
