# Maintainer review patterns

Observed 2026-09-23 from 41 submission threads selected from the 100 most recently updated submission-labeled issues (open and closed). This is a broad, purposive sample, not all marketplace history or an exhaustive private review policy. Older blocked comments can coexist with a later listed status. Links below support the historical findings, not claims that current plugin code remains vulnerable.

Apply each section to relevant data/privilege boundaries. These checks extend beyond the five deterministic scanner findings. The public comments are attributed to `HANCORE-linux`; whether that person uses AI assistance is not established.

## Stable review target

[Android Mirror #7396](https://github.com/omacom/omarchy-plugin-marketplace/issues/7396#issuecomment-5792752793) and [Pullover #8291](https://github.com/omacom/omarchy-plugin-marketplace/issues/8291#issuecomment-5790834901) show repeated rejection when HEAD moved after scans. In Android Mirror, reports covered `a74f3d94eef6889f22793a75083e7492088b20eb`, the author reported a fix at `52c1dfc914599c79e34bdd6b1a1a83a208ac82c6`, and the reviewer then observed `63306320d1297437117e9a593162b14ba8488ae7`. Those are historical values, not targets to reuse.

[OmaNitro #5540](https://github.com/omacom/omarchy-plugin-marketplace/issues/5540#issuecomment-5786650600) explicitly says `/validate` comments do not trigger the pipeline. Edit the existing issue body after finishing and publishing changes. [System+ #7666](https://github.com/omacom/omarchy-plugin-marketplace/issues/7666#issuecomment-5779931029) shows why an attached remediation report cannot substitute for committed implementation.

## Secrets and private payloads

Follow secrets through every subprocess hop, fallback, error and persistence path. Use private stdin/descriptors or the native secret API; never interpolate a secret into `sh -c`, including positional arguments. Clear transient UI properties after handoff. Redact logs and bounded diagnostics. Private files need verified owner-only permissions and safe creation/replacement; chmod after an unsafe write is inadequate.

Evidence: [ADB pairing #7396](https://github.com/omacom/omarchy-plugin-marketplace/issues/7396#issuecomment-5735889477), [notes and E2EE password #6087](https://github.com/omacom/omarchy-plugin-marketplace/issues/6087#issuecomment-5654129441), [AI conversation/API key #7524](https://github.com/omacom/omarchy-plugin-marketplace/issues/7524#issuecomment-5742003143), [hotspot PSK #7130](https://github.com/omacom/omarchy-plugin-marketplace/issues/7130#issuecomment-5701624604), [camera credentials #4784](https://github.com/omacom/omarchy-plugin-marketplace/issues/4784#issuecomment-5775175701).

For password-encrypted stored data, review KDF strength, parameter versioning and migration against current cryptographic guidance. The weak-KDF finding in [#6087](https://github.com/omacom/omarchy-plugin-marketplace/issues/6087#issuecomment-5656384186) is contextual; don't copy a universal iteration count from it.

## Enforce limits before buffering

For remote APIs, subprocess output, files, history, search/export results and downloaded media, bound bytes as received, before `StdioCollector`, `response.text/json`, `FileView.text`, `capture_output`, shell command substitution or JSON parsing. Cover both stdout and stderr, error bodies, aggregate pages/items, field lengths, retained UI logs and disk writes. Use max+1 reads to detect and reject overflow instead of quietly parsing a truncated result.

A timeout is not a byte ceiling. A line/item limit is not a byte ceiling. Content-Length/getsize is at most an early check, not enforcement over actual bytes. Limit concurrent jobs/poll overlap. Apply a whole-job deadline and terminate/reap descendants on timeout, overflow and teardown; killing only the parent can leave children holding pipes.

Evidence: [Taskwarrior post-buffer check #8328](https://github.com/omacom/omarchy-plugin-marketplace/issues/8328#issuecomment-5794890001), [Docker stderr bypass #4280](https://github.com/omacom/omarchy-plugin-marketplace/issues/4280#issuecomment-5792679867), [Flatpak error streams #6717](https://github.com/omacom/omarchy-plugin-marketplace/issues/6717#issuecomment-5794101654), [API refresh/error paths #8128](https://github.com/omacom/omarchy-plugin-marketplace/issues/8128#issuecomment-5784912804), [rclone metadata filter #6087](https://github.com/omacom/omarchy-plugin-marketplace/issues/6087#issuecomment-5715506765).

Verification: oversized single-line stdout, stderr-only flood, stalled child that survives its parent, oversized error response, and lying/absent size metadata. Check bounded memory/output and complete cleanup, not just a constant in source.

## Files, identity and destructive actions

For mutable state, secrets, caches and externally supplied filenames, reject traversal and validate actual descriptor identity. Prefer retained directory descriptors and component-wise no-follow opens; open once, check regular type/owner/mode with `fstat`, read cap+1 from that descriptor. FIFO rejection needs nonblocking opens where appropriate. A final-component `O_NOFOLLOW` doesn't protect mutable ancestors.

Write via unpredictable exclusive private sibling files and an atomic descriptor-relative replacement. Refuse unsafe parents, changed identities and symlink destinations. Avoid predictable `.tmp`, truncation through links, resolve-then-reopen races, and broad uninstall globs. Match protection to the actual store; fixed kernel endpoints are not the same as mutable user files.

Evidence: [history reader #6628](https://github.com/omacom/omarchy-plugin-marketplace/issues/6628#issuecomment-5793847736), [notes traversal and ancestor race #6674](https://github.com/omacom/omarchy-plugin-marketplace/issues/6674#issuecomment-5793861377), [state/SQLite paths #6694](https://github.com/omacom/omarchy-plugin-marketplace/issues/6694#issuecomment-5694076170), [FIFO and pre-read boundary #2542](https://github.com/omacom/omarchy-plugin-marketplace/issues/2542#issuecomment-5471926331).

Destructive UI actions should bind confirmation to an immutable identity and re-query state immediately before use: [Docker removal #4280](https://github.com/omacom/omarchy-plugin-marketplace/issues/4280#issuecomment-5508892750). Privileged signaling needs a retained process identity (pidfd/service boundary) or unprivileged cleanup: checking `/proc` then killing a numeric PID still races with reuse, as in [Phonecam #7497](https://github.com/omacom/omarchy-plugin-marketplace/issues/7497#issuecomment-5795173133).

## Treat external text and images as data

Force QML `Text.PlainText` on every external string sink, including tooltips/toasts: window titles, MPRIS, task data, SSIDs, API fields, errors. Use GTK text APIs or explicit markup escaping. Use a JSON encoder, not string concatenation. Use fixed argv arrays for untrusted non-secret values; that avoids shell evaluation but does not solve secret exposure.

Evidence: [Dock #8307](https://github.com/omacom/omarchy-plugin-marketplace/issues/8307#issuecomment-5792100747), [Musica #7873](https://github.com/omacom/omarchy-plugin-marketplace/issues/7873#issuecomment-5767300787), [Wi-Fi shell/markup #7465](https://github.com/omacom/omarchy-plugin-marketplace/issues/7465#issuecomment-5794231762), [weather encoding #7666](https://github.com/omacom/omarchy-plugin-marketplace/issues/7666#issuecomment-5752578355).

Untrusted image URLs need scheme/path policy, streaming size and time limits, validated file type and decoded-pixel bounds before the shell loads a bounded local file. Don't fallback to direct remote QML Image loading when a safe helper fails: [Vantage #7716](https://github.com/omacom/omarchy-plugin-marketplace/issues/7716#issuecomment-5793021017), [OmaHub #8022](https://github.com/omacom/omarchy-plugin-marketplace/issues/8022#issuecomment-5792501095).

## Dependencies, builds and provenance

Review all executable inputs, including transitive/build dependencies and optional setup paths. Bind Git to full SHAs, container images to digests, downloadable artifacts to verified hashes, package installs to consumed lockfiles with integrity enforcement. Pin toolchains/actions where the build would otherwise fetch mutable inputs. A version label, `Cargo.lock`, or pinned outer installer alone doesn't authenticate every fetched dependency.

Evidence: [pip build isolation #8123](https://github.com/omacom/omarchy-plugin-marketplace/issues/8123#issuecomment-5778796110), [pinned installer still resolves packages #7945](https://github.com/omacom/omarchy-plugin-marketplace/issues/7945#issuecomment-5768103964), [in-panel bypass #7945](https://github.com/omacom/omarchy-plugin-marketplace/issues/7945#issuecomment-5774628228), [uv tool dependencies #8282](https://github.com/omacom/omarchy-plugin-marketplace/issues/8282#issuecomment-5789844583), [pip upgrade #8227](https://github.com/omacom/omarchy-plugin-marketplace/issues/8227#issuecomment-5785444445), [container digest #4784](https://github.com/omacom/omarchy-plugin-marketplace/issues/4784#issuecomment-5547976240).

Inspect CI actions and what those actions download; pin full action SHAs, narrow permissions, disable persisted checkout credentials. An action SHA doesn't pin a mutable container it launches: [firmware CI #6393](https://github.com/omacom/omarchy-plugin-marketplace/issues/6393#issuecomment-5694998707), [Rust toolchain/CI #6535](https://github.com/omacom/omarchy-plugin-marketplace/issues/6535#issuecomment-5793827698).

Auto-build/credential/privileged execution needs trusted executable identities and controlled interpreter/build environments. Don't blindly trust PATH tools, user-writable fallback binaries or pre-existing build outputs. For integrity stamps, bind complete build inputs **and binary bytes**, verify before execution and fail closed on missing/mismatched identity. Evidence: [OmaTube executable/parent identity #6300](https://github.com/omacom/omarchy-plugin-marketplace/issues/6300#issuecomment-5645101240), [incomplete binary stamp #4149](https://github.com/omacom/omarchy-plugin-marketplace/issues/4149#issuecomment-5791317083), [existing-source bypass #8330](https://github.com/omacom/omarchy-plugin-marketplace/issues/8330#issuecomment-5794938556). Apply this to the relevant sensitive/automatic boundary, not as a blanket claim that every user-selected executable is forbidden.

Downloaded fonts/media were also reviewed for immutable source and digest verification: [Lock Designs #7747](https://github.com/omacom/omarchy-plugin-marketplace/issues/7747#issuecomment-5770278475). AppImage extraction itself executes code; verify bounded downloads and obtain product-user consent before that first execution: [#8256](https://github.com/omacom/omarchy-plugin-marketplace/issues/8256#issuecomment-5789684040).

## Privileged boundaries

Review root helpers, Polkit, sudoers, package installation and Docker-group access. Fixed commands/arguments must be enforced by the trusted privileged component, not only mutable UI code. Authenticate the bootstrap and payload independently of a user-writable checkout. Copying/chowning after reading mutable inputs doesn't establish provenance; embedding hashes in the same replaceable root-run script doesn't either.

Evidence: [OmaNitro repeated bootstrap failures #5540](https://github.com/omacom/omarchy-plugin-marketplace/issues/5540#issuecomment-5794881191), [XPS Power #7617](https://github.com/omacom/omarchy-plugin-marketplace/issues/7617#issuecomment-5792923632), [cleanup whitelist #7145](https://github.com/omacom/omarchy-plugin-marketplace/issues/7145#issuecomment-5787887873), [login theme #7747](https://github.com/omacom/omarchy-plugin-marketplace/issues/7747#issuecomment-5794155725).

Sudoers generation also needs OS-verified account identity, strict values, protected staging, `visudo -cf`, atomic installation and fixed root-owned helpers: [#7130](https://github.com/omacom/omarchy-plugin-marketplace/issues/7130#issuecomment-5787797981). Preserve explicit setup/privilege documentation even when it triggers manual review.

## Network services and browser collectors

Authenticate before accepting expensive bodies. Bound headers, uploads, clipboard, disk reservations, global/per-peer concurrency and absolute request deadlines; per-read timeouts permit slow clients. Avoid credential-bearing status responses/URLs/logs, wildcard CORS on sensitive APIs and unauthenticated clipboard writes. Review companion apps too: [Omasend authentication #4149](https://github.com/omacom/omarchy-plugin-marketplace/issues/4149#issuecomment-5594065389), [aggregate/deadline limits](https://github.com/omacom/omarchy-plugin-marketplace/issues/4149#issuecomment-5685480590), [Android companion](https://github.com/omacom/omarchy-plugin-marketplace/issues/4149#issuecomment-5715758048).

Keep browser sandboxing enabled and scope credentials instead of copying a whole signed-in profile into an unsandboxed collector: [Ollama Cloud Usage #7629](https://github.com/omacom/omarchy-plugin-marketplace/issues/7629#issuecomment-5752425238).

## Agent-control files in the payload

Reviewers repeatedly rejected root `AGENTS.md`, `CLAUDE.md`, `.claude/` instructions and code that writes Codex hooks/config. Move contributor prose to ordinary documentation outside auto-loaded agent-control names, and remove agent-hook installation from the marketplace payload. This is an observed eligibility boundary; moving the install instructions into README alone did not fix shipped hook code.

Evidence: [OpenCode Usage #6488](https://github.com/omacom/omarchy-plugin-marketplace/issues/6488#issuecomment-5645131153), [Exposé #8261](https://github.com/omacom/omarchy-plugin-marketplace/issues/8261#issuecomment-5789707014), [Omarchy Watch #6393](https://github.com/omacom/omarchy-plugin-marketplace/issues/6393#issuecomment-5642448113). Do not treat this as permission to delete the current user's unrelated workspace instructions. The skill itself is a separate authoring tool, not part of the Omarchy runtime repository.
