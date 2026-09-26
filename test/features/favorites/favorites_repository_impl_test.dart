import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokedex/core/errors/app_exception.dart';
import 'package:pokedex/core/network/network_info.dart';
import 'package:pokedex/features/favorites/data/favorites_local_data_source.dart';
import 'package:pokedex/features/favorites/data/favorites_remote_data_source.dart';
import 'package:pokedex/features/favorites/data/favorites_repository_impl.dart';
import 'package:pokedex/features/favorites/domain/entities/favorite_pokemon.dart';

class _MockRemote extends Mock implements FavoritesRemoteDataSource {}

class _MockLocal extends Mock implements FavoritesLocalDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetworkInfo networkInfo;
  late FavoritesRepositoryImpl repository;

  final favorite = FavoritePokemon(
    pokemonId: 25,
    name: 'pikachu',
    imageUrl: 'img/25.png',
    addedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(favorite);
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    networkInfo = _MockNetworkInfo();
    repository = FavoritesRepositoryImpl(remote: remote, local: local, networkInfo: networkInfo);
  });

  group('getFavorites', () {
    test('returns remote favorites and caches them when online', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.fetchFavorites()).thenAnswer((_) async => [favorite]);
      when(() => local.cacheFavorites(any())).thenAnswer((_) async {});

      final result = await repository.getFavorites();

      expect(result, [favorite]);
      verify(() => local.cacheFavorites([favorite])).called(1);
    });

    test('returns cached favorites when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => local.getCachedFavorites()).thenReturn([favorite]);

      final result = await repository.getFavorites();

      expect(result, [favorite]);
      verifyNever(() => remote.fetchFavorites());
    });

    test('throws AppException when offline with nothing cached', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => local.getCachedFavorites()).thenReturn(null);

      expect(() => repository.getFavorites(), throwsA(isA<AppException>()));
    });
  });

  group('addFavorite', () {
    test('refuses to add a favorite while offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      expect(() => repository.addFavorite(favorite), throwsA(isA<AppException>()));
      verifyNever(() => remote.addFavorite(any()));
    });

    test('translates a 401 response into an unauthorized AppException', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.addFavorite(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 401),
        ),
      );

      expect(
        () => repository.addFavorite(favorite),
        throwsA(isA<AppException>().having((e) => e.message, 'message', contains('reconnecter'))),
      );
    });
  });
}
