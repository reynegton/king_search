import 'package:fpdart/fpdart.dart';

import '../entities/search_params.dart';
import '../entities/search_update.dart';
import '../errors/failures.dart';

abstract class ISearchRepository {
  Future<Either<Failure, Stream<SearchUpdate>>> searchFiles(
    SearchParams params,
  );
}
