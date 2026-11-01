# Release pipeline

Remote AI ships through GitHub Actions.

## CI

Every push and pull request runs:

1. `swift test`
2. `swift build`
3. `./build.sh`
4. `./tools/snap.sh` on a separate macOS job
5. upload of 16 light/dark PNG screenshots as the `RemoteAI-screenshots` artifact

The screenshots cover all six pixel-cloud states plus the Settings surface and two state sheets.

## Dry-run release

Run the **Release** workflow manually with a version such as `0.1.0-dev`.

The workflow builds and tests the app, renders screenshots, creates an app ZIP and screenshot ZIP, writes SHA-256 checksums, and uploads the complete release candidate as a workflow artifact. A manual dry run does not create a GitHub Release.

## Publish

Push a version tag:

```bash
git switch main
git pull --ff-only
git tag v0.1.0
git push origin v0.1.0
```

A tag runs the same release gate and publishes the artifacts to GitHub Releases.

If Apple signing/notarization secrets are absent, the app is ad-hoc signed and the GitHub Release is automatically marked as a prerelease. This is suitable for development/testing but not frictionless Gatekeeper distribution.

## Optional Developer ID signing

Configure these GitHub Actions secrets:

- `MACOS_CERTIFICATE_P12`: base64-encoded Developer ID Application `.p12`
- `MACOS_CERTIFICATE_PASSWORD`: password for the `.p12`
- `APPLE_ID`: Apple ID used by `notarytool`
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_APP_PASSWORD`: app-specific password

With all secrets present the workflow:

1. imports the Developer ID certificate into an ephemeral keychain
2. signs the app with hardened runtime and timestamp
3. submits the ZIP to Apple notary service
4. staples and validates the ticket
5. republishes the final ZIP

Secrets are never stored in the repository.

## Versioning

`Resources/Info.plist` keeps the development baseline version. During CI/CD, `APP_VERSION` and `BUILD_NUMBER` override `CFBundleShortVersionString` and `CFBundleVersion` in the packaged app without modifying the source plist.
