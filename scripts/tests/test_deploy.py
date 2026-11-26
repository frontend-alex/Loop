"""Deployment wiring tests; all external commands are faked, never deployed."""

import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "deploy.sh"
WORKFLOW = SCRIPT.parents[1] / ".github/workflows/main.yml"
IMAGE = "ghcr.io/frontend-alex/loop-backend@sha256:" + "a" * 64


class DeployTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(
            os.environ,
            PATH=f"{self.root}:{os.environ['PATH']}",
            DEPLOY_HOST="staging.example.test",
            DEPLOY_USER="loop",
            DEPLOY_KEY="fake-test-key",
            DEPLOY_KNOWN_HOSTS="fake-test-host-key",
            BACKEND_IMAGE=IMAGE,
            TEST_ROOT=str(self.root),
            TEST_IMAGE=IMAGE,
        )
        self.env.pop("RELEASE_HEAD", None)
        self.fake("ssh", 'printf "%s\\n" "$@" > "$TEST_ROOT/ssh-args"\ncat > "$TEST_ROOT/remote-script"\n')

    def fake(self, name, body):
        path = self.root / name
        path.write_text("#!/bin/sh\nset -eu\n" + body)
        path.chmod(0o700)

    def run_script(self):
        return subprocess.run(["sh", str(SCRIPT)], env=self.env, text=True, capture_output=True)

    def select_production_image(self):
        # Execute the actual workflow's shell block, not a copy of its logic.
        step = WORKFLOW.read_text().split("      - name: Select the staging-approved image\n", 1)[1]
        block = step.split("        run: |\n", 1)[1].split("\n      - name:", 1)[0]
        self.env["RUNNER_TEMP"] = str(self.root)
        self.env["GITHUB_OUTPUT"] = str(self.root / "outputs")
        return subprocess.run(
            ["sh", "-eu", "-c", textwrap.dedent(block)],
            env=self.env, text=True, capture_output=True,
        )

    def test_staging_uses_digest_strict_host_keys_and_readiness(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        args = (self.root / "ssh-args").read_text()
        self.assertIn("StrictHostKeyChecking=yes", args)
        self.assertIn(IMAGE, args)
        arguments = args.splitlines()
        key_file = Path(arguments[arguments.index("-i") + 1])
        self.assertFalse(key_file.exists(), "Temporary SSH credentials must be cleaned up")
        remote = (self.root / "remote-script").read_text()
        self.assertIn("/health/ready", remote)
        self.assertIn("--no-build", remote)
        self.assertNotIn("fake-test-key", result.stdout + result.stderr)

    def test_mutable_or_injected_images_are_rejected_before_ssh(self):
        for image in ["ghcr.io/frontend-alex/loop-backend:latest", IMAGE + "\nmalicious", IMAGE + ";false"]:
            with self.subTest(image=image):
                self.env["BACKEND_IMAGE"] = image
                self.assertNotEqual(self.run_script().returncode, 0)
                self.assertFalse((self.root / "ssh-args").exists())

    def test_production_requires_and_uses_approved_artifact(self):
        self.env.update(RELEASE_HEAD="b" * 40, GH_TOKEN="fake", GITHUB_REPOSITORY="frontend-alex/Loop")
        self.env["BACKEND_IMAGE"] = "must-not-bypass-approval"
        self.fake("gh", """
printf '%s\\n' "$*" >> "$TEST_ROOT/gh-args"
case "$1 $2" in
    'run list') printf '123\\n';;
    'api repos/'*) printf '2\\n';;
    'run download')
        while [ "$1" != '--dir' ]; do shift; done
        shift
        mkdir -p "$1"
        printf '%s\\n' "$TEST_IMAGE" > "$1/approved-image.txt";;
    *) exit 1;;
esac
""")
        result = self.select_production_image()
        self.assertEqual(result.returncode, 0, result.stderr)
        selected = (self.root / "outputs").read_text().removeprefix("image=").strip()
        self.assertEqual(selected, IMAGE)
        self.env["BACKEND_IMAGE"] = selected
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(IMAGE, (self.root / "ssh-args").read_text())
        gh_args = (self.root / "gh-args").read_text()
        self.assertIn("--commit " + "b" * 40, gh_args)
        self.assertIn("--name approved-image-2", gh_args)

    def test_missing_production_approval_fails_closed(self):
        self.env.update(RELEASE_HEAD="b" * 40, GH_TOKEN="fake", GITHUB_REPOSITORY="frontend-alex/Loop")
        self.fake("gh", "exit 1\n")
        self.assertNotEqual(self.select_production_image().returncode, 0)
        self.assertFalse((self.root / "ssh-args").exists())

    def test_no_successful_staging_run_stops_production(self):
        self.env.update(RELEASE_HEAD="b" * 40, GH_TOKEN="fake", GITHUB_REPOSITORY="frontend-alex/Loop")
        self.fake("gh", "printf '\\n'\n")
        result = self.select_production_image()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No successful staging workflow", result.stderr)
        self.assertFalse((self.root / "outputs").exists())

    def test_invalid_approved_artifact_does_not_set_workflow_output(self):
        self.env.update(
            RELEASE_HEAD="b" * 40, GH_TOKEN="fake", GITHUB_REPOSITORY="frontend-alex/Loop",
            TEST_IMAGE=IMAGE + "\nextra-output=malicious",
        )
        self.fake("gh", """
case "$1 $2" in
    'run list') printf '123\\n';;
    'api repos/'*) printf '2\\n';;
    'run download')
        while [ "$1" != '--dir' ]; do shift; done
        shift
        mkdir -p "$1"
        printf '%s\\n' "$TEST_IMAGE" > "$1/approved-image.txt";;
    *) exit 1;;
esac
""")
        self.assertNotEqual(self.select_production_image().returncode, 0)
        self.assertFalse((self.root / "outputs").exists())

    def test_remote_failure_propagates(self):
        self.fake("ssh", "exit 42\n")
        self.assertEqual(self.run_script().returncode, 42)


if __name__ == "__main__":
    unittest.main()
