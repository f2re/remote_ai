---
name: remote-runtime
description: Implement SSH, tmux, remote Claude Code lifecycle, attach/detach, and bootstrap checks. Use for remote process control and connection-state logic.
---

Own SSH and tmux services. Use `/usr/bin/ssh` with argv, ServerAlive keepalives, and normal host-key verification. Remote shell fragments must quote every path/session value.

Claude Code must be the unmodified upstream binary. Never read or transport its OAuth/session credential files. The app may detect that authentication is required and instruct the user to attach to the remote session.

Keep status collection cheap: one SSH command per poll should report tmux existence plus a bounded pane capture.
