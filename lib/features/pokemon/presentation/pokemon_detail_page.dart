import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/connectivity_banner.dart';
import '../../../core/widgets/error_view.dart';
import '../../favorites/presentation/favorites_provider.dart';
import '../domain/entities/pokemon_detail.dart';
import '../domain/pokemon_repository.dart';
import 'pokemon_detail_provider.dart';
import 'pokemon_list_provider.dart' show LoadStatus;

class PokemonDetailPage extends StatelessWidget {
  final int pokemonId;

  const PokemonDetailPage({super.key, required this.pokemonId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          PokemonDetailProvider(context.read<PokemonRepository>(), pokemonId)..load(),
      child: const _PokemonDetailView(),
    );
  }
}

class _PokemonDetailView extends StatelessWidget {
  const _PokemonDetailView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PokemonDetailProvider>(
      builder: (context, provider, _) {
        final detail = provider.detail;
        return Scaffold(
          appBar: AppBar(
            title: Text(detail == null ? 'Détail' : '#${detail.id} ${detail.name}'),
            actions: [
              if (detail != null)
                Consumer<FavoritesProvider>(
                  builder: (context, favorites, _) {
                    final isFavorite = favorites.isFavorite(detail.id);
                    return IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => favorites.toggle(
                        pokemonId: detail.id,
                        name: detail.name,
                        imageUrl: detail.imageUrl,
                      ),
                    );
                  },
                ),
            ],
          ),
          body: ConnectivityBanner(
            child: Builder(builder: (context) {
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
                  return _DetailBody(detail: detail!);
              }
            }),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PokemonDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Image.network(
            detail.imageUrl,
            height: 160,
            errorBuilder: (_, _, _) => const Icon(Icons.catching_pokemon, size: 96),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final type in detail.types)
              Chip(label: Text(type)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatTile(label: 'Taille', value: '${detail.heightMeters} m'),
            _StatTile(label: 'Poids', value: '${detail.weightKg} kg'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Capacités', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: [
            for (final ability in detail.abilities)
              Chip(label: Text(ability)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Statistiques', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in detail.stats.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 110, child: Text(entry.key)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (entry.value / 200).clamp(0, 1).toDouble(),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
