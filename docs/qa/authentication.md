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

All rows below passed in the local `go test -race -v -count=1 ./...` execution on 12 November 2026, including a clean archive of published revision [56438fa](https://github.com/frontend-alex/Loop/commit/56438fa9106a5e95c58df8a0724702c1113c21c6). See [execution summary](results/authentication-2026-11-12.txt).

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
| AUTH-11 | Call the onboarding handler without authenticated context | HTTP 401 before service/database access | Existing direct-handler test passed in the clean committed-tree suite |

AUTH-02 through AUTH-06 exercise middleware around a test handler, not a running deployed endpoint. AUTH-10 exercises an in-process HTTP router, not a live network deployment.

### Test implementation

- [JWT and middleware tests](../../apps/server/internal/platform/auth/).
- [Account creation, rollback, and returning-user tests](../../apps/server/internal/auth/service_integration_test.go).
- [HTTP onboarding isolation test](../../apps/server/internal/onboarding/service_integration_test.go).
- [Shared fixtures](../../apps/server/internal/testutil/).
- AUTH-11 is an existing test retained in the published commit. Its unrelated local deletion was excluded from this PR; the working-tree-only run did not include that test.

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

### CI dependency finding and fix

The first [Server CI run](https://github.com/frontend-alex/Loop/actions/runs/43281034949) passed the server validation job but failed Snyk. The scan reported two high-severity integer-overflow findings in transitive Testcontainers dependency `github.com/klauspost/compress` 1.18.7: [huff0 finding](https://security.snyk.io/vuln/SNYK-GOLANG-GITHUBCOMKLAUSPOSTCOMPRESSHUFF0-21755460) and [fse finding](https://security.snyk.io/vuln/SNYK-GOLANG-GITHUBCOMKLAUSPOSTCOMPRESSFSE-21755459).

Fix: update only that dependency to the reported fixed version 1.20.2 in [d6167a2](https://github.com/frontend-alex/Loop/commit/d6167a233fe97ac9acf2f275e4c5d1b30fe8ea8a). Local vet/module/race checks passed again. The [Snyk retest job](https://github.com/frontend-alex/Loop/actions/runs/43281431101/job/131403400055) succeeded; the [server validation retest](https://github.com/frontend-alex/Loop/actions/runs/43281431101/job/131403400155) also succeeded. The overall run still failed Sonar, so it is not described as a successful whole-workflow run.

### Sonar test-helper classification

Sonar's [PR quality gate](https://sonarcloud.io/dashboard?id=frontend-alex_Loop&pullRequest=21) reported new-code coverage of 0% against an 80% threshold. Shared `internal/testutil` setup files were classified as production code. With explicit user approval, [56438fa](https://github.com/frontend-alex/Loop/commit/56438fa9106a5e95c58df8a0724702c1113c21c6) added only `internal/testutil/**` to the test inclusions and source exclusions. Production files and quality thresholds were not excluded or relaxed. The [follow-up Server CI run](https://github.com/frontend-alex/Loop/actions/runs/43282109932) completed successfully, including the Sonar quality gate. Correct test classification is not evidence of 80% whole-application coverage.

## Revision, PR, review, and CI

- Branch: `feature/auth-testing`.
- Base revision: [cf6ec7d](https://github.com/frontend-alex/Loop/commit/cf6ec7df79f2b8b0ba94c3b4cc3ed353feb86da2). This base alone does **not** contain the tests.
- Test implementation commit: [30ef3a1](https://github.com/frontend-alex/Loop/commit/30ef3a128cc0836daaa32d11b2d10216068a7c67).
- Locally verified code/configuration revision: [56438fa](https://github.com/frontend-alex/Loop/commit/56438fa9106a5e95c58df8a0724702c1113c21c6); tested from a clean `git archive`, not only the modified working tree.
- PR: [#21 — authentication transactions and onboarding isolation](https://github.com/frontend-alex/Loop/pull/21), open against `develop`; not merged.
- Human review: pending; the PR review API returned no submitted reviews when checked. [PR review/diff](https://github.com/frontend-alex/Loop/pull/21/files). AI-assisted changes and local test execution are not human approval.
- Successful Server CI run for the verified code revision: [43282109932](https://github.com/frontend-alex/Loop/actions/runs/43282109932), completed with conclusion `success` at head SHA `56438fa9106a5e95c58df8a0724702c1113c21c6`. All three jobs succeeded: [server validation](https://github.com/frontend-alex/Loop/actions/runs/43282109932/job/131405814052), [Snyk dependency scan](https://github.com/frontend-alex/Loop/actions/runs/43282109932/job/131405814653), and [Sonar quality gate](https://github.com/frontend-alex/Loop/actions/runs/43282109932/job/131405814562). CI runs `go vet ./...` and `go test ./...`; the race-detector execution is separate local evidence. Earlier failures remain linked above rather than hidden. Subsequent documentation-only commits do not change the identified tested revision.
- Existing workflow: `.github/workflows/server.yml`; PRs to `develop`/`main` run server validation, with Snyk and Sonar jobs separately configured. The server validation failure stops later commands in that step; no deployment stage or required branch protection has been demonstrated here.
- Publication scope: test files, shared test helpers, Testcontainers dependency changes, the explicitly approved Sonar test classification fix, and this QA report. Unrelated Makefile edits and local file deletions are excluded.
- Separate iOS workflow: [43282093883](https://github.com/frontend-alex/Loop/actions/runs/43282093883) failed with no jobs. The checked-in `.github/workflows/ios.yaml` is fully commented out and was not changed here. No successful iOS CI or globally green PR is claimed.

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

- Independent human review and the user's manual Google sign-in observations are still required.
- Real Google/Apple sign-in, iOS flows, logout/revocation, network failures, invalid JSON, all protected routes, token theft, and malicious ownership inputs are outside this executed subset.
- The isolation test demonstrates A's legitimate request leaves B unchanged; it is not an exhaustive penetration test or a complete IDOR assessment.
- Schema setup uses GORM `AutoMigrate`, not a verified production migration chain.
- A database container used by tests is **not** evidence that the backend application was deployed through Docker. Live deployment and successful requests remain separate evidence.
- This report supports selected backend behavior, not five completed full-stack stories or completion of every LO3/LO4 requirement.
