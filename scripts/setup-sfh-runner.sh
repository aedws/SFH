#!/usr/bin/env bash
# Run as root inside the dedicated Ubuntu-24.04 WSL distribution.
# Registration uses a short-lived token supplied separately, never saved here.
set -euo pipefail
test "$(id -u)" = 0
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io curl ca-certificates jq git libicu74
systemctl enable --now docker
if ! id sfh-runner >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /home/sfh-runner --shell /bin/bash sfh-runner
fi
usermod -aG docker sfh-runner
install -d -o sfh-runner -g sfh-runner /home/sfh-runner/actions-runner
version=2.337.0
archive=/tmp/actions-runner-linux-x64-$version.tar.gz
curl --fail --location --retry 3 "https://github.com/actions/runner/releases/download/v$version/actions-runner-linux-x64-$version.tar.gz" -o "$archive"
echo "70920811a4f8ad4328818682bca5c6469c1c942fab52448868071d0063816613  $archive" | sha256sum --check
if [ ! -e /home/sfh-runner/actions-runner/.runner ]; then
  tar -xzf "$archive" -C /home/sfh-runner/actions-runner
  chown -R sfh-runner:sfh-runner /home/sfh-runner/actions-runner
fi
docker pull barichello/godot-ci:4.7.2
echo SFH_RUNNER_PREREQUISITES_OK
