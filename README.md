# Kyng Search 🔍

**Kyng Search** é um buscador de arquivos poderoso e performático desenvolvido em Flutter, projetado para localizar textos dentro de documentos de forma rápida e eficiente. Com uma arquitetura robusta e processamento paralelo, ele oferece uma experiência fluida mesmo em diretórios com milhares de arquivos.

## 🚀 Funcionalidades

- **Busca em Tempo Real**: Contador de descoberta de arquivos que atualiza instantaneamente para que você saiba exatamente o progresso da varredura.
- **Processamento Paralelo**: Utiliza `Isolates` do Dart para realizar a busca em múltiplos núcleos, garantindo que a interface do usuário nunca trave.
- **Filtros Flexíveis**:
  - **Extensões**: Filtre por tipos específicos (ex: `.txt, .dart, .cs`) ou use `*` para buscar em tudo. O sistema limpa automaticamente entradas como `*.txt`.
  - **Case Sensitive**: Diferencie maiúsculas de minúsculas.
  - **Regex (Expressões Regulares)**: Suporte completo para padrões complexos de busca.
  - **Ignorar Quebras de String**: Especialmente útil para arquivos que utilizam quebras de linha em textos longos (comum em arquivos `.dfm`).
- **Multiplataforma**: Suporte nativo para **Windows** e **Linux**.

## 🛠️ Tecnologias Utilizadas

- **Core**: [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- **Gerenciamento de Estado**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Padrão BLoC)
- **Arquitetura**: Clean Architecture (Domain, Data, Presentation)
- **Injeção de Dependência**: Provider / InjecaoBase
- **Tratamento Funcional**: [fpdart](https://pub.dev/packages/fpdart) (Uso de `Either` para erros)
- **Serialização e Utilitários**:
  - `path`: Manipulação de caminhos de arquivos.
  - `shared_preferences`: Persistência de configurações locais.
  - `equatable`: Comparação de estados e eventos.

## 📦 Como Rodar o Projeto

### Pré-requisitos
- Flutter SDK instalado.
- Ambiente configurado para a plataforma de destino (C++ para Windows/Linux, Android Studio para Android).

### Passos
1. Clone o repositório.
2. No terminal, execute:
   ```bash
   flutter pub get
   ```
3. Para rodar o aplicativo:
   ```bash
   flutter run
   ```

## 🏗️ Estrutura do Projeto

O projeto segue os princípios da **Clean Architecture**:

- `lib/domain`: Regras de negócio puras (Entities, UseCases, Repository Interfaces).
- `lib/data`: Implementações (Repositories, DataSources, Models).
- `lib/presentation`: Camada de UI (Blocs, Screens, Widgets).

## 🖥️ Configurações de Build

### Windows (MSIX)
O projeto está configurado para gerar instaladores MSIX:
```bash
flutter pub run msix:create
```

### Ícones
Para regenerar os ícones das plataformas:
```bash
flutter pub run flutter_launcher_icons
```

---
Desenvolvido por **Reynegton Nunes**.
