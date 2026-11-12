# Authentication and account-owned onboarding — test plan and results

**Executed:** 12 November 2026. **Scope:** backend unit, middleware, PostgreSQL integration, and in-process HTTP tests. **Outcomes supported:** LO4 quality assurance and LO3 automated engineering evidence.

## Purpose and traceability

Validate that authentication preserves identity, account creation is atomic, returning sign-in preserves progress, and an authenticated onboarding request cannot accidentally update another account.

- FR-01 / [US-001, KAN-71 — account and sign-in](https://loopappios.atlassian.net/browse/KAN-71): backend account creation and returning sign-in only; provider/device acceptance remains pending.
- FR-02 / [US-005, KAN-75 — account-owned onboarding](https://loopappios.atlassian.net/browse/KAN-75): onboarding initialization, progress preservation, and account isolation.
- FR-15 / NFR-05: authentication and ownership boundaries; partial evidence, not a complete security assessment.
- NFR-03: atomic account creation and duplicate prevention; not every integrity/idempotency requirement is covered.
- [Canonical acceptance criteria and traceability](https://app.notion.com/p/4055cda456b1814bac95e966415cc302). These results do not mark entire stories or all numbered acceptance criteria complete.

## Risk-based approach and environment

- In-memory JWT/middleware tests check valid, missing, malformed, incorrectly signed, and expired credentials without external OAuth.
- Real PostgreSQL integration tests check foreign-key relationships, transaction rollback, and preserved data. PostgreSQL is used rather than SQLite to exercise the application's actual database technology.
- The isolation test uses the registered onboarding route, real JWT middleware, handler, service, repository, and database. User B starts with existing answers and step 2; the full persisted row is compared before and after A's request, including timestamps.
- Shared `testutil.AuthFixture` creates a new PostgreSQL container per integration test. No development/production connection or `DATABASE_TEST_URL` is used. Connections and containers are cleaned up automatically.
- Environment: macOS/arm64, Go 1.27.3, Docker Desktop, Testcontainers Go 0.45.0, `postgres:17-alpine`. Production migrations and production database version parity were not verified.

## Expected versus actual results

All rows below passed in the local `go test -race -v -count=1 ./...` execution on 12 November 2026. See [execution summary](results/authentication-2026-11-12.txt).

| ID | Scenario | Expected | Actual observed result |
| --- | --- | --- | --- |
| AUTH-01 | Generate and validate a JWT | Extracted identity matches the supplied user | User ID 67 recovered; passed |
| AUTH-02 | Missing bearer token | HTTP 401; protected handler not called | 401; handler not called; passed |
| AUTH-03 | Malformed token | HTTP 401; protected handler not called | 401; handler not called; passed |
| AUTH-04 | Token signed with a different key | HTTP 401; protected handler not called | 401; handler not called; passed |
| AUTH-05 | Expired token | HTTP 401; protected handler not called | 401; handler not called; passed |
| AUTH-06 | Valid bearer token | Protected handler runs with the correct user ID | 204 from the test handler with user ID 67; passed |
| AUTH-07 | First account sign-in | User, provider identity, and incomplete onboarding saved; token matches user | All relationships and token identity assertions passed |
| AUTH-08 | Database rejects onboarding creation | Authentication errors; no token; all three tables remain empty | Named constraint error observed; empty token and zero rows verified; passed |
| AUTH-09 | Same provider identity signs in again | Same account; one row per table; existing onboarding progress unchanged | Both JWT identities match; counts remain 1; saved answers and step 2 preserved; passed |
| AUTH-10 | A completes onboarding through HTTP | A completes with submitted answers; B's existing onboarding is unchanged | 204; A's completion, step 3, and answer verified; B's entire persisted row unchanged; passed |

AUTH-02 through AUTH-06 exercise middleware around a test handler, not a running deployed endpoint. AUTH-10 exercises an in-process HTTP router, not a live network deployment.

## Commands and static checks

Run from `apps/server` with Docker available:

```bash
go vet ./...
go mod verify
go test -race -v -count=1 ./...
```

Results: all three commands exited successfully; no race reports were emitted. Formatting checks on the QA test/helper files returned no filenames. This is not a performance benchmark or proof of exhaustive coverage. Test files currently have no integration build tag, so ordinary `go test ./...` also requires Docker.

## Failure, correction, and retest

The returning-user test initially failed on `require.NotZero(t, identity.ID)`. This inspected the original input value, although `Authenticate` receives an identity by value and persists a copy. The invalid assertion was removed; persisted-record, token-identity, duplicate-count, and progress assertions were retained. The creation test was also corrected to assert the saved identity's `UserID` equals the saved account's ID rather than passing `UserID` as an assertion message.

Retest: all three authentication integration tests passed, followed by the full backend suite with the race detector. This was a **test-code correction**, not a discovered application authentication defect. The rollback test's database constraint error is intentional and is not itself a failed test.

## Revision, PR, review, and CI

- Branch: `feature/auth-testing`.
- Base revision: [cf6ec7d](https://github.com/frontend-alex/Loop/commit/cf6ec7df79f2b8b0ba94c3b4cc3ed353feb86da2). This base alone does **not** contain the tests.
- Test commit: pending publication; replace with the exact published revision.
- PR: pending creation against `develop`.
- Human review: pending; AI-assisted changes and local test execution are not human approval.
- CI run: pending the PR-triggered Server CI run. No unrelated successful run is used as evidence.
- Existing workflow: `.github/workflows/server.yml`; PRs to `develop`/`main` run server validation, with Snyk and Sonar jobs separately configured. The server validation failure stops later commands in that step; no deployment stage or required branch protection has been demonstrated here.
- Publication scope: test files, shared test helpers, Testcontainers dependency changes, and this QA report. Unrelated Makefile edits and local file deletions are excluded.

## Manual Google sign-in — pending user execution

The student will perform this check. No Google/Apple sign-in, iOS build, simulator/device behavior, or deployment was verified in this execution.

| Check | Expected | Actual / status |
| --- | --- | --- |
| First Google sign-in | Returns to Loop; correct account and initial onboarding load | Pending user report |
| Sign-in cancellation and retry | No authenticated session after cancellation; retry can succeed | Pending user report |
| Complete onboarding and restart | Same account and persisted onboarding state load after restart | Pending user report |
| Sign in again with the same Google identity | Same account and previous onboarding state; no duplicates | Pending user report |

For each manual result, record date/time, tested commit/build, device and iOS version, server environment, expected/actual behavior, and a redacted screenshot or observation. Use account aliases; never include passwords, JWTs, OAuth codes, or personal account details. Do not mark these passed until the user supplies observations.

## Remaining limitations and completion actions

- Commit and PR must be linked to the actual CI result; human review is still required.
- Real Google/Apple sign-in, iOS flows, logout/revocation, network failures, invalid JSON, all protected routes, token theft, and malicious ownership inputs are outside this executed subset.
- The isolation test demonstrates A's legitimate request leaves B unchanged; it is not an exhaustive penetration test or a complete IDOR assessment.
- Schema setup uses GORM `AutoMigrate`, not a verified production migration chain.
- A database container used by tests is **not** evidence that the backend application was deployed through Docker. Live deployment and successful requests remain separate evidence.
- This report supports selected backend behavior, not five completed full-stack stories or completion of every LO3/LO4 requirement.
