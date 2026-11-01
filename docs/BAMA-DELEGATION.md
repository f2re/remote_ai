# BAMA delegation map

This repository vendors `daveebbelaar/bama` at `vendor/bama` and uses its skills as the authoritative macOS development workflow.

## Active pixel-cloud pass

| Work packet | BAMA skill | GitHub issue | Output |
| --- | --- | --- | --- |
| Interaction/state language | `skills/design/ux-design` | #8 | `docs/BRIEF.md`, `docs/GLOSSARY.md` |
| Native visual system + motion tokens | `skills/design/mac-design`, `skills/design/design-system` | #9 | `design/DESIGN-SYSTEM.md`, `Sources/RemoteAI/UI/*` |
| Custom pixel-cloud component | `skills/design/design-kit` | #10 | `design/KIT.md`, mascot SwiftUI components |
| Verification/improvement loop | `skills/ship/build-and-verify`, `skills/ship/improve-loop`, `skills/ship/test-mac-app` | #11 | CI/build/test verification and repair commits |

## Execution contract

1. Read the owning `SKILL.md` before touching its files.
2. Keep each packet bounded to its declared output and acceptance criteria.
3. Commit design/spec work before implementation work.
4. Commit implementation before verification repairs.
5. Do not duplicate BAMA guidance in new local agent prompts unless Remote AI has a project-specific invariant that BAMA cannot know.
6. Every handoff records files changed, checks run and known risks.

## Current sequence

`#8 ux-design` -> `#9 mac-design/design-system` -> `#10 design-kit implementation` -> `#11 build-and-verify/improve-loop`.

The repo-local `orchestrator` and `macos-ui` wrappers route to these skills. They are not alternative frameworks.
