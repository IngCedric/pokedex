import 'package:flutter/material.dart';

import '../features/favorites/presentation/favorites_page.dart';
import '../features/pokemon/presentation/pokemon_list_page.dart';

/// Coquille avec navigation par onglets (Pokédex / Favoris).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [PokemonListPage(), FavoritesPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.catching_pokemon), label: 'Pokédex'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoris'),
        ],
      ),
    );
  }
}
