# Deployment contract

Both GitHub workflows invoke `sh scripts/deploy.sh`. This script does not provision
a server or deploy on a developer's machine automatically.

- Staging passes the published `BACKEND_IMAGE` as an immutable GHCR digest.
- The production workflow uses `RELEASE_HEAD` to find a successful `Server CI` push run on
  `develop` for that exact commit, then downloads its `approved-image-<attempt>`
  artifact. Missing approval stops the workflow. It passes that image to the
  deploy script; the script does not select releases or call GitHub.
- `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY`, and `DEPLOY_KNOWN_HOSTS` come from
  the selected GitHub environment. Host-key verification remains enabled.
- The host must already have Docker Compose, registry pull access, and
  `/opt/loop/compose.deploy.yaml`. Its backend service must use
  `image: ${BACKEND_IMAGE}` and expose readiness at
  `http://127.0.0.1:8080/health/ready`. Secrets and database storage are
  host-managed, not copied from this repository.
- Publishing an image is not evidence of deployment. Staging and production
  remain opt-in through the existing environment variables/approval settings.

Local, non-deploying checks:

```sh
sh -n scripts/deploy.sh
python3 -m unittest discover -s scripts/tests -v
```

These tests fake SSH and GitHub CLI calls. They verify wiring and failure
handling, not access to the actual host or successful live deployment.

## What the script does, in order

1. Check that the server settings and an immutable image digest were supplied.
2. Write temporary SSH key/known-hosts files, automatically cleaned up on exit.
3. Connect to the server with host-key verification enabled.
4. In `/opt/loop`, pull the image and restart the backend through Docker Compose.
5. Call `/health/ready`, retrying while the backend starts.

`set -eu` stops the script when a command fails or a required variable is missing.
The `REMOTE` block runs on the server; the setup above it runs in GitHub Actions.
Staging and production use the same script. Production approval and image
selection belong to `.github/workflows/main.yml`, not the deployment script.
