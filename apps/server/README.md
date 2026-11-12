# Server Notes

## Docker development image

Build from this directory with `docker build -t go-server .`, or use `make image`.
The image runs Air as the non-root `loop` user (UID/GID 10001) and copies only
the Go module files, source, API specification, and Air configuration. Local
environment files, private keys, and build artifacts are excluded from the build
context. Supply runtime configuration with `--env-file .env`; do not bake it into
the image.

The Makefile bind-mounts this directory at `/app` for hot reload. On Linux, the
mounted directory (including `tmp/`) must be writable by UID/GID 10001. If needed,
pass `--user "$(id -u):$(id -g)" --env HOME=/tmp --env GOCACHE=/tmp/go-build` to
`docker run` or `docker create` to use the host user's permissions instead. The
bind mount is not filtered by `.dockerignore` and exposes local files to the
container, so keep it limited to trusted local development.

This is a development image, not a minimal production runtime. Keep the Go image
version aligned with `go.mod` and update the pinned Air commit deliberately.
The Dockerfile comment records the corresponding Air release.

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
