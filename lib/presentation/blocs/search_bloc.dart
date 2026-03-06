import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_params.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_update.dart';
import '../../domain/usecases/search_files_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchFilesUseCase searchFilesUseCase;
  StreamSubscription<SearchUpdate>? _searchSubscription;
  final List<SearchResult> _accumulatedResults = [];

  SearchBloc({required this.searchFilesUseCase}) : super(SearchInitialState()) {
    on<RequestSearchEvent>(_onRequestSearch);
    on<CancelSearchEvent>(_onCancelSearch);
    on<InternalSearchUpdateEvent>(_onSearchUpdate);
    on<InternalSearchDoneEvent>(_onSearchDone);
    on<InternalSearchErrorEvent>(_onSearchError);
  }

  Future<void> _onRequestSearch(
    RequestSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    _searchSubscription?.cancel();
    _accumulatedResults.clear();

    emit(
      const SearchLoadingState(
        currentResults: [],
        filesDiscovered: 0,
        filesProcessed: 0,
        totalFilesToSearch: 0,
        isDiscovering: true,
        statusText: 'Descobrindo arquivos: 0',
      ),
    );

    List<String> extList = [];
    if (event.extensionsText.trim().isNotEmpty &&
        event.extensionsText.trim() != '*') {
      extList = event.extensionsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      extList = extList.map((e) => e.startsWith('.') ? e : '.$e').toList();
    }

    final params = SearchParams(
      currentDirectory: Directory(event.directoryPath),
      query: event.query,
      isCaseSensitive: event.isCaseSensitive,
      isRegExp: event.isRegExp,
      isMultiline: event.isMultilineDfm,
      extensions: extList,
    );

    final result = await searchFilesUseCase(params);

    result.fold((failure) => add(InternalSearchErrorEvent(failure.message)), (
      stream,
    ) {
      _searchSubscription = stream.listen(
        (update) => add(InternalSearchUpdateEvent(update)),
        onDone: () =>
            add(InternalSearchDoneEvent(List.from(_accumulatedResults))),
        onError: (e) =>
            add(InternalSearchErrorEvent('Erro na leitura de Stream: $e')),
      );
    });
  }

  void _onSearchUpdate(
    InternalSearchUpdateEvent event,
    Emitter<SearchState> emit,
  ) {
    if (state is! SearchLoadingState) return;
    final currentState = state as SearchLoadingState;
    final update = event.update;

    if (update is SearchDiscoveryProgress) {
      emit(
        currentState.copyWith(
          filesDiscovered: update.filesDiscovered,
          statusText: 'Descobrindo arquivos: ${update.filesDiscovered}',
        ),
      );
    } else if (update is SearchPreProcessDone) {
      emit(
        currentState.copyWith(
          isDiscovering: false,
          totalFilesToSearch: update.totalFilesToSearch,
          statusText: 'Buscando nos arquivos: 0 / ${update.totalFilesToSearch}',
        ),
      );
    } else if (update is SearchScanningProgress) {
      emit(
        currentState.copyWith(
          filesProcessed: update.filesProcessed,
          statusText:
              'Buscando nos arquivos: ${update.filesProcessed} / ${currentState.totalFilesToSearch}',
        ),
      );
    } else if (update is SearchResultMatch) {
      _accumulatedResults.add(update.result);
      emit(
        currentState.copyWith(currentResults: List.from(_accumulatedResults)),
      );
    }
  }

  void _onSearchDone(InternalSearchDoneEvent event, Emitter<SearchState> emit) {
    _searchSubscription?.cancel();
    emit(SearchDoneState(event.results));
  }

  void _onSearchError(
    InternalSearchErrorEvent event,
    Emitter<SearchState> emit,
  ) {
    _searchSubscription?.cancel();
    emit(SearchErrorState(event.message));
  }

  void _onCancelSearch(CancelSearchEvent event, Emitter<SearchState> emit) {
    _searchSubscription?.cancel();
    if (state is SearchLoadingState) {
      emit(SearchDoneState(List.from(_accumulatedResults)));
    } else {
      emit(SearchInitialState());
    }
  }

  @override
  Future<void> close() {
    _searchSubscription?.cancel();
    return super.close();
  }
}
