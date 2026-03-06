import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/search_bloc.dart';
import '../blocs/search_event.dart';
import '../blocs/search_state.dart';
import '../blocs/theme_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dirController = TextEditingController();
  final _queryController = TextEditingController();
  final _extController = TextEditingController();

  bool _isCaseSensitive = false;
  bool _isRegExp = false;
  bool _isMultilineDfm = true;

  @override
  void initState() {
    super.initState();
    _extController.text = '*';
  }

  @override
  void dispose() {
    _dirController.dispose();
    _queryController.dispose();
    _extController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('King Search'), elevation: 2),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Configurações',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text('Modo Escuro'),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  value: isDark,
                  onChanged: (value) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// FILTROS E PESQUISA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dirController,
                            decoration: const InputDecoration(
                              labelText: 'Diretório Raíz',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pickDirectory,
                          icon: const Icon(Icons.folder),
                          label: const Text('Procurar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _queryController,
                            decoration: const InputDecoration(
                              labelText: 'Texto ou (RegExp) a buscar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _extController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Extensões (* para todas) use virgual para separar várias',
                              hintText: 'Ex: .txt, .dfm',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CheckboxMenuButton(
                          value: _isCaseSensitive,
                          onChanged: (v) =>
                              setState(() => _isCaseSensitive = v!),
                          child: const Text('Case Sensitive (Aa)'),
                        ),
                        Tooltip(
                          message: 'Não pode ser usado com Ignore Quebras',
                          child: CheckboxMenuButton(
                            value: _isRegExp,
                            onChanged: _isMultilineDfm
                                ? null
                                : (v) => setState(() => _isRegExp = v!),
                            child: const Text('Usar Expressão Regular (.*)'),
                          ),
                        ),
                        Tooltip(
                          message:
                              'Busca a palavra mesmo se ela estiver com quebra de código (String Break)',
                          child: CheckboxMenuButton(
                            value: _isMultilineDfm,
                            onChanged: _isRegExp
                                ? null
                                : (v) => setState(() => _isMultilineDfm = v!),
                            child: const Text('Ignorar Quebras de String'),
                          ),
                        ),
                        const Spacer(),
                        BlocBuilder<SearchBloc, SearchState>(
                          builder: (context, state) {
                            if (state is SearchLoadingState) {
                              return ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                                onPressed: () {
                                  context.read<SearchBloc>().add(
                                    CancelSearchEvent(),
                                  );
                                },
                                icon: Icon(
                                  Icons.stop,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                label: Text(
                                  'Parar Busca',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              );
                            }
                            return ElevatedButton.icon(
                              onPressed: () {
                                context.read<SearchBloc>().add(
                                  RequestSearchEvent(
                                    directoryPath: _dirController.text,
                                    query: _queryController.text,
                                    isCaseSensitive: _isCaseSensitive,
                                    isRegExp: _isRegExp,
                                    isMultilineDfm: _isMultilineDfm,
                                    extensionsText:
                                        _extController.text.trim().isEmpty
                                        ? "*"
                                        : _extController.text,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Pesquisar em Todos'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// MOSTRADOR DE STATUS E RESULTADOS
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchErrorState) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Erro: ${state.message}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                if (state is SearchLoadingState) {
                  return _buildResultsList(
                    state.currentResults,
                    state.statusText,
                    true,
                  );
                } else if (state is SearchDoneState) {
                  return _buildResultsList(
                    state.results,
                    'Busca finalizada! ${state.results.length} ocorrências',
                    false,
                  );
                }

                return const Expanded(
                  child: Center(
                    child: Text('Selecione os filtros e inicie uma busca.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    List currentResults,
    String headerText,
    bool isLoading,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (isLoading) const SizedBox(width: 8),
              if (isLoading)
                Text(
                  headerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                Text(
                  headerText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                itemCount: currentResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = currentResults[index];
                  return ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.file.path,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Abrir no Gerenciador de Arquivos',
                          onPressed: () =>
                              _openFileInExplorer(result.file.path),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Linha ${result.lineNumber}:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.textContext,
                            style: const TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      setState(() {
        _dirController.text = directoryPath;
      });
    }
  }

  void _openFileInExplorer(String path) {
    if (Platform.isWindows) {
      Process.run('explorer.exe', ['/select,', path]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [File(path).parent.path]);
    }
  }
}
