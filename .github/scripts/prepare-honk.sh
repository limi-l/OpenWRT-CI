#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

feed_commit=8c6ed9bd00a99d7662cfd5bf15fb4eed393ce689
honk_commit=64848881b7304e250e7a25422f4f1d86a5975eca # v0.1.0-beta.6
package_dir=package/daeuniverse-honk
feed_dir=$(mktemp -d)
trap 'rm -rf -- "$feed_dir"' EXIT

git init -q "$feed_dir"
git -C "$feed_dir" fetch --depth=1 https://github.com/daeuniverse/openwrt-packages.git "$feed_commit"
mkdir -p "$package_dir"
packages=(honk luci-app-honk luci-lib-daeuniverse)
if [[ "${WRT_HONK_BTF:-embedded}" != detached ]]; then
	packages+=(vmlinux-btf-builtin)
fi
git -C "$feed_dir" archive FETCH_HEAD "${packages[@]}" | tar -x -C "$package_dir"

script_dir=$(dirname "$0")
patch --batch --forward --fuzz=0 -d "$package_dir/honk" -p1 < "$script_dir/honk-default-dns.patch"
install -m 644 "$script_dir/honk-dns.uci-defaults" "$package_dir/honk/files/honk-dns.uci-defaults"

if [[ "${WRT_HONK_BTF:-embedded}" == detached ]]; then
	# Generate BTF from this build's vmlinux and keep it out of the boot partition.
	install -D -m 644 "$script_dir/vmlinux-btf.mk" "$package_dir/vmlinux-btf/Makefile"
else
	# Match the dependency to the provider when the kernel exports its own BTF.
	sed -i 's/+vmlinux-btf /+vmlinux-btf-builtin /' "$package_dir/honk/Makefile"
fi

source_dir="$package_dir/honk/src"
git init -q "$source_dir"
git -C "$source_dir" fetch --depth=1 https://github.com/daeuniverse/honk.git "$honk_commit"
git -C "$source_dir" checkout --quiet --detach FETCH_HEAD
