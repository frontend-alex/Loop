# Loop

An iOS morning-routine application being developed with a native SwiftUI client and a Go backend. The product direction combines alarms, onboarding, and controls intended to reduce distracting app use.

## Current status

Active prototype. The repository implements several native screens and platform services plus an initial backend; it does not yet demonstrate a complete alarm-to-task-to-unlock workflow.

## Features and implementation

- SwiftUI onboarding, authentication screens, permission screens, and reusable design-system components.
- Alarm scheduling and cancellation through AlarmKit.
- FamilyControls authorization and storage of an app selection; authorization is distinct from applying a ManagedSettings shield.
- Go HTTP server with Chi routing, structured logging, request middleware, timeouts, and graceful shutdown.
- PostgreSQL connection management through GORM, liveness/readiness endpoints, and OAuth provider callbacks.

## Technology

Swift/SwiftUI, AlarmKit, FamilyControls, Go, Chi, Goth, GORM, PostgreSQL, Docker, and GitHub Actions. The checked-in Go module declares Go 1.27.1. The Xcode project contains an iOS 26.5 deployment target; use an Xcode installation that can build those settings.

## Repository map

| Path | Purpose |
| --- | --- |
| [apps/ios/loop.xcodeproj](apps/ios/loop.xcodeproj) | Native iOS project |
| [apps/ios/loop/Features](apps/ios/loop/Features) | Feature views, models, providers, and services |
| [apps/ios/loop/Components](apps/ios/loop/Components) | Shared UI and design-system primitives |
| [apps/server/cmd/api/main.go](apps/server/cmd/api/main.go) | Backend composition and entry point |
| [apps/server/internal](apps/server/internal) | Configuration, HTTP helpers, features, and infrastructure |
| [.github/workflows/backend.yml](.github/workflows/backend.yml) | Backend build and test-command workflow |

## Local setup

Clone the repository, then open the iOS project on macOS:

```bash
git clone https://github.com/frontend-alex/Loop.git
cd Loop
open apps/ios/loop.xcodeproj
```

Select the app scheme and an appropriate simulator or device. Configure signing for your own team. Platform permission and entitlement behavior must be checked on the target device.

For the backend, start a local PostgreSQL instance and supply configuration through the process environment. The Go entry point does not load a .env file itself:

```bash
docker run --name loop-local-postgres -e POSTGRES_PASSWORD=local-only-password -p 5432:5432 -d postgres:17
cd apps/server
go mod download
export DATABASE_URL='host=127.0.0.1 user=postgres password=local-only-password dbname=postgres port=5432 sslmode=disable'
export AUTH_KEY='replace-with-a-local-session-signing-secret'
go run ./cmd/api
```

The server defaults to :8080. Set HTTP_ADDR to override it. Google/Apple credentials are read by [config.Load](apps/server/internal/config/config.go); provider callback URLs must include the mounted /api/v1/auth prefix. The current default callback strings omit that prefix, so override them when configuring OAuth.

## Verification

```bash
cd apps/server
go test ./...
go build ./cmd/api
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
```

The workflow runs the Go test command and builds the API. No *_test.go files were present in the inspected tree; a successful test command would not establish behavioral coverage. Runtime and device checks were not executed during this documentation update.

## Limitations and next steps

- The root compose.yaml is empty; use the explicit local database instructions or review the server Makefile.
- The current OAuth callback returns provider user information; this alone is not an application access/refresh-token flow.
- Provider registration is currently gated by the Google credential condition, including Apple registration.
- App-blocking authorization/selection and alarm scheduling are implemented pieces, not evidence of a finished morning-lock product.
- Add focused backend tests and device-based acceptance checks before describing the app as production ready.

## Code review starting points

- [apps/server/internal/app/router.go](apps/server/internal/app/router.go)
- [apps/server/internal/platform/auth/providers.go](apps/server/internal/platform/auth/providers.go)
- [apps/ios/loop/Features/Alarm/Services/Scheduler.swift](apps/ios/loop/Features/Alarm/Services/Scheduler.swift)
- [apps/ios/loop/Features/AppBlocking/Services/AppBlockingService.swift](apps/ios/loop/Features/AppBlocking/Services/AppBlockingService.swift)
