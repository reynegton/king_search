import 'dart:io';

class SearchParams {
  final Directory currentDirectory;
  final String query;
  final bool isCaseSensitive;
  final bool isRegExp;
  final bool isMultiline;
  final List<String> extensions;

  SearchParams({
    required this.currentDirectory,
    this.query = '',
    this.isCaseSensitive = false,
    this.isRegExp = false,
    this.isMultiline = false,
    this.extensions = const [],
  });
}
