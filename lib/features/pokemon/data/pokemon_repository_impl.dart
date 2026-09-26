import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/network_info.dart';
import '../domain/entities/pokemon.dart';
import '../domain/entities/pokemon_detail.dart';
import '../domain/pokemon_repository.dart';
import 'pokemon_local_data_source.dart';
import 'pokemon_remote_data_source.dart';

class PokemonRepositoryImpl implements PokemonRepository {
  final PokemonRemoteDataSource remote;
  final PokemonLocalDataSource local;
  final NetworkInfo networkInfo;

  PokemonRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException.timeout();
      case DioExceptionType.connectionError:
        return AppException.network();
      default:
        if (e.response?.statusCode == 404) return AppException.notFound();
        if (e.response?.statusCode == 401) return AppException.unauthorized();
        if ((e.response?.statusCode ?? 0) >= 500) return AppException.server();
        return AppException.unknown(e);
    }
  }

  @override
  Future<List<Pokemon>> getPokemonList({int offset = 0, int limit = 20}) async {
    if (await networkInfo.isConnected) {
      try {
        final list = await remote.fetchList(offset: offset, limit: limit);
        await local.cacheList(list, offset: offset, limit: limit);
        return list;
      } on DioException catch (e) {
        final cached = local.getCachedList(offset: offset, limit: limit);
        if (cached != null) return cached;
        throw _mapDioException(e);
      }
    }

    final cached = local.getCachedList(offset: offset, limit: limit);
    if (cached != null) return cached;
    throw AppException.network();
  }

  @override
  Future<PokemonDetail> getPokemonDetail(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final detail = await remote.fetchDetail(id);
        await local.cacheDetail(detail);
        return detail;
      } on DioException catch (e) {
        final cached = local.getCachedDetail(id);
        if (cached != null) return cached;
        throw _mapDioException(e);
      }
    }

    final cached = local.getCachedDetail(id);
    if (cached != null) return cached;
    throw AppException.network();
  }
}
