import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokedex/core/errors/app_exception.dart';
import 'package:pokedex/core/network/network_info.dart';
import 'package:pokedex/features/pokemon/data/pokemon_local_data_source.dart';
import 'package:pokedex/features/pokemon/data/pokemon_remote_data_source.dart';
import 'package:pokedex/features/pokemon/data/pokemon_repository_impl.dart';
import 'package:pokedex/features/pokemon/domain/entities/pokemon.dart';

class _MockRemote extends Mock implements PokemonRemoteDataSource {}

class _MockLocal extends Mock implements PokemonLocalDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetworkInfo networkInfo;
  late PokemonRepositoryImpl repository;

  const pokemons = [Pokemon(id: 1, name: 'bulbasaur', imageUrl: 'img/1.png')];

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    networkInfo = _MockNetworkInfo();
    repository = PokemonRepositoryImpl(remote: remote, local: local, networkInfo: networkInfo);
  });

  group('getPokemonList', () {
    test('returns remote data and caches it when online', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.fetchList(offset: 0, limit: 20)).thenAnswer((_) async => pokemons);
      when(() => local.cacheList(any(), offset: 0, limit: 20)).thenAnswer((_) async {});

      final result = await repository.getPokemonList(offset: 0, limit: 20);

      expect(result, pokemons);
      verify(() => local.cacheList(pokemons, offset: 0, limit: 20)).called(1);
    });

    test('falls back to cache when online but the API call fails', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.fetchList(offset: 0, limit: 20)).thenThrow(
        DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionError),
      );
      when(() => local.getCachedList(offset: 0, limit: 20)).thenReturn(pokemons);

      final result = await repository.getPokemonList(offset: 0, limit: 20);

      expect(result, pokemons);
    });

    test('returns cached data when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => local.getCachedList(offset: 0, limit: 20)).thenReturn(pokemons);

      final result = await repository.getPokemonList(offset: 0, limit: 20);

      expect(result, pokemons);
      verifyNever(() => remote.fetchList(offset: any(named: 'offset'), limit: any(named: 'limit')));
    });

    test('throws AppException when offline and nothing is cached', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => local.getCachedList(offset: 0, limit: 20)).thenReturn(null);

      expect(
        () => repository.getPokemonList(offset: 0, limit: 20),
        throwsA(isA<AppException>()),
      );
    });
  });
}
