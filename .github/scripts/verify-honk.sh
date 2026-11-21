#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
shopt -s nullglob

require_config() {
	local file=$1 symbol
	shift
	for symbol in "$@"; do
		if ! grep -Fxq "CONFIG_${symbol}=y" "$file"; then
			echo "Honk requires CONFIG_${symbol}=y in $file" >&2
			exit 1
		fi
	done
}

case "${1:-}" in
	config)
		case "$(sed -n 's/^CONFIG_ARCH="\(.*\)"$/\1/p' .config)" in
			aarch64|x86_64) ;;
			*) echo 'Honk requires an aarch64 or x86_64 target.' >&2; exit 1 ;;
		esac
		require_config .config PACKAGE_honk PACKAGE_luci-app-honk PACKAGE_vmlinux-btf-builtin \
			KERNEL_DEBUG_INFO_BTF KERNEL_CGROUP_BPF KERNEL_NET_NS
		;;
	firmware)
		kernels=(build_dir/target-*/linux-*/linux-*/.config)
		manifests=(bin/targets/*/*/*.manifest)
		if (( ${#kernels[@]} != 1 || ${#manifests[@]} == 0 )); then
			echo 'Expected one built kernel and at least one firmware manifest for Honk.' >&2
			exit 1
		fi
		require_config "${kernels[0]}" BPF BPF_SYSCALL BPF_JIT CGROUP_BPF NET_SCHED \
			NET_CLS_ACT NET_XGRESS NET_NS DEBUG_INFO_BTF
		for manifest in "${manifests[@]}"; do
			for package in honk luci-app-honk vmlinux-btf-builtin kmod-nft-queue kmod-nfnetlink-queue; do
				if ! grep -q "^$package - " "$manifest"; then
					echo "Honk requires $package in $manifest" >&2
					exit 1
				fi
			done
		done
		;;
	*) exit 2 ;;
esac
