# Sprint 2 readiness — 26 November 2026

## Scope

Local changes based on `develop` revision
`8eb79bc4965cd97c09051a0df213862fd4aad6f5`, preserving the owner's staged
questionnaire/task-list and asset changes. These results describe the working
tree, not a published commit, merged PR, GitHub CI run, or live deployment.

## Fixes and evidence

- The iOS unit-test host no longer constructs the live app store or starts
  authentication/keychain/network effects. Unit tests still construct their own
  stores and explicitly override dependencies.
- Backend draft saves validate supplied question IDs, choices, enum shapes and
  step bounds. Completion requires five valid answers from one supported
  questionnaire and summary step 8. Both the released legacy questionnaire and
  current stable-ID questionnaire are accepted; unknown or mixed fields fail.
- Invalid completion returns HTTP 400 without persistence. Integration checks
  verify unchanged data, account isolation, and idempotent valid completion.
- OpenAPI examples are checked against the validator, and the documented
  `/users/me` response is checked against the actual Go response DTO.
- Deployment workflows now resolve a tracked `scripts/deploy.sh`. The helper
  uses immutable images, verified SSH host keys, an approved exact-commit
  artifact for production, and the actual readiness endpoint. See
  [deployment contract](../deployment.md).

## Executed checks

| Check | Result |
| --- | --- |
| `go test -race ./...` from `apps/server` | Passed; includes PostgreSQL integration tests |
| `go vet ./...` from `apps/server` | Passed |
| `sh -n scripts/deploy.sh` | Passed |
| `python3 -m unittest discover -s scripts/tests -v` | Five tests passed; SSH/GitHub CLI mocked |
| `xcodebuild test`, scheme `loop`, Debug simulator, signing disabled | Passed: 57 tests, zero failures, no runtime warnings in result summary |

iOS environment: Xcode 27.2, iPhone 18 Pro simulator, iOS 27.2. Parameterized
cases account for 70 device-level executions in the result bundle. The asset
compiler still reports the pre-existing missing `AccentColor` warning.

## Remaining release work

Review and publish these local fixes. Physical-device AlarmKit/FamilyControls
checks, host provisioning/credentials, actual staging/production deployment,
and Sprint 2 feature acceptance remain separate work. Passing backend tests
does not establish coverage for packages reported as having no test files.
