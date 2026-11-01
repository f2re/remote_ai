# Manual failure-injection checklist

Run these after unit tests on a disposable workspace.

1. SSH unavailable: block/stop the server. Mascot must become offline, not error-loop, and remote tmux must remain untouched.
2. Reconnect: restore SSH. Existing Mutagen/tmux names must be reused; no duplicate workspace/session is created.
3. Mutagen missing: temporarily remove Mutagen from PATH. Start must show an actionable dependency error and never delete remote data.
4. tmux missing: use a host without tmux. Start must fail before creating a Claude session.
5. Claude missing: use a host without `claude`. Start must fail with an actionable message; app must not install or substitute a modified binary automatically.
6. Sync conflict: modify the same tracked file differently on both sides while disconnected, then reconnect. Mascot must show error and Stop must not kill/pause before a successful flush.
7. Host-key change: simulate a changed SSH host key. Connection must fail; the app must never bypass the warning with `StrictHostKeyChecking=no`.
8. Sleep/network loss during thinking: detach the Mac while Claude is active. Remote tmux must continue. After reconnect, files must catch up and state must return to syncing/thinking/waiting.
9. Terminal attach: custom SSH port and identity must be reflected in the generated attach command.
10. Notification: transition from thinking to waiting should create one local notification, not repeat on every poll.
