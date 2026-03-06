import 'dart:io';

class SearchResult {
  final File file;
  final int lineNumber;
  final String textContext;

  SearchResult({
    required this.file,
    required this.lineNumber,
    required this.textContext,
  });
}
