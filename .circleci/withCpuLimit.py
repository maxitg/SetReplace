#!/usr/bin/env python3

from fractions import Fraction
import os
from pathlib import Path
import random
import re
import sys

def unescapeMountPath(value):
  return re.sub(r"\\([0-7]{3})", lambda match: chr(int(match[1], 8)), value)

def cpuQuota(proc=Path("/proc/self")):
  """Find the tightest CPU bandwidth limit in the visible cgroup hierarchy."""
  groups = {}
  for line in (proc / "cgroup").read_text().splitlines():
    hierarchy, controllers, group = line.split(":", 2)
    if hierarchy == "0" and not controllers:
      groups["cgroup2"] = Path(group)
    elif "cpu" in controllers.split(","):
      groups["cgroup"] = Path(group)

  # On hybrid hosts, a controller belongs to either v1 or v2, never both.
  if "cgroup" in groups:
    groups.pop("cgroup2", None)

  limits = []
  matched = set()
  for line in (proc / "mountinfo").read_text().splitlines():
    mount, filesystem = line.split(" - ", 1)
    if filesystem.split(maxsplit=1)[0] not in groups:
      continue
    kind, _, options = filesystem.split()
    if kind == "cgroup" and "cpu" not in options.split(","):
      continue
    fields = mount.split()
    root, point = (Path(unescapeMountPath(value)) for value in fields[3:5])
    group = groups[kind]
    if ".." in group.parts:
      raise ValueError("CPU cgroup is outside the visible namespace")
    try:
      relative = group.relative_to(root)
    except ValueError:
      continue
    directory = point / relative
    if not directory.is_dir():
      continue
    matched.add(kind)
    while True:
      quotaFile = directory / ("cpu.max" if kind == "cgroup2" else "cpu.cfs_quota_us")
      try:
        value = quotaFile.read_text().strip()
      except FileNotFoundError:
        value = None  # The CPU controller need not be enabled at every level.
      if value is not None:
        if kind == "cgroup2":
          quota, period = value.split()
        else:
          quota, period = value, (directory / "cpu.cfs_period_us").read_text().strip()
        period = int(period)
        if period <= 0:
          raise ValueError("Invalid CPU period in " + str(directory))
        unlimited = quota == ("max" if kind == "cgroup2" else "-1")
        if not unlimited:
          quota = int(quota)
          if quota <= 0:
            raise ValueError("Invalid CPU quota in " + str(directory))
          limits.append(Fraction(quota, period))
      if directory == point:
        break
      directory = directory.parent

  if groups.keys() - matched:
    raise ValueError("Cannot locate the process's CPU cgroup mount")
  # Ancestors outside the container's mounted hierarchy cannot be inspected.
  return min(limits, default=None)

def limitCpus():
  allowed = sorted(os.sched_getaffinity(0))
  quota = cpuQuota()
  # Round down to avoid oversubscribing fractional quotas, but always allow one CPU.
  count = len(allowed) if quota is None else max(1, min(len(allowed), int(quota)))
  selected = allowed
  if count < len(allowed):
    # Avoid sending every co-located container to the same lowest-numbered CPUs.
    offset = random.SystemRandom().randrange(len(allowed))
    selected = sorted((allowed + allowed)[offset:offset + count])
    os.sched_setaffinity(0, selected)
  quotaText = "no finite visible limit" if quota is None else str(quota)
  print("CPU affinity: {} -> {} CPUs; cgroup CPU quota: {}; selected IDs: {}".format(
    len(allowed), len(selected), quotaText, ",".join(map(str, selected))), flush=True)

def main():
  if len(sys.argv) < 2:
    print("Usage: withCpuLimit.py COMMAND [ARGUMENTS...]", file=sys.stderr)
    return 2
  try:
    limitCpus()
  except (OSError, ValueError, AttributeError) as error:
    print("Cannot determine/apply the Linux CPU limit: " + str(error), file=sys.stderr)
    return 1
  # Replace this process so exit status and signals, as well as affinity, are preserved.
  try:
    os.execvp(sys.argv[1], sys.argv[1:])
  except OSError as error:
    print(str(error), file=sys.stderr)
    return 127 if isinstance(error, FileNotFoundError) else 126

if __name__ == "__main__":
  sys.exit(main())
