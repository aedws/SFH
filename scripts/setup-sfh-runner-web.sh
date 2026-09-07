#!/usr/bin/env bash
# Explicit administrator bootstrap, not a CI step. Dedicated Ubuntu WSL only.
# Official packages: learn.microsoft.com/powershell/scripting/install/install-ubuntu
# Official Node binaries and checksums: nodejs.org/dist
set -euo pipefail
test "$(id -u)" = 0
. /etc/os-release
test "$ID:$VERSION_ID" = ubuntu:24.04
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates python3-venv python3-yaml gh xz-utils
task_dir=$(mktemp -d /tmp/sfh-web-bootstrap.XXXXXX)
trap 'rm -r -- "$task_dir"' EXIT
curl --fail --location --retry 3 https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o "$task_dir/microsoft.deb"
dpkg -i "$task_dir/microsoft.deb"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
node_version=24.13.0
node_archive="node-v$node_version-linux-x64.tar.xz"
curl --fail --location --retry 3 "https://nodejs.org/dist/v$node_version/$node_archive" -o "$task_dir/$node_archive"
curl --fail --location --retry 3 "https://nodejs.org/dist/v$node_version/SHASUMS256.txt" -o "$task_dir/SHASUMS256.txt"
(cd "$task_dir"; grep "  $node_archive$" SHASUMS256.txt | sha256sum --check --strict)
install -d /opt/sfh-ci
tar -xJf "$task_dir/$node_archive" -C /opt/sfh-ci
for program in node npm npx; do
  link="/usr/local/bin/$program"
  # Do not replace another application's runtime on future installations.
  if [ -e "$link" ] && [[ "$(readlink "$link")" != /opt/sfh-ci/node-* ]]; then
    echo "Unmanaged runtime at $link; refusing overwrite" >&2
    exit 1
  fi
  ln -sfn "/opt/sfh-ci/node-v$node_version-linux-x64/bin/$program" "$link"
done
node --version
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
python3 --version
echo SFH_RUNNER_WEB_PREREQUISITES_OK
