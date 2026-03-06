import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/local_search_datasource.dart';
import 'data/repositories/search_repository_impl.dart';
import 'domain/repositories/i_search_repository.dart';
import 'domain/usecases/search_files_usecase.dart';
import 'presentation/blocs/search_bloc.dart';
import 'presentation/blocs/theme_cubit.dart';

class InjecaoBase extends StatelessWidget {
  final Widget child;
  final SharedPreferences prefs;

  const InjecaoBase({super.key, required this.child, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: _providers(), child: child);
  }

  List<SingleChildWidget> _providers() {
    return [
      // DataSources
      Provider<LocalSearchDatasource>(create: (_) => LocalSearchDatasource()),
      // Repositories
      Provider<ISearchRepository>(
        create: (context) => SearchRepositoryImpl(
          datasource: context.read<LocalSearchDatasource>(),
        ),
      ),
      // UseCases
      Provider<SearchFilesUseCase>(
        create: (context) =>
            SearchFilesUseCase(repository: context.read<ISearchRepository>()),
      ),
      // Blocs
      Provider<SearchBloc>(
        create: (context) =>
            SearchBloc(searchFilesUseCase: context.read<SearchFilesUseCase>()),
      ),
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs: prefs)),
    ];
  }
}
