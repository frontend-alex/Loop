# Loop Project Rules

These rules apply to every request in this repository.

## Source Changes

- Do not create, edit, delete, or rename application source files.
- Do not modify tests, dependencies, generated files, platform files, or configuration files unless the user explicitly asks for that exact file change.
- When implementation is requested, explain the design and provide the proposed code or patch in the response only. Wait for explicit permission before applying it.
- Read the repository first and reference the exact files and symbols involved.

## Verification

- Validate framework and package API claims against current official documentation or the official API reference before recommending code that depends on them.
- Prefer Dart and Flutter documentation, package documentation on pub.dev, and primary platform documentation over blogs or generated summaries.
- Cite the URLs used and distinguish documented facts from project recommendations.
- Use read-only repository inspection and validation commands unless the user explicitly authorizes a change.

## Dart and Flutter Style

- Keep implementations as small as correctness allows.
- Try, in order: a clear one-liner, a small function, then a larger function only when the smaller form would reduce clarity, testability, or type safety.
- Do not write explicit `for`, `for-in`, `while`, or `do-while` loops. Prefer typed collection operations such as `map`, `where`, `fold`, `firstWhere`, or `forEach` when they are clearer and preserve the same behavior.
- Do not replace a loop with a long or opaque chained expression merely to satisfy this rule. If no-loop code is less readable or less safe, explain the exception before proposing it.
- Prefer `if`, `switch`, guard clauses, and named helpers over nested or large ternary expressions.
- Avoid `dynamic`, unchecked casts, untyped collection literals, and broad `Object?` state when a concrete type can be modeled.
- Use sound null safety, typed generic collections, explicit public API types, and immutable values where practical.
- Keep widgets focused on rendering and user interaction. Keep data and business logic in typed controllers, view models, repositories, services, or domain objects.
- Reuse feature-level components from onboarding instead of duplicating specialized behavior inside the onboarding page.

## React-to-Flutter Translation

- Explain Flutter concepts using React and TypeScript terms when useful.
- A `StatelessWidget` is similar to a pure React component that receives inputs and returns rendered JSX. In Flutter, that output is a widget tree rather than TSX.
- A `StatefulWidget` is a widget with a separate `State` object and lifecycle. Treat it as local UI state plus lifecycle, not automatically as a place for repositories, API calls, or business logic.
- A Flutter controller or view model is the closest equivalent to reusable hook logic such as `useAlarm`, especially when it exposes state and commands like `create`, `update`, `delete`, or `toggle`.
- A repository is closest to a typed data-access client or the API layer behind a React Query hook. A service is closest to an integration wrapper for platform APIs, such as notifications or native alarm scheduling.
- A Riverpod provider is closest to a dependency-injected context/store selector. Explain whether it owns shared state, creates a repository, or exposes an operation before comparing it to a React hook.
- A Flutter `ChangeNotifier` or notifier is closest to a store or query state object that emits updates. It is not itself the database or native API.
- For the alarm feature, describe the flow as: alarm editor widget -> alarm controller/view model -> alarm repository -> alarm scheduler service. Compare that to: form component -> custom hook/query mutation -> API client -> platform or server integration.
- Keep terminology precise: a custom React Hook shares stateful logic, while each hook call still owns independent state unless state is lifted or backed by a shared store/cache.

## Response Format

- Do not silently implement code. Give the user the design, file plan, code, or patch needed to implement it.
- When proposing or providing code, always include the folder architecture and file architecture first, followed by the code, then a short explanation in React and TypeScript terms at the bottom.
- State assumptions and unresolved product decisions briefly.
- For code proposals, include the smallest useful snippet first, then expand only if necessary.
- Do not use filler, invented APIs, or unsupported claims.

## Source-Code Response Formatting

- Put each Dart or Flutter filename in a Markdown heading outside the code block.
- Wrap Dart and Flutter source in a fenced Markdown block labelled `dart`.
- Never output Dart source as an unlabelled or plain-text block.
