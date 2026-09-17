# Loop Project Rules

These rules apply to every request in this repository.

## Source Changes

- Do not create, edit, delete, or rename application source files.
- Do not modify tests, dependencies, generated files, platform files, or configuration files unless the user explicitly asks for that exact file change.
- When implementation is requested, explain the design and provide the proposed code or patch in the response only. Wait for explicit permission before applying it.
- Treat `/write` as explicit permission to implement the current request. When `/write` is present, source edits are allowed and the implementation must be verified. Without `/write`, remain proposal-only.
- Read the repository first and reference the exact files and symbols involved.

## Verification

- Validate framework and package API claims against current official documentation or the official API reference before recommending code that depends on them.
- Prefer Dart and Flutter documentation, package documentation on pub.dev, and primary platform documentation over blogs or generated summaries.
- Cite the URLs used and distinguish documented facts from project recommendations.
- Use read-only repository inspection and validation commands unless the user explicitly authorizes a change.

## SwiftUI Design System

- Keep the design system limited to reusable primitives and component behavior. Do not put screen-specific layout decisions such as `screenHorizontalPadding`, `contentPadding`, or `bottomBarPadding` in global design-system files.
- Use `DesignSystem.Spacing` for the shared spacing scale. Use the 4pt/8pt grid: `xs = 4`, `sm = 8`, `md = 16`, `lg = 24`, and `xl = 32`.
- Use `16pt` as the default horizontal content inset on iPhone unless the feature has a documented reason to use another value.
- Use `safeAreaPadding` when content must respect system areas such as the notch or home indicator. Use `padding` when only the content needs an inset while the background remains edge-to-edge.
- Keep feature-specific layout values next to the feature that owns the layout. Name them by intent, such as `artworkBottomInset`, `sectionSpacing`, or `actionSpacing`.
- Use `8pt` for tightly related elements, `16pt` for normal element spacing, `24pt` between sections, and `32pt` for major visual separation.
- Keep interactive controls at least `44pt` by `44pt`, including icon-only buttons.
- Prefer SwiftUI layout containers and spacing over arbitrary offsets. Do not use `offset` to create normal layout spacing.
- Do not introduce generic names whose meaning depends on a particular screen hierarchy, such as `contentHorizontal`, `screenHorizontal`, or `bottomBarVertical`, into global tokens.

Good:

```swift
enum DesignSystem {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}

private enum OnboardingLayout {
    static let sectionSpacing = DesignSystem.Spacing.md
    static let horizontalInset = DesignSystem.Spacing.md
}

VStack(spacing: OnboardingLayout.sectionSpacing) {
    content
}
.safeAreaPadding(.horizontal, OnboardingLayout.horizontalInset)
```

Bad:

```swift
enum AppInsets {
    static let screenHorizontal: CGFloat = 16
    static let contentHorizontal: CGFloat = 8
    static let bottomBarVertical: CGFloat = 8
}
```

- Treat the [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) and SwiftUI layout APIs such as [`safeAreaPadding`](https://developer.apple.com/documentation/swiftui/view/safeareapadding(_:)) as the platform guidance. The spacing scale and feature-level naming rules above are Loop project conventions.

## Flutter Skills

- Repository-local Flutter and Dart skills are located under `.opencode/skills/flutter/*`.
- Always load and follow the relevant skill from `.opencode/skills/flutter/` before working on Flutter, Dart, Riverpod, or Flutter platform-integration tasks.
- If no dedicated Flutter or Dart skill is available in the environment, apply the Flutter and Dart rules in this file and verify framework or package behavior against official documentation.
- For Flutter platform integrations, use both the relevant Flutter skill and the primary Android or Apple platform documentation.

## Relevant Apple Skills

- Repository-local Apple skills are located under `.opencode/skills/swift/*`.
- Always load and follow the relevant skill from `.opencode/skills/swift/` before working on Swift, AlarmKit, iOS lifecycle, signing, or physical-device integration tasks.
- Use [Swift Concurrency Pro](https://github.com/twostraws/Swift-Concurrency-Agent-Skill) for `async`/`await`, `Task`, actors, and AlarmKit calls.
- Use [Background Execution Skill](https://github.com/n0an/Background-Execution-Agent-Skill) for AlarmKit behavior while the app is backgrounded, suspended, or terminated.
- Use [iOS Simulator Skill](https://github.com/conorluddy/ios-simulator-skill) for simulator and physical-device installation, logs, permissions, and runtime verification.
- Use [Swift Architecture Skill](https://github.com/efremidze/swift-architecture-skill) when changing the Flutter method-channel/native adapter boundary.
- Use [Swift API Design Guidelines Agent Skill](https://github.com/Erikote04/Swift-API-Design-Guidelines-Agent-Skill) when adding or reviewing public Swift bridge APIs.
- Use [iOS Code Audit](https://github.com/jazzychad/ios-code-audit) when reviewing native alarm, signing, permissions, or lifecycle changes.
- Always validate Apple platform behavior against the relevant primary Apple documentation; third-party skills supplement but do not replace official documentation.

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
- When using ports-and-adapters architecture, name interfaces as ports and implementations as adapters. Do not make a platform adapter implement an unrelated repository port.
- Use the smallest architecture that keeps UI state, domain behavior, and real external boundaries clear. Do not add controllers, services, ports, folders, or layers speculatively or merely to satisfy a pattern.
- Preserve genuinely reusable boundaries, but introduce abstractions only when there is a concrete external dependency, repeated behavior, or a real change expected in the app.

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

- Put each Dart, Flutter, Swift, or Kotlin filename in a Markdown heading outside the code block.
- Wrap Dart and Flutter source in a fenced Markdown block labelled `dart`.
- Wrap Swift source in a fenced Markdown block labelled `swift`.
- Wrap Kotlin source in a fenced Markdown block labelled `kotlin`.
- Never output these languages as unlabelled or plain-text blocks.
