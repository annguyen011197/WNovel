# State Ownership: `setState` vs Riverpod

This rule defines **where** each piece of state lives in the WNovel Flutter + Riverpod
codebase. Every contributor (human or AI agent) must classify state before writing it.

---

## Decision Flowchart

```
Is this state…
├─ Read by another widget?                       → Riverpod provider
├─ Domain/business data (Chapter, Project, …)?    → Riverpod provider
├─ Driving an async operation (API, DB)?          → Riverpod provider
├─ Must survive widget disposal within a session? → Riverpod provider
└─ None of the above?                             → Local setState
```

**Simple litmus test:** _"If I killed and rebuilt this widget right now, would this
piece of state need to still exist correctly elsewhere in the app?"_
If yes → provider. If no and no other widget cares → local `setState`.

---

## 1 · Local `setState` (Ephemeral UI State)

Use plain `setState` / local `State` fields **only** for state that:

- Is **not read** by any other widget.
- Does **not** represent business/domain data.
- Is **fine to lose** when the widget is disposed or rebuilt from scratch.

### Examples (keep as local state)

| State | Why local |
|-------|-----------|
| Split-pane `_splitRatio` | Only this widget's layout cares; losing it on rebuild is fine. |
| Scroll offset | Framework-managed via `ScrollController`. |
| Tooltip/expansion toggle | Purely visual; no other widget depends on it. |
| Animation controller | Owned by this widget's lifecycle. |
| Text field focus | Transient interaction state. |
| Cached derived data (e.g. parsed paragraph lists) | Performance cache derived from provider-owned data; recomputable. |

### Rules

- Keep the `setState` call as close to the gesture handler as possible.
- Never put domain data (chapter text, status, project fields) in local state.
- If a "local" value starts being needed by a sibling/parent widget, promote it to a provider.

---

## 2 · Riverpod Provider (Domain / Shared State)

Use a Riverpod provider/notifier for **any** state that:

- Represents **domain/business data** (Chapter, Project, translation status, user session).
- Needs to be **read or reacted to** by more than one widget.
- Must **survive** widget rebuilds/disposal within the same session.
- **Drives async operations** (API calls) and their success/error/loading states.

### Immutability Rules

1. **Never mutate a model field directly** and then separately call a provider update.  
   This creates two competing sources of truth and breaks Riverpod change detection.

   ```dart
   // ❌ BAD — direct mutation
   chapter.status = ChapterStatus.translating;
   ref.read(libraryProvider.notifier).updateProject(project);

   // ✅ GOOD — immutable update via copyWith
   project.chapters[index] = chapter.copyWith(
     status: ChapterStatus.translating,
   );
   ref.read(libraryProvider.notifier).updateProject(project);
   ```

2. **Always produce new instances via `copyWith`** and update state exclusively through
   the notifier's public methods.

3. **Widgets must only `ref.watch` / `ref.read`** the resulting state — never
   read-then-mutate the same object the provider owns.

4. **Represent async status explicitly** inside the provider state
   (e.g. `AsyncValue`, or an explicit enum: `idle` / `loading` / `success` / `error`),
   not via ad-hoc fields mutated by the widget.

### Where Business Logic Lives

| Concern | Location | Never in |
|---------|----------|----------|
| API calls | Notifier method | Widget `onSelected` / `onPressed` |
| Status transitions (pending → translating → done) | Notifier method | Widget `setState` |
| Error handling for async ops | Notifier sets `errorMessage` / `AsyncValue.error` | Widget `try/catch` around API call |
| Showing a SnackBar from error state | Widget `ref.listen` with `mounted` guard | — |

### Pattern: Widget → Notifier Delegation

```dart
// In the widget (only dispatches, never mutates):
onPressed: () {
  final project = ref.read(activeProjectProvider);
  if (project == null) return;
  ref.read(translationProvider.notifier).translateChapterOnly(project, chapter);
},

// In the notifier (owns all mutation + async logic):
Future<void> translateChapterOnly(Project project, Chapter chapter) async {
  final index = project.chapters.indexWhere((c) => c.id == chapter.id);
  if (index == -1) return;

  project.chapters[index] = chapter.copyWith(status: ChapterStatus.translating);
  _updateProject(project);

  try {
    final result = await _ref.read(apiServiceProvider).translateOnly(chapter.originalText);
    project.chapters[index] = project.chapters[index].copyWith(
      translatedText: result['translatedText'] ?? '',
      status: ChapterStatus.done,
    );
    _updateProject(project);
  } catch (e) {
    project.chapters[index] = project.chapters[index].copyWith(
      status: ChapterStatus.pending,
    );
    _updateProject(project);
    state = state.copyWith(errorMessage: 'Translation failed: $e');
  }
}
```

---

## 3 · `BuildContext` After `await`

Any widget code that uses `context` or calls `setState` after an `await` **must** check
`mounted` first:

```dart
final result = await someAsyncCall();
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

If the async logic moves into a notifier (preferred), the widget reacts to state changes
via `ref.listen` — still guarded by `mounted`:

```dart
ref.listen<TranslationState>(translationProvider, (prev, next) {
  if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.errorMessage!)),
    );
  }
});
```

---

## 4 · Quick-Reference Classification for This Codebase

| State | Owner | Type |
|-------|-------|------|
| `_splitRatio` (divider position) | Widget local `setState` | Ephemeral UI |
| `_sourceParagraphs` / `_targetParagraphs` (cached parse) | Widget local field | Derived cache |
| `Chapter.status`, `.translatedText`, `.summary` | `translationProvider` notifier via `copyWith` | Domain |
| `Project.chapters`, `.characters`, `.relations` | `libraryProvider` notifier | Domain |
| `TranslationState.isTranslating`, `.errorMessage` | `translationProvider` state | Async status |
| Active project selection | `activeProjectIdProvider` | Navigation/domain |
| Scroll position in reader | `ScrollController` (local) | Ephemeral UI |
| Dialog open/close | Local `showDialog` / `Navigator` | Ephemeral UI |

---

## 5 · Enforcement Checklist (For Code Review / AI Agents)

Before merging any widget change, verify:

- [ ] No `chapter.someField = value` or `project.someField = value` appears in any widget file (`lib/ui/`).
- [ ] All domain state mutations go through a notifier method using `copyWith`.
- [ ] All API calls live in a notifier, not in a widget callback.
- [ ] Any `context` usage after `await` is guarded by `if (!mounted) return;`.
- [ ] `ref.listen` (not inline `try/catch`) is used to show SnackBars from async errors.
- [ ] New state fields are classified as local vs. provider-owned in the PR description.
