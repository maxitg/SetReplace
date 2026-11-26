#!/usr/bin/env bash
set -eo pipefail

uname -a
printf 'Available CPUs: '
nproc
printf 'All CPUs: '
nproc --all
sed -n '/^Cpus_allowed_list:/p' /proc/self/status

# Support both cgroup v2 and the older Docker cgroup v1 layout.
for path in \
  /sys/fs/cgroup/cpu.max \
  /sys/fs/cgroup/cpu.stat \
  /sys/fs/cgroup/memory.max \
  /sys/fs/cgroup/cpu/cpu.cfs_quota_us \
  /sys/fs/cgroup/cpu/cpu.cfs_period_us \
  /sys/fs/cgroup/memory/memory.limit_in_bytes; do
  if [[ -r "$path" ]]; then
    printf '%s: ' "$path"
    cat "$path"
  fi
done
