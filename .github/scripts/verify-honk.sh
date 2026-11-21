#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
shopt -s nullglob

btf_package=vmlinux-btf-builtin
if [[ "${WRT_HONK_BTF:-embedded}" == detached ]]; then
	btf_package=vmlinux-btf
fi

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
		board=$(sed -n 's/^CONFIG_TARGET_BOARD="\([^"]*\)"$/\1/p' .config)
		subtarget=$(sed -n 's/^CONFIG_TARGET_SUBTARGET="\([^"]*\)"$/\1/p' .config)
		kernel_version=$(awk -v target="$board/$subtarget" '
			$1 == "Target:" { selected = ($2 == target) }
			selected && $1 == "Linux-Version:" { print $2; exit }
		' tmp/.targetinfo)
		if [[ -z "$kernel_version" || $(printf '6.12\n%s\n' "$kernel_version" | sort -V | head -n1) != 6.12 ]]; then
			echo "Honk requires Linux 6.12 or later (selected: ${kernel_version:-unknown})." >&2
			exit 1
		fi
		require_config .config PACKAGE_honk PACKAGE_luci-app-honk "PACKAGE_$btf_package" \
			KERNEL_DEBUG_INFO KERNEL_CGROUP_BPF KERNEL_NET_NS
		if [[ "$btf_package" == vmlinux-btf-builtin ]]; then
			require_config .config KERNEL_DEBUG_INFO_BTF
		fi
		;;
	firmware)
		kernels=(build_dir/target-*/linux-*/linux-*/.config)
		manifests=(bin/targets/*/*/*.manifest)
		profiles=(bin/targets/*/*/profiles.json)
		if (( ${#kernels[@]} != 1 || ${#manifests[@]} == 0 || ${#profiles[@]} != 1 )); then
			echo 'Expected a built kernel, firmware manifests, and profiles.json for Honk.' >&2
			exit 1
		fi
		if ! jq -e '[.profiles[].images[]] | length > 0' "${profiles[0]}" > /dev/null; then
			echo 'Honk firmware build produced no device images.' >&2
			exit 1
		fi
		require_config "${kernels[0]}" BPF BPF_SYSCALL BPF_JIT CGROUP_BPF NET_SCHED \
			NET_CLS_ACT NET_XGRESS NET_NS
		if [[ "$btf_package" == vmlinux-btf ]]; then
			blobs=(build_dir/target-*/vmlinux-btf-*/vmlinux)
			if (( ${#blobs[@]} != 1 )) || [[ $(od -An -tx1 -N2 "${blobs[0]}" | tr -d ' \n') != 9feb ]]; then
				echo 'The generated detached kernel BTF is missing or invalid.' >&2
				exit 1
			fi
		else
			require_config "${kernels[0]}" DEBUG_INFO_BTF
			if ! readelf -SW "${kernels[0]%/.config}/vmlinux" | awk '$0 ~ /[[:space:]]\.BTF[[:space:]]/ { found = 1 } END { exit !found }'; then
				echo 'The built kernel is missing its .BTF section.' >&2
				exit 1
			fi
		fi
		for manifest in "${manifests[@]}"; do
			for package in honk luci-app-honk "$btf_package" kmod-nft-queue kmod-nfnetlink-queue; do
				if ! grep -q "^$package - " "$manifest"; then
					echo "Honk requires $package in $manifest" >&2
					exit 1
				fi
			done
		done
		;;
	*) exit 2 ;;
esac
