# Modern Go - Agent Guidelines

Welcome, agent! This file contains the project's build, lint, and test commands, as well as code style guidelines. Please adhere to these rules when working in this repository.

## 1. Build, Lint, and Test Commands

### Setup
- Get dependencies: `flutter pub get`
- Clean project: `flutter clean && flutter pub get`

### Linting & Formatting
- Analyze code (check for errors/warnings): `flutter analyze`
- Format code: `dart format lib test`
- Check formatting without applying: `dart format --output=none --set-exit-if-changed .`

### Testing
- Run all tests: `flutter test`
- Run a single test file: `flutter test path/to/test_file.dart`
- Run a specific test within a file: `flutter test path/to/test_file.dart --plain-name "Test Name"`
- Run tests with coverage: `flutter test --coverage` (generates `coverage/lcov.info`)

### Building
- Build Android APK: `flutter build apk`
- Build Android App Bundle: `flutter build appbundle`
- Build iOS (requires macOS): `flutter build ios`

## 2. Code Style & Architecture Guidelines

### Architecture
- The project follows a feature-first, Clean Architecture approach inside the `lib/` directory:
  - `lib/core/`: Contains shared resources, API clients, constants, themes, and utility classes.
  - `lib/features/`: Contains specific features (e.g., `auth`, `cart`, `home`).
    - Each feature should typically be divided into:
      - `data/`: Models, Repositories implementations, Data Sources (local/remote).
      - `domain/`: Entities, Repository interfaces, Use Cases.
      - `presentation/`: BLoC/Cubit state management, Pages, and Widgets.

### State Management & Dependency Injection
- Use **flutter_bloc** for state management.
- Use **get_it** for dependency injection. Register dependencies in `lib/main.dart` or a dedicated service locator file.

### Formatting & Syntax
- Follow the official Dart formatting guidelines. Use `dart format` before committing.
- Prefer single quotes for strings (`'...'`) unless the string contains a single quote.
- Avoid using `print` in production code. Use a logging framework or remove debug prints. (Note: `avoid_print` is currently not strictly enforced in `analysis_options.yaml`, but it's a best practice).

### Imports
- Organize imports in the following order:
  1. `dart:` imports
  2. `package:` imports (e.g., Flutter framework, third-party packages)
  3. Relative imports (e.g., `core/...`, `features/...`)
- Prefer relative imports for files within the `lib` directory to maintain portability.

### Naming Conventions
- **Classes, Enums, Typedefs:** `PascalCase` (e.g., `HomeRepositoryImpl`, `UserRole`).
- **Files, Directories:** `snake_case` (e.g., `home_repository_impl.dart`, `auth_bloc.dart`).
- **Variables, Functions, Methods:** `camelCase` (e.g., `fetchUserData`, `isLoggedIn`).
- **Constants:** `camelCase` or `SCREAMING_SNAKE_CASE` (follow existing patterns in `lib/core/constants/`).

### Error Handling
- Use the `dartz` package for functional error handling, returning `Either<Failure, Success>` from repositories.
- Define custom exceptions and failures in `lib/core/error/`.
- Handle network errors gracefully using `dio` interceptors or try-catch blocks in the data layer.

### UI & Styling
- Use Material 3 design principles as configured in `ThemeData(useMaterial3: true)`.
- Use `GoogleFonts.poppinsTextTheme()` for typography.
- Extract colors to `lib/core/constants/app_colors.dart`.
- Build responsive UIs and avoid hardcoded dimensions where possible.

### Domain Specific Rules
- **Store Cards:** When a store card is opened, it should display its products by fetching them from the `/stores/:storeId/products` endpoint. The backend returns a list of `storeProducts` which includes populated `productId` details from the `Product` model.

### General Agent Rules
- Always read existing files (`read` tool) before modifying them (`edit` tool) to understand context.
- Try to use the `edit` tool to make targeted changes rather than rewriting entire files with `write`.
- When writing tests, mimic the style of existing tests in the `test/` directory.
- Never commit secrets or API keys.
