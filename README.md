# Remote AI

A native macOS mascot for remote Claude Code sessions.

Remote AI keeps the interaction surface deliberately small: a floating mascot reports connection/sync/Claude state, while OpenSSH, Mutagen, and tmux do the actual work underneath.

## Architecture

- local code stays in your normal project folder
- Mutagen mirrors it to the remote host
- Claude Code runs inside remote tmux
- closing the terminal or losing the Mac connection does not stop Claude
- reconnect resumes synchronization and status monitoring

The agent framework is BAMA, pinned as `vendor/bama`.

```bash
git clone --recurse-submodules https://github.com/f2re/remote_ai.git
cd remote_ai
swift test
./build.sh --install
open ~/Applications/RemoteAI.app
```

## MVP dependencies

- macOS 14+
- Swift 6 toolchain
- OpenSSH (built into macOS)
- Mutagen (`brew install mutagen-io/mutagen/mutagen`)
- remote host with `tmux` and the unmodified `claude` CLI installed/authenticated

## SSH identity note

Remote AI can pass an explicit identity file to direct SSH commands. Mutagen itself uses OpenSSH and inherits normal OpenSSH configuration. If the server needs a non-default key, define the host/alias, `User`, `Port`, and `IdentityFile` in `~/.ssh/config` and use that alias as the Remote AI host. This keeps direct SSH and Mutagen on the same route.

## Safety defaults

Remote AI uses Mutagen `two-way-safe`, does not silently resolve sync conflicts, and never reads or stores Claude OAuth/session credentials.

Development is currently on `feat/remote-ai-mascot-mvp`.
