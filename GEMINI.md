# AI Coding Agent Guidelines: Flutter + Riverpod

This file provides project architecture guidelines, conventions, state management rules, and development best practices for building scalable, maintainable Flutter applications using **Riverpod** (with code generation).

It is written to be used by **any AI coding agent** (Claude Code, Cursor, Copilot Workspace, Gemini CLI, etc.) — drop it in the project root as `AGENT.md` / `CLAUDE.md` / `.cursorrules` / `GEMINI.md` as needed, or symlink one to the others so every agent reads the same source of truth.

---

## 1. Project Overview & Tech Stack

- **Framework:** Flutter (latest stable, Dart 3.x)
- **State Management & DI:** `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- **Data Modeling & Immutability:** `freezed`, `freezed_annotation`, `json_serializable`
- **Routing:** `go_router` (synchronized with Riverpod for reactive auth/route guards)
- **Networking:** `dio` / `retrofit` or standard HTTP client with interceptors
- **Local Storage:** `shared_preferences`, `flutter_secure_storage`, or `drift` / `hive_ce`

---

## 2. Architecture: Feature-First Clean Architecture

The codebase follows a **Feature-First** structure with clear layer separation:

```text
lib/
├── src/
│   ├── app.dart                    # Root MaterialApp.router & global configs
│   ├── core/                       # App-wide utilities, constants, themes, network clients
│   │   ├── constants/
│   │   ├── errors/                 # Failure / Exception classes
│   │   ├── network/                # Dio client, interceptors, API endpoints
│   │   ├── theme/                  # Color schemes, typography, ThemeData
│   │   └── utils/                  # Helpers, formatters, extensions
│   ├── routing/                    # GoRouter configuration & routes
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   └── features/                   # Encapsulated feature modules
│       └── [feature_name]/
│           ├── data/               # Repositories implementation, Data Sources, DTOs
│           │   ├── datasources/
│           │   └── repositories/
│           ├── domain/             # Entities, Value Objects, Domain Interfaces (contracts)
│           │   ├── models/
│           │   └── repositories/
│           └── presentation/       # UI (Screens, Widgets) and Riverpod Controllers / Notifiers
│               ├── controllers/
│               └── screens/
└── main.dart                       # Entry point with ProviderScope
```

**Agent rule:** before creating a new file, check whether an existing feature folder already owns the concern. New code goes into the matching layer of an existing feature unless the feature itself is new — never bypass the layering to "save a file."

---

## 3. Riverpod Conventions & Best Practices

### 3.1. Always Use Riverpod Code Generation (`@riverpod`)

- Use `@riverpod` annotations instead of legacy manual providers (`StateNotifierProvider`, `ChangeNotifierProvider`).
- Default to **auto-dispose** (the default for `@riverpod`). Use `@Riverpod(keepAlive: true)` only for long-lived singletons (e.g., authentication state, network client, global configuration).

```dart
// Functional Provider (Synchronous / Read-Only / Computation)
@riverpod
String appVersion(Ref ref) {
  return '1.0.0';
}

// FutureProvider / Async Computation
@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.fetchCurrentUser();
}

// Notifier (Async State with Mutations)
@riverpod
class TodoListController extends _$TodoListController {
  @override
  FutureOr<List<Todo>> build() async {
    // Initial fetch / setup
    return _fetchTodos();
  }

  Future<void> addTodo(String title) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(todoRepositoryProvider);
      await repository.addTodo(title);
      return _fetchTodos();
    });
  }

  Future<List<Todo>> _fetchTodos() => ref.read(todoRepositoryProvider).getTodos();
}
```

### 3.2. Widget Consumption Rules

1. **Use `ConsumerWidget` or `ConsumerStatefulWidget`:**
   - Prefer `ConsumerWidget` over wrapping small sections with `Consumer` unless micro-optimizing rebuilds.
2. **`ref.watch` in `build()`:**
   - Always use `ref.watch` inside widget `build()` to rebuild on state changes.
   - Use `select` to filter rebuilds when only a specific field is needed:
     ```dart
     final username = ref.watch(userControllerProvider.select((user) => user.name));
     ```
3. **`ref.read` in Event Handlers / Callbacks:**
   - Use `ref.read` inside `onPressed`, `onTap`, and asynchronous side-effects. **Never use `ref.read` directly inside the widget `build()` method.**
4. **`ref.listen` for Side Effects:**
   - Use `ref.listen` inside `build()` to trigger snackbars, alerts, dialogs, or navigation on state transitions:
     ```dart
     ref.listen<AsyncValue<void>>(
       todoListControllerProvider,
       (previous, next) {
         next.whenOrNull(
           error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(error.toString())),
           ),
         );
       },
     );
     ```

### 3.3. Handling `AsyncValue` Gracefully

- Use `.when()`, `.maybeWhen()`, or Dart pattern matching on `AsyncValue` to handle loading, error, and data states deterministically.

```dart
final todoState = ref.watch(todoListControllerProvider);

