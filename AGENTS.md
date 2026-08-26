# Repository Guidelines

## Project Structure & Module Organization

The Flutter application lives in `wnovel/`. Its Dart entry point is `wnovel/lib/main.dart`; application code is organized into `models/`, Riverpod `providers/`, data/integration `services/`, and `ui/screens/` plus reusable `ui/widgets/`. Worker implementations and generated worker bindings are under `lib/services/worker/`. Tests are in `wnovel/test/` (for example, `widget_test.dart`), and platform runners/assets are in `wnovel/android`, `ios`, `macos`, `linux`, `windows`, and `web`.

The PocketBase server configuration is in `backend/`, with JavaScript hooks in `backend/pb_hooks/` and migrations in `backend/pb_migrations/`. Do not commit `backend/pb_data/` or local PocketBase binaries. `GEMINI.md` and `.agents/rules/` contain additional architecture and state-ownership guidance.

## Build, Test, and Development Commands

Run Flutter commands from `wnovel/`:

```bash
flutter pub get                                      # Install dependencies
flutter run                                          # Run on a connected/default device
flutter analyze                                      # Run Dart/Flutter lints
dart format .                                        # Format Dart sources
flutter test                                         # Run the test suite
dart run build_runner build --delete-conflicting-outputs  # Regenerate worker/codegen output
```

Configure `wnovel/.env` with the required `PB_URL` before running; it is loaded as a Flutter asset. Start the local PocketBase service separately when integration features require it.

## Coding Style & Naming Conventions

Use standard Dart formatting (`dart format .`), two-space indentation, null safety, and the lints enabled by `analysis_options.yaml`. Use `snake_case.dart` filenames, `PascalCase` types/widgets, `camelCase` members, and `lowerCamelCase` Riverpod provider names. Prefer `const` widgets, immutable state, and existing Riverpod/provider patterns. Keep business and API logic in providers/services rather than embedding it in widgets; avoid editing generated `*.g.dart` files manually.

## Testing Guidelines

Tests use Flutter’s `flutter_test` framework. Name files with the `_test.dart` suffix and group tests by the behavior or feature they cover. Run `flutter analyze` and `flutter test` for every change; regenerate code first when annotations or worker definitions change.

## Commit & Pull Request Guidelines

History includes both Conventional Commit-style messages (`feat: ...`) and short imperative summaries (`Refactored`). Prefer a concise imperative subject, optionally using a type such as `feat:`, `fix:`, or `refactor:`. Keep commits focused. Pull requests should describe the user-visible or backend impact, list verification commands/results, link the related issue or plan when applicable, and include screenshots or a short recording for UI changes. Call out required `.env` or PocketBase setup explicitly.

## Security & Configuration

Never commit secrets, `.env` values, PocketBase data, or production credentials. Use local configuration for `PB_URL` and review PocketBase hooks/migrations carefully because they affect authentication and translation behavior.
