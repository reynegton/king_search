import 'search_result.dart';

abstract class SearchUpdate {}

class SearchDiscoveryProgress extends SearchUpdate {
  final int filesDiscovered;
  SearchDiscoveryProgress(this.filesDiscovered);
}

class SearchPreProcessDone extends SearchUpdate {
  final int totalFilesToSearch;
  SearchPreProcessDone(this.totalFilesToSearch);
}

class SearchScanningProgress extends SearchUpdate {
  final int filesProcessed;
  SearchScanningProgress(this.filesProcessed);
}

class SearchResultMatch extends SearchUpdate {
  final SearchResult result;
  SearchResultMatch(this.result);
}
