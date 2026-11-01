# Warp integration

Remote AI treats Warp as the interactive handoff surface, not as another backend.

## One-click flow

When Claude is active or waiting, clicking the mascot opens a generated Warp Tab Config for the selected workspace.

```text
Remote AI mascot
      │ click
      ▼
~/.warp/tab_configs/remote_ai_<workspace>.toml
      │ warp://tab_config/<workspace>
      ▼
┌────────────────────────────┬─────────────────────────────────┐
│ Local review               │ Live Claude                    │
│ real local checkout        │ SSH -> existing remote tmux    │
│                            │                                 │
│ git status                 │ same Claude Code process       │
│ changed tracked files      │ existing transcript            │
│ untracked files            │ prompts / approvals / steering │
│ diff --stat                │                                 │
└────────────────────────────┴─────────────────────────────────┘
```

The right pane joins the existing tmux session. It never starts a second Claude process. Closing Warp detaches the terminal client while Claude continues running on the remote host.

The left pane uses the real local Git checkout after Mutagen synchronization. `.git` is intentionally not synchronized to the server.

## Why Tab Config instead of only a warp:// URL

Warp URI links can open windows, tabs and saved Tab Configs, but a plain URI does not execute an arbitrary startup command. A generated Tab Config is therefore the correct bridge: it defines the split layout and commands, while `warp://tab_config/...` is only the launcher.

## Review workflow

The local pane prints paths as ordinary terminal output. Warp recognizes file paths, so the user can open changed files directly in Warp's editor. The pane remains a normal shell after the summary commands finish, which allows local tests, Git inspection, or manual edits without leaving the handoff workspace.

The live Claude pane is focused initially. The user can type directly into the existing Claude Code conversation, approve actions, interrupt work, or give a follow-up task.

## Remote Control

Warp can publish a running third-party Claude Code session through its Remote Control feature. This is useful as an optional second layer after Remote AI has opened the session in Warp: the user can monitor and steer it from a browser, phone, or another computer.

Remote AI should not silently enable Warp Remote Control. Publishing uploads the live terminal/agent session to Warp's cloud and changes the privacy boundary. If we expose this later, it must be an explicit user action with clear disclosure.

## Future enhancements

1. Optional third pane configured per project for tests, dev server, or logs.
2. A compact generated command such as `remote-ai review` so Warp configs do not need to embed review shell commands.
3. A focus-back link from Remote AI notifications to the exact Warp pane when Warp exposes a stable public focus target for this workflow.
4. App-managed cleanup for stale `remote_ai_*.toml` files.
5. Project presets: review-only, Claude-only, review + Claude, review + Claude + logs.

## Security rules

- Never write Claude OAuth/session tokens into a Warp config.
- Never persist the Claude transcript only to populate the review pane.
- Keep SSH host-key checking enabled.
- Shell-quote SSH commands and TOML-escape every generated string.
- Keep Git metadata local until the separate Git bridge design is complete.
