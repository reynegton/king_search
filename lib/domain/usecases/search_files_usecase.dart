import 'package:fpdart/fpdart.dart';

import '../entities/search_params.dart';
import '../entities/search_update.dart';
import '../errors/failures.dart';
import '../repositories/i_search_repository.dart';

class SearchFilesUseCase {
  final ISearchRepository repository;

  SearchFilesUseCase({required this.repository});

  Future<Either<Failure, Stream<SearchUpdate>>> call(
    SearchParams params,
  ) async {
    if (!params.currentDirectory.existsSync()) {
      return Left(
        SearchFailure('A pasta selecionada não existe ou foi removida.'),
      );
    }

    if (params.query.trim().isEmpty) {
      return Left(SearchFailure('Digite um termo para pesquisar.'));
    }

    if (params.isRegExp && params.isMultiline) {
      return Left(
        SearchFailure(
          'A busca Expressão Regular e a busca Igora Quebras não podem ser usadas ao mesmo tempo.',
        ),
      );
    }

    // Validar formatação da expressão regular
    if (params.isRegExp) {
      try {
        RegExp(
          params.query,
          caseSensitive: params.isCaseSensitive,
          multiLine: true,
        );
      } catch (e) {
        return Left(SearchFailure('A Expressão Regular fornecida é inválida.'));
      }
    }

    return repository.searchFiles(params);
  }
}
