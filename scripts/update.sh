#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

current=$(grep 'version = "' flake.nix | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
latest=$(curl -s https://api.github.com/repos/moonrepo/moon/releases/latest | jq -r .tag_name | sed 's/^v//')

echo "Current: $current"
echo "Latest:  $latest"

if [ "$current" = "$latest" ]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating $current -> $latest"

targets=(
  "x86_64-unknown-linux-gnu:x86_64-linux"
  "aarch64-unknown-linux-gnu:aarch64-linux"
  "aarch64-apple-darwin:aarch64-darwin"
)

for entry in "${targets[@]}"; do
  target="${entry%%:*}"
  key="${entry##*:}"
  url="https://github.com/moonrepo/moon/releases/download/v${latest}/moon_cli-${target}.tar.xz"
  sha=$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url "$url" 2>/dev/null)")
  echo "$key: $sha"
  sed -i -E "/${key}.*sha256/s|sha256 = \"[^\"]+\"|sha256 = \"${sha}\"|" flake.nix
done

src_sha=$(nix-prefetch-url --unpack "https://github.com/moonrepo/moon/archive/refs/tags/v${latest}.tar.gz" 2>/dev/null)
echo "source: $src_sha"
sed -i -E "/^[[:space:]]+sha256 = \"[a-z0-9]{52}\";/s/sha256 = \"[^\"]+\"/sha256 = \"${src_sha}\"/" flake.nix

sed -i -E "s/(version = \")[^\"]+/\1${latest}/" flake.nix

echo "Updated flake.nix to v${latest}"
