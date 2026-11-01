# Glossary

| Term | Means | Not |
| --- | --- | --- |
| Mascot | The persistent pixel-cloud control that shows Remote AI state and opens the main handoff action | dashboard, widget, status card |
| Workspace | One local project folder plus its deterministic mirrored remote directory and tmux session | server, repository metadata |
| Review | The Warp handoff that shows local Git changes beside the live remote Claude tmux session | embedded editor, transcript archive |
| Start / Reconnect | Prepare SSH, resume/create Mutagen, and start/reuse the remote Claude session | create a second Claude process |
| Stop | Flush synchronization, stop the remote Claude session, then pause the mirror | delete workspace, discard edits |
| Waiting | Claude is idle or requires user input and the workspace is synchronized | offline, finished forever |
| Thinking | Claude is actively processing a turn or using tools | syncing files |
| Syncing | Mutagen is scanning/staging/transferring workspace changes | Claude thinking |
| Offline | Remote session or mirror is not currently active/reachable | error that always needs an alert |
| Error | A state requiring attention, such as a sync conflict or runtime failure | generic warning color only |
