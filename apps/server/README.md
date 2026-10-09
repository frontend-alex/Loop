# Server Notes

## Observations

- Code is grouped by feature under `internal/`.
- `internal/user` contains the handler, service, repository, models, contracts, and routes.
- `internal/app/application.go` wires dependencies together.
- Current flow: `database -> repository -> service -> handler -> application`.
- Constructors keep setup explicit:

  ```go
  user.NewHandler(user.NewService(user.NewRepository(db, logger)))
  ```

## Research Points

### Naming

Use `New<Type>` for exported constructors and avoid repeating the package name:

```go
user.NewRepository(...)
user.NewService(...)
user.NewHandler(...)
```

Prefer `NewUserRepository` only when the type itself is named `UserRepository` and the longer name improves clarity. Keep constructors private as `new<Type>` when they are only used inside the package.

Research:

- [Effective Go: Names](https://go.dev/doc/effective_go#names)
- [Go Code Review Comments: Names](https://go.dev/wiki/CodeReviewComments#names)
- [Go Blog: Package Names](https://go.dev/blog/package-names)

### Dependency Injection

Dependencies are passed into constructors rather than created inside the type. This makes dependencies visible and allows tests to provide fakes or test databases.

Research:

- [Go Code Review Comments: Interfaces](https://go.dev/wiki/CodeReviewComments#interfaces)
- [Google Wire: Compile-time Dependency Injection](https://github.com/google/wire)

### Testing

Add tests for repository database operations, service behavior, handlers, and route registration.

Research:

- [Go Testing Package](https://pkg.go.dev/testing)
- [Go Wiki: TableDrivenTests](https://go.dev/wiki/TableDrivenTests)
- [Go Blog: Using Subtests and Sub-benchmarks](https://go.dev/blog/subtests)

## Current Verification

- `gofmt` passes for the renamed user constructors.
- `go test ./...` is blocked by an existing auth mismatch: `router.go` expects `*Handler`, while `handler.go` defines `*AuthHandler`.