return todoState.when(
  data: (todos) => ListView.builder(
    itemCount: todos.length,
    itemBuilder: (context, index) => TodoItemTile(todo: todos[index]),
  ),
  loading: () => const Center(child: CircularProgressIndicator.adaptive()),
  error: (err, stack) => Center(child: Text('Error: $err')),
);
```

---

## 4. State & Model Immutability with Freezed

All models, states, and union types must be immutable:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    DateTime? dueDate,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}
```

---

## 5. Routing with GoRouter & Riverpod Integration

Integrate `GoRouter` with Riverpod by providing the router via a provider and synchronizing it with authentication/app state:

```dart
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
```

---

## 6. Testing Strategy

### 6.1. Unit Testing Providers

Use `ProviderContainer` to test Riverpod notifiers and providers in isolation:

```dart
test('TodoListController adds item successfully', () async {
  final container = ProviderContainer(
    overrides: [
      todoRepositoryProvider.overrideWithValue(MockTodoRepository()),
    ],
  );
  addTearDown(container.dispose);

  final listener = container.listen(todoListControllerProvider, (_, __) {});

  await container.read(todoListControllerProvider.notifier).addTodo('New Task');

  expect(
    container.read(todoListControllerProvider).value,
    contains(predicate((Todo t) => t.title == 'New Task')),
  );
});
```

### 6.2. Widget Testing with Overrides

Wrap widget tests in `ProviderScope`:

```dart
testWidgets('HomeScreen renders todo items', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoListControllerProvider.overrideWith(() => FakeTodoListController()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('Sample Todo'), findsOneWidget);
});
```

### 6.3. Agent Self-Verification Loop

Any AI coding agent that generates or edits code in this project must, before considering a task done:

1. Run `dart run build_runner build --delete-conflicting-outputs` if any `@riverpod`, `@freezed`, or `@JsonSerializable` annotation was added or changed.
2. Run `flutter analyze` and resolve all errors (warnings should be resolved unless pre-existing and unrelated to the change).
3. Run `flutter test` for the affected feature (or the full suite for cross-cutting changes) and report results — never claim a task is complete without having actually run it.
4. If a command isn't available in the current environment (e.g., no simulator/emulator for widget golden tests), say so explicitly rather than silently skipping it.

---

## 7. Essential Development Commands

```bash
# Get dependencies
flutter pub get

# Run code generator (Riverpod & Freezed)
dart run build_runner build --delete-conflicting-outputs

# Watch code generator during development
dart run build_runner watch --delete-conflicting-outputs

# Analyze & Lint code
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

---

## 8. Rules for the AI Coding Agent

When generating or refactoring Flutter code in this workspace, any agent must:

1. **Always prioritize `@riverpod` annotations** over manual provider syntax (`StateNotifierProvider`, `ChangeNotifierProvider`, plain `Provider` for mutable state).
2. **Never create a `StatefulWidget` solely for managing state** if a Riverpod provider is more appropriate. `StatefulWidget` is acceptable only for purely local, ephemeral UI state (e.g., an `AnimationController`, a `TextEditingController`, scroll position) that has no business logic and nothing else needs to read.
3. **Always separate Presentation, Domain, and Data layers.** Business logic belongs in Notifiers/Controllers and Repositories, never directly inside UI Widgets.
4. **Use `AsyncValue.guard()`** for asynchronous mutations to safely catch errors — never a bare `try/catch` that silently swallows the error.
5. **Enforce strict null-safety and immutability** with `freezed` and `const` constructors where applicable.
6. **Include required `part` directives** (`part '[file].g.dart';` and `part '[file].freezed.dart';`) when generating code-generated models or providers, and run the build runner (§6.3) afterward — generated code must exist and compile before the task is considered done.
7. **Never fabricate a package API.** If unsure whether a Riverpod/Freezed/GoRouter API exists or matches the pinned version in `pubspec.yaml`, check `pubspec.yaml`/`pubspec.lock` or the package source under `.dart_tool/` rather than guessing from memory — package APIs change across major versions (notably Riverpod 2.x → 3.x generator syntax).
8. **Respect existing patterns over introducing new ones.** If the codebase already has an established convention for something not covered here (e.g., a specific error-handling wrapper, a custom lint rule, a naming scheme), follow it instead of introducing a competing pattern, and flag the gap in this file for a human to reconcile.
9. **Keep diffs minimal and reviewable.** Don't reformat or refactor unrelated code while completing a task; call out opportunistic improvements separately instead of bundling them into an unrelated change.
10. **State assumptions explicitly.** When a request is ambiguous (e.g., which feature folder a new screen belongs to), state the assumption made and proceed, rather than blocking on it or guessing silently.
