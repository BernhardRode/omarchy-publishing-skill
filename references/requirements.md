# Official contract and preflight

Research date: 2026-09-23. Marketplace checkout: `3382370f6b9a5334876d461a96335198bd0111c5`. Refresh these sources before submission. The publishing website is a shorter overview than the repository's current intake/security implementation.

## Source hierarchy

- [Publishing overview](https://plugins.omarchy.org/publish.html), [development guide](https://plugins.omarchy.org/develop.html).
- [CLI/AI submission guide](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md), [issue form](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/.github/ISSUE_TEMPLATE/submit-plugin.yml).
- [Manifest validator](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/scripts/build-catalog.mjs), [intake parser](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/scripts/submission.mjs).
- [Security policy](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SECURITY.md), [deterministic policy owner](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/scripts/security-baseline-policy.mjs), [scanner](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/scripts/security-baseline-scanner.mjs).
- [Validation workflow](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/.github/workflows/validate-submission.yml), [routing workflow](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/.github/workflows/route-issue-automation.yml), [approval workflow](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/.github/workflows/approve-submission.yml).
- [Existing listing/update guide](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/VERIFICATION.md).

When sources differ, report the discrepancy and use the current implementation for what automation accepts. Do not infer unpublished reviewer rules from scanner behavior.

## Repository and manifest

New submissions use a public GitHub root repository URL, one root plugin manifest, root README with installation/removal, a root license file, and documented dependencies. Existing legacy multi-plugin sources have different update handling; do not scaffold new submissions from that exception.

Manifest contract: `schemaVersion: 1`; nonempty `id`, `name`, `version`, `author`, `description`; supported `kinds` and matching `entryPoints`. Community text limits from the validator are ID 128, name 120, version 64, author 120, description 500, optional license 120 characters. A manifest license field does not replace the root license file.

IDs use lowercase `[a-z0-9][a-z0-9._-]*`, exclude `..`, and cannot begin `omarchy.`. Prefer a namespaced ID; current and retired IDs are unavailable for reuse. Check the current catalog and registry, not only search results. Update every ID reference consistently.

| Kind | Entry-point key |
| --- | --- |
| bar-widget | barWidget |
| bar | bar |
| panel | panel |
| overlay | overlay |
| menu | menu |
| service | service |

Every entry point must exist, stay relative, and avoid traversal, backslash, colon, newline and NUL. Plugin folders cannot contain symlinks. `barWidget.defaultSection`, when present, is left/center/right. A nested panel loaded by a bar widget does not automatically require a standalone panel kind. Remove development-only clone metadata when publishing; preserve valid runtime lifecycle behavior.

Optional root previews: `preview.png`, `.jpg`, `.jpeg`, `.webp`, `.avif`; maximum 50 MB and 40 megapixels. The service optimizes them. Do not require a preview as a submission gate.

## Baseline policy snapshot

At research time: baseline version **3**, marker protocol **4**, enforcement **selective**. These are different version fields.

| Finding ID | Review preparation |
| --- | --- |
| curl-pipe-shell | Remove direct download/execution; use a trusted package route or verified immutable input. |
| cargo-git-unpinned | Require full 40-character `--rev`; `--locked` alone doesn't pin Git. |
| remote-git-execution-unpinned | Bind external source to a full commit, checkout detached, verify the execution path. |
| sudoers-dangerous-passwordless-command | Remove broad NOPASSWD command surfaces; privileged helpers need a fixed authenticated boundary. |
| privileged-process-control-from-shared-temp | Do not use shared mutable PID state to authorize privileged signals. |

Review capabilities: `installer`, `package-manager`, `privilege`, `remote-build`, `bundled-executable-binary`, `service-management`, `sudoers-modification`. Documentation can trigger them too. Same-repository builds and fixed helper policies still require review; they are not automatic rejection.

Outcomes: no findings/capabilities → `passed`; capabilities only → `review-required`; findings → `needs-fixes`. **Outcome differs from publication disposition:** selective enforcement blocks the last two finding IDs above; remote-execution findings can instead require explicit acceptance of the exact evidence. Never interpret that exception as recommended practice or permission to suppress a finding. Scan failure is not an eligible result. All new listings still need explicit maintainer approval.

Scan ceilings: 1,000 relevant files, 8 MiB total text, 512 KiB per file. Special setup/binary probes have further limits. Consult current scope code when a scan is incomplete; do not move runtime files into excluded directories to pass.

## Concrete validation

First inspect tool availability/version. Static local checks, using the actual plugin directory and QML files:

```bash
omarchy plugin validate /absolute/path/to/plugin
qmllint -I "$OMARCHY_PATH/shell" /absolute/path/to/plugin/BarWidget.qml
```

Do not run `omarchy plugin clone`, install, enable, rescan or restart just to validate structure. Full click/open/close/disable/re-enable/restart/removal testing belongs in an authorized runtime environment. Note absent hardware or imports explicitly.

For closer parity, use a separately inspected checkout of the official marketplace, its required Node version (24 at research time), and locked dependencies. Read its current CLI entry points before execution. Never run community install hooks for static scanning. These official commands inspect the **published** repository; they don't validate uncommitted changes:

```bash
VALIDATION_METADATA_PATH=/absolute/output/validation-metadata.json \
  node scripts/validate-submission.mjs --repo=https://github.com/OWNER/REPO
node scripts/security-baseline.mjs \
  --metadata=/absolute/output/validation-metadata.json \
  --json=/absolute/output/security-baseline.json
```

Read outcome and disposition from JSON even when exit status is zero; a completed scan can report findings. These local artifacts are not GitHub bot attestations. Don't fabricate missing metadata or downgrade failures. Network/API availability and marketplace dependencies can prevent this optional parity check; report that limitation.

## Intake metadata and posting

Categories: Appearance, Desktop, Developer Tools, Hardware, Kids, Productivity, System, Widgets, Other. Use exact case.

Choose 1–3 canonical tags: ai, bar, education, games, hyprland, kids, launcher, media, power-management, quickshell, security, system, vpn, workspaces. The form displays humanized variants; the parser normalizes them. Preserve exact template headings and checklist. Fill optional sections with `_No response_` when unused.

After owner authorization, create using a body file:

```bash
gh issue create --repo omacom/omarchy-plugin-marketplace \
  --title '[Plugin]: Actual plugin name' --body-file /absolute/path/submission-body.md
```

For a correction, fetch the latest body first, preserve it, and use the existing issue:

```bash
gh issue edit ISSUE_NUMBER --repo omacom/omarchy-plugin-marketplace \
  --body-file /absolute/path/updated-submission-body.md
```

Only run these external writes when authorized. A posting request already approved in the session needs no redundant confirmation. Ownership claims still require evidence/owner confirmation. The official AI submission section asks for owner confirmation of all declarations and review of the completed body before creation.

A fresh issue-body edit retriggers validation; `/validate` comments do not. Freeze current HEAD and compare full validation/baseline/review SHA before requesting approval. Historical `approved-for-listing` no longer publishes new listings. Listed updates use the verification form and retain the old snapshot until promotion succeeds. Current install commands may fetch upstream HEAD; snapshot verification does not automatically cover later upstream code.
