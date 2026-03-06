import 'package:equatable/equatable.dart';
import '../../domain/entities/search_result.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitialState extends SearchState {}

class SearchLoadingState extends SearchState {
  final List<SearchResult> currentResults;
  final int filesDiscovered;
  final int filesProcessed;
  final int totalFilesToSearch;
  final bool isDiscovering;
  final String statusText;

  const SearchLoadingState({
    required this.currentResults,
    required this.filesDiscovered,
    required this.filesProcessed,
    required this.totalFilesToSearch,
    required this.isDiscovering,
    required this.statusText,
  });

  @override
  List<Object?> get props => [
    currentResults,
    filesDiscovered,
    filesProcessed,
    totalFilesToSearch,
    isDiscovering,
    statusText,
  ];

  SearchLoadingState copyWith({
    List<SearchResult>? currentResults,
    int? filesDiscovered,
    int? filesProcessed,
    int? totalFilesToSearch,
    bool? isDiscovering,
    String? statusText,
  }) {
    return SearchLoadingState(
      currentResults: currentResults ?? this.currentResults,
      filesDiscovered: filesDiscovered ?? this.filesDiscovered,
      filesProcessed: filesProcessed ?? this.filesProcessed,
      totalFilesToSearch: totalFilesToSearch ?? this.totalFilesToSearch,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      statusText: statusText ?? this.statusText,
    );
  }
}

class SearchDoneState extends SearchState {
  final List<SearchResult> results;
  const SearchDoneState(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchErrorState extends SearchState {
  final String message;
  const SearchErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
