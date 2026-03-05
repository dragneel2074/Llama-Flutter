# Repository Operations Guide

This project uses two separate GitHub repositories:

1. Development repository (source of truth):
   - https://github.com/dragneel2074/llama_flutter_dev
   - Local path:
     `C:\Users\ADMIN\Documents\HP\old_ssd\MY_FILES\flutter_projects\llama_flutter_android`
2. Production repository (pub.dev facing):
   - https://github.com/dragneel2074/Llama-Flutter
   - Local path:
     `C:\Users\ADMIN\Documents\HP\old_ssd\MY_FILES\flutter_projects\Llama-Flutter`

## Recommended Model

- Do all feature work, dependency updates, and llama.cpp upgrades in `llama_flutter_dev`.
- Treat `Llama-Flutter` as a release mirror only.
- Promote tested commits from dev to production.
- Publish to pub.dev only from production-ready state.

## Branch Strategy

- Dev repo:
  - `dev` = active development branch.
  - Optional short-lived `release/<version>` branch for final release validation.
- Production repo:
  - `master` = stable, publishable branch only.

## llama.cpp Update Automation

Workflow file:
- `.github/workflows/llama-cpp-auto-update.yml`

Triggers:
- Manual: `workflow_dispatch`
- Scheduled: every Monday at `03:17 UTC` (`17 3 * * 1`)

Behavior:
- Reads latest release tag from `ggml-org/llama.cpp`.
- Compares against `.llama_cpp_version`.
- If newer:
  - updates `android/src/main/cpp/llama.cpp`
  - updates `.llama_cpp_version`
  - opens PR into `dev`.

Notes:
- Scheduled GitHub Actions run only from the repo default branch.
- If `dev` is not default branch, use manual dispatch or switch default branch.

## Promotion + Publish Automation

Workflow file:
- `.github/workflows/promote-to-production-and-publish.yml`

Trigger:
- Manual only (`workflow_dispatch`)

Inputs:
- `dev_ref`: ref to promote
- `sync_to_production`: push selected ref to production `master`
- `publish_pub_dev`: optional pub.dev publish

Required GitHub secrets:
- `PRODUCTION_REPO_PAT`
  - PAT with push access to `dragneel2074/Llama-Flutter`
- `PUB_DEV_CREDENTIALS_JSON`
  - JSON content of `~/.pub-cache/credentials.json` from an authenticated machine

## Day-to-Day Flow

1. Work in dev repo on `dev`.
2. Open/merge PRs in dev repo.
3. For llama.cpp bumps:
   - let scheduled/manual auto-update open PR
   - review and run validation
   - merge into `dev`.
4. Validate release candidate:
   - run tests/builds
   - optionally create `release/<version>` for final checks.
5. Promote to production:
   - run promotion workflow
   - push selected ref to `Llama-Flutter:master`.
6. Publish to pub.dev:
   - either via same workflow (`publish_pub_dev=true`)
   - or manually after dry-run.

## Release Checklist

Before promoting:
- `flutter analyze` passes
- Android build passes (`flutter build apk --debug` in `example/`)
- `CHANGELOG.md` updated
- `README.md` version references updated (if needed)
- `.llama_cpp_version` matches vendored tree (if llama.cpp was updated)

Before pub.dev publish:
- `pubspec.yaml` version bumped correctly
- `flutter pub publish --dry-run` passes
- production repo `master` contains exactly intended files

## Local Multi-Repo Workflow (Optional)

If working with both local folders:

1. Implement and validate in:
   `...\llama_flutter_android`
2. Sync result into:
   `...\Llama-Flutter`
   only when ready to release.

Prefer using GitHub workflow promotion for consistency and audit trail.

## Safety Rules

- No direct hotfix edits in production repo unless emergency.
- No force push to production `master` unless absolutely necessary.
- Keep automation opening PRs rather than directly pushing dev changes.
- Review every llama.cpp bump PR even if build is green.
