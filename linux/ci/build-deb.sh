#!/usr/bin/env bash
set -euo pipefail

# Run inside Debian container; Debian compatibility != native Astra certification.
target="${1:?Usage: build-deb.sh debian10|debian12}"
case "$target" in
  debian10)
    printf 'deb http://archive.debian.org/debian buster main\n' >/etc/apt/sources.list
    rm -f /etc/apt/sources.list.d/* || true
    apt-get -o Acquire::Check-Valid-Until=false update
    ;;
  debian12) apt-get update ;;
  *) echo "Unknown compatibility baseline: $target" >&2; exit 2 ;;
esac
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates cmake make g++ qtbase5-dev dpkg-dev desktop-file-utils
cmake -S /src/linux -B /tmp/rai-build \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DASTRA_TARGET="$target"
cmake --build /tmp/rai-build --parallel 2
ctest --test-dir /tmp/rai-build --output-on-failure
desktop-file-validate /src/linux/packaging/remote-ai-astra.desktop
(cd /tmp/rai-build && cpack -G DEB)
mkdir -p /tmp/rai-installed /out
packages=(/tmp/rai-build/*.deb)
[[ ${#packages[@]} -eq 1 && -s "${packages[0]}" ]] || {
  echo "Expected exactly one nonempty .deb package" >&2; exit 1
}
dpkg-deb --info "${packages[0]}"
dpkg-deb --contents "${packages[0]}" | grep -F 'usr/bin/remote-ai-astra'
dpkg-deb --contents "${packages[0]}" | grep -F 'usr/share/applications/remote-ai-astra.desktop'
dpkg-deb -x "${packages[0]}" /tmp/rai-installed
QT_QPA_PLATFORM=offscreen /tmp/rai-installed/usr/bin/remote-ai-astra --smoke
cp "${packages[0]}" /out/
(cd /out && sha256sum ./*.deb >SHA256SUMS.txt)
echo "PACKAGED $target: ${packages[0]}"
