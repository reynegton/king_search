import 'package:equatable/equatable.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_update.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class RequestSearchEvent extends SearchEvent {
  final String directoryPath;
  final String query;
  final bool isCaseSensitive;
  final bool isRegExp;
  final bool isMultiline;
  final String extensionsText;

  const RequestSearchEvent({
    required this.directoryPath,
    required this.query,
    this.isCaseSensitive = false,
    this.isRegExp = false,
    this.isMultiline = false,
    this.extensionsText = "",
  });

  @override
  List<Object?> get props => [
    directoryPath,
    query,
    isCaseSensitive,
    isRegExp,
    isMultiline,
    extensionsText,
  ];
}

class CancelSearchEvent extends SearchEvent {}

// INTERNAL EVENTS (Para gerenciamento de subscrição de stream no BLoC)
class InternalSearchUpdateEvent extends SearchEvent {
  final SearchUpdate update;
  const InternalSearchUpdateEvent(this.update);

  @override
  List<Object?> get props => [update];
}

class InternalSearchDoneEvent extends SearchEvent {
  final List<SearchResult> results;
  const InternalSearchDoneEvent(this.results);

  @override
  List<Object?> get props => [results];
}

class InternalSearchErrorEvent extends SearchEvent {
  final String message;
  const InternalSearchErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}
