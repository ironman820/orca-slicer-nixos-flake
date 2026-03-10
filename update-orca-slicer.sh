#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

release_channel=${ORCA_RELEASE_CHANNEL:-latest}

if [[ ! -f "flake.nix" ]]; then
  print_error "This script must be run from the orca-slicer-nixos-flake directory"
  exit 1
fi

for cmd in curl jq nix nix-prefetch-url; do
  if ! command -v "$cmd" >/dev/null; then
    print_error "$cmd is required"
    exit 1
  fi
done

print_info "Orca Slicer Package Flake Updater"
print_info "Fetching latest release metadata..."

json=$(curl -fsSL "https://api.github.com/repos/OrcaSlicer/OrcaSlicer/releases?per_page=10")
version_tag_filter='.tag_name | test("^v?[0-9]+\\.[0-9]+\\.[0-9]+([.-][A-Za-z0-9]+)*$")'

case "$release_channel" in
  latest)
    jq_filter="map(select((.draft | not) and (${version_tag_filter}))) | .[0]"
    ;;
  stable)
    jq_filter="map(select((.draft | not) and (.prerelease | not) and (${version_tag_filter}))) | .[0]"
    ;;
  *)
    print_error "Unsupported ORCA_RELEASE_CHANNEL: $release_channel"
    print_info "Supported values: latest, stable"
    exit 1
    ;;
esac

new_tag=$(echo "$json" | jq -r "$jq_filter | .tag_name")
release_url=$(echo "$json" | jq -r "$jq_filter | .html_url")
release_name=$(echo "$json" | jq -r "$jq_filter | .name")
release_type=$(echo "$json" | jq -r "$jq_filter | if .prerelease then \"pre-release\" else \"stable\" end")

if [[ -z "$new_tag" || "$new_tag" == "null" ]]; then
  print_error "Failed to parse GitHub releases response"
  print_info "Expected a version-like tag such as v2.3.2-rc2 or v2.3.1"
  exit 1
fi

new_version=${new_tag#v}
src_url="https://github.com/OrcaSlicer/OrcaSlicer/archive/refs/tags/${new_tag}.tar.gz"

current_version=$(grep -o 'version = "[^"]*";' flake.nix | head -1 | sed 's/version = "//;s/";//')
current_src_hash=$(grep -o 'srcHash = "[^"]*";' flake.nix | head -1 | sed 's/srcHash = "//;s/";//')

print_info "Current version: ${current_version:-unknown}"
print_info "Latest  version: $new_version"
print_info "Release type: $release_type"
print_info "Release name: $release_name"
print_info "Release URL: $release_url"

if [[ -n "${current_version:-}" && "$current_version" == "$new_version" ]]; then
  print_success "Package is already up-to-date"
  exit 0
fi

print_info "Prefetching source hash from ${src_url}..."
src_base32=$(nix-prefetch-url --unpack "$src_url")

if [[ -z "$src_base32" ]]; then
  print_error "Failed to compute source hash"
  exit 1
fi

if new_src_sri=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "$src_base32" 2>/dev/null); then
  :
else
  new_src_sri=$(nix hash to-sri --type sha256 "$src_base32")
fi

print_success "srcHash: $new_src_sri"

print_info "Updating flake.nix..."
sed -i "s|version = \"[^\"]*\";|version = \"$new_version\";|" flake.nix
sed -i "s|srcHash = \"[^\"]*\";|srcHash = \"$new_src_sri\";|" flake.nix

print_success "flake.nix updated"

if [[ "${ORCA_SKIP_BUILD:-0}" == "1" ]]; then
  print_warning "Skipping build verification because ORCA_SKIP_BUILD=1"
  exit 0
fi

print_info "Testing build..."
if nix build .#orca-slicer -L; then
  print_success "Build successful"
else
  print_error "Build failed"
  if [[ -n "${current_version:-}" ]]; then
    print_warning "Restoring previous version and hash"
    sed -i "s|version = \"[^\"]*\";|version = \"$current_version\";|" flake.nix
    sed -i "s|srcHash = \"[^\"]*\";|srcHash = \"$current_src_hash\";|" flake.nix
  fi
  exit 1
fi

print_success "Update complete"
