import 'dart:async';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/search_params.dart';
import '../../domain/entities/search_update.dart';
import '../../domain/errors/failures.dart';
import '../../domain/repositories/i_search_repository.dart';
import '../datasources/local_search_datasource.dart';

class SearchRepositoryImpl implements ISearchRepository {
  final LocalSearchDatasource datasource;

  SearchRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, Stream<SearchUpdate>>> searchFiles(
    SearchParams params,
  ) async {
    try {
      final resultStream = await datasource.searchInParallel(params);
      return Right(resultStream);
    } catch (e) {
      return Left(
        SearchFailure('Erro interno ao iniciar a busca: ${e.toString()}'),
      );
    }
  }
}
