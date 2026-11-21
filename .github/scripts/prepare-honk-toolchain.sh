#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

case "$(sed -n 's/^CONFIG_ARCH="\(.*\)"$/\1/p' .config)" in
	aarch64) rust_target=aarch64-unknown-linux-musl ;;
	x86_64) rust_target=x86_64-unknown-linux-musl ;;
	*) echo 'Honk requires an aarch64 or x86_64 target.' >&2; exit 1 ;;
esac

source_dir=package/daeuniverse-honk/honk/src
stable=$(sed -n 's/^channel = "\([^"]*\)"$/\1/p' "$source_dir/rust-toolchain.toml")
nightly=$(sed -n 's/^channel = "\([^"]*\)"$/\1/p' "$source_dir/crates/honk-ebpf/rust-toolchain.toml")
rustup toolchain install "$stable" --profile minimal --target "$rust_target" --component rustfmt,clippy
rustup toolchain install "$nightly" --profile minimal --component rust-src,llvm-tools

source "$source_dir/.github/ci/pins.env"
linker_dir=$(mktemp -d "${RUNNER_TEMP:-/tmp}/honk-bpf-linker.XXXXXXXX")
linker_archive="$linker_dir/bpf-linker.tar.zst"
curl -fsSL --retry 3 -o "$linker_archive" \
	"https://github.com/aya-rs/bpf-linker/releases/download/v${BPF_LINKER_VERSION}/bpf-linker-x86_64-unknown-linux-musl.tar.zst"
printf '%s  %s\n' "$BPF_LINKER_SHA256" "$linker_archive" | sha256sum -c -
tar --zstd -xf "$linker_archive" -C "$linker_dir" bpf-linker
"$linker_dir/bpf-linker" --version
printf '%s\n' "$linker_dir" >> "$GITHUB_PATH"
