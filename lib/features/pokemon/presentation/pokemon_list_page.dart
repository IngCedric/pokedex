import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/connectivity_banner.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../favorites/presentation/favorites_provider.dart';
import 'pokemon_detail_page.dart';
import 'pokemon_list_provider.dart';

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  State<PokemonListPage> createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PokemonListProvider>().loadFirstPage();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PokemonListProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: ConnectivityBanner(
        child: Consumer<PokemonListProvider>(
          builder: (context, provider, _) {
            switch (provider.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LoadStatus.error:
                return ErrorView(
                  message: provider.errorMessage ?? 'Erreur inconnue',
                  onRetry: provider.loadFirstPage,
                );
              case LoadStatus.loaded:
                return RefreshIndicator(
                  onRefresh: provider.loadFirstPage,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: provider.pokemons.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.pokemons.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final pokemon = provider.pokemons[index];
                      return _PokemonCard(
                        id: pokemon.id,
                        name: pokemon.name,
                        imageUrl: pokemon.imageUrl,
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

class _PokemonCard extends StatelessWidget {
  final int id;
  final String name;
  final String imageUrl;

  const _PokemonCard({required this.id, required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PokemonDetailPage(pokemonId: id)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.network(
                    imageUrl,
                    errorBuilder: (_, _, _) => const Icon(Icons.catching_pokemon, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '#$id ${name[0].toUpperCase()}${name.substring(1)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : null,
                ),
                onPressed: () async {
                  try {
                    await favorites.toggle(pokemonId: id, name: name, imageUrl: imageUrl);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(favorites.errorMessage ?? 'Erreur')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
