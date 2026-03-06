import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

import '../../domain/entities/search_params.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_update.dart';

class _SearchWorkerParams {
  final SendPort sendPort;
  final List<String> filesToProcess;
  final SearchParams searchParams;

  _SearchWorkerParams(this.sendPort, this.filesToProcess, this.searchParams);
}

class LocalSearchDatasource {
  Future<Stream<SearchUpdate>> searchInParallel(SearchParams params) async {
    bool isCancelled = false;
    late StreamController<SearchUpdate> controller;

    controller = StreamController<SearchUpdate>(
      onCancel: () {
        isCancelled = true;
      },
    );

    List<String> discoveredFiles = [];
    int totalDiscovered = 0;

    // Phase 1: Descobrir Arquivos
    final dir = params.currentDirectory;
    final validExtensions = params.extensions
        .map((e) => e.toLowerCase())
        .toSet();

    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (isCancelled) {
          controller.close();
          return controller.stream;
        }

        if (entity is File) {
          if (validExtensions.isNotEmpty && !validExtensions.contains('*')) {
            final ext = p.extension(entity.path).toLowerCase();
            if (!validExtensions.contains(ext)) {
              continue;
            }
          }
          discoveredFiles.add(entity.path);
          totalDiscovered++;
          if (totalDiscovered % 100 == 0) {
            controller.add(SearchDiscoveryProgress(totalDiscovered));
            // Cede controle ao event loop para que a UI possa ser atualizada
            await Future.delayed(Duration.zero);
          }
        }
      }
    } catch (e) {
      controller.addError(e);
      controller.close();
      return controller.stream;
    }

    controller.add(SearchPreProcessDone(totalDiscovered));

    if (discoveredFiles.isEmpty) {
      controller.close();
      return controller.stream;
    }

    // Phase 2: Distribuir nos Isolates (Pool Controlado)
    final int processorCount = Platform.numberOfProcessors > 2
        ? Platform.numberOfProcessors - 1
        : 1;
    final int batchSize = 100;

    int activeWorkers = 0;
    int filesProcessedTotal = 0;
    int currentBatchIndex = 0;

    void dispatchNextBatch() {
      if (isCancelled || controller.isClosed) return;

      if (currentBatchIndex >= discoveredFiles.length) {
        if (activeWorkers == 0 && !controller.isClosed) {
          controller.close();
        }
        return;
      }

      int end = currentBatchIndex + batchSize;
      if (end > discoveredFiles.length) end = discoveredFiles.length;

      final batch = discoveredFiles.sublist(currentBatchIndex, end);
      currentBatchIndex = end;

      activeWorkers++;
      final receivePort = ReceivePort();

      final workerParams = _SearchWorkerParams(
        receivePort.sendPort,
        batch,
        params,
      );

      Isolate.spawn(_workerEntrypoint, workerParams).then((_) {
        receivePort.listen(
          (message) {
            if (message is SearchResult) {
              if (!controller.isClosed) {
                controller.add(SearchResultMatch(message));
              }
            } else if (message is int) {
              filesProcessedTotal += message;
              if (!controller.isClosed) {
                controller.add(SearchScanningProgress(filesProcessedTotal));
              }
            } else if (message == "DONE") {
              receivePort.close();
              activeWorkers--;
              dispatchNextBatch(); // Lança o próximo quando liberar um
            }
          },
          onError: (e) {
            activeWorkers--;
            dispatchNextBatch();
          },
        );
      });
    }

    // Inicializa o Pool até o limite (processorCount)
    for (int i = 0; i < processorCount; i++) {
      if (currentBatchIndex < discoveredFiles.length) {
        dispatchNextBatch();
      }
    }

    if (activeWorkers == 0 && !controller.isClosed) {
      controller.close();
    }

    return controller.stream;
  }

  static void _workerEntrypoint(_SearchWorkerParams params) {
    try {
      int processedInThisWorker = 0;
      for (final filePath in params.filesToProcess) {
        final file = File(filePath);
        processedInThisWorker++;

        if (_isBinaryFile(file)) {
          continue;
        }

        final content = file.readAsStringSync(encoding: const SystemEncoding());
        final matches = _findMatches(content, params.searchParams);

        for (final m in matches) {
          params.sendPort.send(
            SearchResult(
              file: file,
              lineNumber: m.lineNumber,
              textContext: m.context,
            ),
          );
        }

        // Reporta progresso do arquivo processado
        if (processedInThisWorker % 10 == 0) {
          params.sendPort.send(10); // envia que processou mais 10
          processedInThisWorker = 0;
        }
      }

      if (processedInThisWorker > 0) {
        params.sendPort.send(processedInThisWorker);
      }
    } catch (_) {
    } finally {
      params.sendPort.send("DONE");
    }
  }

  static bool _isBinaryFile(File file) {
    try {
      final handle = file.openSync(mode: FileMode.read);
      final bytes = handle.readSync(512);
      handle.closeSync();

      for (final byte in bytes) {
        if (byte == 0x00) return true;
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static List<_InternalMatch> _findMatches(String content, SearchParams p) {
    final results = <_InternalMatch>[];
    final lines = content.split('\n');

    if (p.isMultiline) {
      List<String> chars = p.query.split('');
      String breakPattern =
          r"(?:'[ \t]*\+[ \t]*\r?\n[ \t]*'|'[ \t]*\+[ \t]*')?";
      String regexString = chars
          .map((c) => RegExp.escape(c))
          .join(breakPattern);

      RegExp regex = RegExp(
        regexString,
        caseSensitive: p.isCaseSensitive,
        multiLine: true,
      );
      for (final match in regex.allMatches(content)) {
        final lineNum = _calculateLineNumberFromIndex(content, match.start);
        results.add(_InternalMatch(lineNum, _extractContext(lines, lineNum)));
      }
    } else if (p.isRegExp) {
      RegExp regex = RegExp(
        p.query,
        caseSensitive: p.isCaseSensitive,
        multiLine: true,
      );
      for (final match in regex.allMatches(content)) {
        final lineNum = _calculateLineNumberFromIndex(content, match.start);
        results.add(_InternalMatch(lineNum, _extractContext(lines, lineNum)));
      }
    } else {
      int index = 0;
      String searchSource = p.isCaseSensitive ? content : content.toLowerCase();
      String query = p.isCaseSensitive ? p.query : p.query.toLowerCase();

      while ((index = searchSource.indexOf(query, index)) != -1) {
        final lineNum = _calculateLineNumberFromIndex(content, index);
        results.add(_InternalMatch(lineNum, _extractContext(lines, lineNum)));
        index += query.length;
      }
    }

    return results;
  }

  static int _calculateLineNumberFromIndex(String content, int index) {
    int line = 1;
    for (int i = 0; i < index && i < content.length; i++) {
      if (content[i] == '\n') line++;
    }
    return line;
  }

  static String _extractContext(List<String> lines, int lineNumber) {
    if (lines.isEmpty) return "";
    int realIndex = lineNumber - 1;
    if (realIndex < 0) realIndex = 0;
    if (realIndex >= lines.length) realIndex = lines.length - 1;

    String lineContent = lines[realIndex].trim();
    if (lineContent.length > 200) {
      return '${lineContent.substring(0, 200)}...';
    }
    return lineContent;
  }
}

class _InternalMatch {
  final int lineNumber;
  final String context;
  _InternalMatch(this.lineNumber, this.context);
}
