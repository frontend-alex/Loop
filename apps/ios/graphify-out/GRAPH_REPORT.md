# Graph Report - .  (2026-09-15)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 282 nodes · 443 edges · 13 communities
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ce811256`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- SwiftUI
- Action
- Equatable
- AlarmWeekday
- OnboardingProvider
- View
- OnboardingView
- Action
- Step
- AlarmView
- AppBlockingPermission
- _AppBlockingService
- opencode.json

## God Nodes (most connected - your core abstractions)
1. `Action` - 35 edges
2. `AlarmWeekday` - 18 edges
3. `Alarm` - 15 edges
4. `OnboardingView` - 15 edges
5. `AppBlockingPermission` - 14 edges
6. `OnboardingProvider` - 14 edges
7. `Action` - 14 edges
8. `AlarmSound` - 13 edges
9. `ComposableArchitecture` - 13 edges
10. `AlarmView` - 12 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `AuthView`  [INFERRED]
  loop/App/AppView.swift → loop/Features/Auth/Views/Auth.swift
- `.body` --calls--> `AppBlockingPermission`  [INFERRED]
  loop/Features/AppBlocking/Views/AppBlocking.swift → loop/Features/AppBlocking/Views/AppBlockingPermission.swift
- `.body` --calls--> `AppSelection`  [INFERRED]
  loop/Features/AppBlocking/Views/AppBlocking.swift → loop/Features/Onboarding/Models/Onboarding.swift
- `.body` --calls--> `AlarmPermission`  [INFERRED]
  loop/Features/Onboarding/Views/Steps/AlarmEditor.swift → loop/Features/Alarm/Views/AlarmPermission.swift
- `.alarmContent` --calls--> `AlarmRepeatView`  [INFERRED]
  loop/Features/Onboarding/Views/Steps/AlarmEditor.swift → loop/Features/Alarm/Views/Repeat.swift

## Import Cycles
- None detected.

## Communities (13 total, 0 thin omitted)

### Community 0 - "SwiftUI"
Cohesion: 0.06
Nodes (37): App, ComposableArchitecture, FamilyControls, AppView, StoreOf, loopApp, .body, Action (+29 more)

### Community 1 - "Action"
Cohesion: 0.06
Nodes (32): Action, alarmAuthorizationChecked, alarmAuthorizationFailed, alarmAuthorizationRequested, alarmAuthorizationSucceeded, alarmPermissionSkipped, alarmSelected, alarmSetFailed (+24 more)

### Community 2 - "Equatable"
Cohesion: 0.13
Nodes (29): Codable, Data, Equatable, Identifiable, AppSelection, OnboardingDraft, OnboardingLayout, Question (+21 more)

### Community 3 - "AlarmWeekday"
Cohesion: 0.09
Nodes (27): CaseIterable, Foundation, Hashable, Alarm, .repeatSummary, AlarmSound, birds, `default` (+19 more)

### Community 4 - "OnboardingProvider"
Cohesion: 0.10
Nodes (20): FamilyActivitySelection, AppBlockingView, .body, StoreOf, String, AlarmAuthorizationStatus, authorized, denied (+12 more)

### Community 5 - "View"
Cohesion: 0.19
Nodes (13): AlarmAnimationValues, AlarmMockScreen, .body, AlarmPermission, .body, Bool, CGFloat, Color (+5 more)

### Community 6 - "OnboardingView"
Cohesion: 0.11
Nodes (17): .body, HomeView, .body, OnboardingView, .adaptiveColor, .bottomBar, .bottomButtonTitle, .canContinue (+9 more)

### Community 7 - "Action"
Cohesion: 0.11
Nodes (19): Action, delegate, emailChanged, loginTapped, otpChanged, otpSubmitted, passwordChanged, registerTapped (+11 more)

### Community 8 - "Step"
Cohesion: 0.15
Nodes (13): ActivityKit, AlarmMetadata, AlarmKitMetadata, AlarmScheduler, Date, UUID, .body, Step (+5 more)

### Community 9 - "AlarmView"
Cohesion: 0.13
Nodes (12): AlarmKit, AlarmRepeatView, .body, Set, AlarmView, .alarmContent, .body, .permissionDescription (+4 more)

### Community 10 - "AppBlockingPermission"
Cohesion: 0.24
Nodes (9): AppBlockingPermission, .body, MockApp, Bool, CGFloat, Color, Set, String (+1 more)

### Community 11 - "_AppBlockingService"
Cohesion: 0.18
Nodes (5): AppBlockingPort, Bool, Bool, _AppBlockingService, AppBlockingService

### Community 12 - "opencode.json"
Cohesion: 0.50
Nodes (3): instructions, $schema, AGENTS.md

## Knowledge Gaps
- **98 isolated node(s):** `auth`, `onboarding`, `splashFinished`, `auth`, `home` (+93 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `OnboardingProvider` connect `OnboardingProvider` to `SwiftUI`, `Action`, `Equatable`, `OnboardingView`, `Step`, `AlarmView`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._
- **Why does `Action` connect `Action` to `Equatable`, `AlarmWeekday`, `OnboardingProvider`?**
  _High betweenness centrality (0.224) - this node is a cross-community bridge._
- **Why does `Alarm` connect `AlarmWeekday` to `Action`, `Equatable`, `AlarmView`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **What connects `auth`, `onboarding`, `splashFinished` to the rest of the system?**
  _98 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SwiftUI` be split into smaller, more focused modules?**
  _Cohesion score 0.05697278911564626 - nodes in this community are weakly interconnected._
- **Should `Action` be split into smaller, more focused modules?**
  _Cohesion score 0.0625 - nodes in this community are weakly interconnected._
- **Should `Equatable` be split into smaller, more focused modules?**
  _Cohesion score 0.12873563218390804 - nodes in this community are weakly interconnected._