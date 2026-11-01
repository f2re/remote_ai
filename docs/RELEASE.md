# Release pipeline

Remote AI ships through GitHub Actions. Release builds are Universal 2 and are verified before publication.

## CI

Every push and pull request runs one macOS verification job:

1. `swift test --parallel`
2. native `swift build -c release`
3. `./build.sh` to package a Universal 2 (`arm64` + `x86_64`) `.app`
4. `./tools/snap.sh` to render the deterministic 16-image light/dark screenshot set
5. `./tools/verify-release.sh` to verify bundle metadata, codesign, architectures, and screenshots
6. ZIP integrity checks and SHA-256 generation
7. upload of the app ZIP, screenshot ZIP, checksums, and individual PNGs as one verified candidate artifact

CI uses read-only repository permissions and cancels superseded runs on the same ref.

## Dry-run release

Push a `release/**` branch or run the **Release** workflow manually with a version such as `0.2.0`.

The workflow repeats the full release gate, creates the application ZIP and screenshot ZIP, writes SHA-256 checksums, and uploads the complete release candidate. A dry run does not create a GitHub Release.

## Publish

Create a version tag from a commit that is contained in `main`:

```bash
git switch main
git pull --ff-only
git tag v0.2.0
git push origin v0.2.0
```

The release workflow rejects tags whose target is not contained in `main`.

A successful tag build attaches:

- `RemoteAI-<version>-macOS.zip`
- `RemoteAI-<version>-screenshots.zip`
- `SHA256SUMS.txt`
- all individual light/dark release PNGs

If Apple signing/notarization secrets are absent, the app is ad-hoc signed and the GitHub Release is automatically marked as a prerelease. The binary is still codesign-verified and Universal 2, but users may encounter Gatekeeper friction.

## Developer ID signing and notarization

Configure these GitHub Actions secrets:

- `MACOS_CERTIFICATE_P12`: base64-encoded Developer ID Application `.p12`
- `MACOS_CERTIFICATE_PASSWORD`: password for the `.p12`
- `APPLE_ID`: Apple ID used by `notarytool`
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_APP_PASSWORD`: app-specific password

With all secrets present the workflow:

1. imports the Developer ID certificate into an ephemeral keychain
2. signs the Universal 2 app with hardened runtime and timestamp
3. verifies the bundle and release screenshots
4. submits the application ZIP to Apple notary service
5. staples and validates the ticket
6. runs `spctl --assess`
7. verifies the stapled app again
8. republishes the final ZIP and creates a normal (non-prerelease) GitHub Release

Secrets are never stored in the repository.

## Versioning

`Resources/Info.plist` keeps the development baseline version. During CI/CD, `APP_VERSION` and `BUILD_NUMBER` override `CFBundleShortVersionString` and `CFBundleVersion` in the packaged app without modifying the source plist.

`tools/verify-release.sh` rejects a package if the resulting bundle version differs from the requested release version.
