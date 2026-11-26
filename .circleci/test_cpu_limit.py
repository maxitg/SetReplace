import contextlib
from fractions import Fraction
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import withCpuLimit

class CpuQuotaTests(unittest.TestCase):
  def setUp(self):
    temporary = tempfile.TemporaryDirectory()
    self.addCleanup(temporary.cleanup)
    self.root = Path(temporary.name)
    self.proc = self.root / "proc"
    self.proc.mkdir()

  def hierarchy(self, version=2, group="/", root="/", name="cpu group", controllers="cpu,cpuacct"):
    point = self.root / name
    point.mkdir()
    (self.proc / "cgroup").write_text("0::" + group if version == 2 else "3:" + controllers + ":" + group)
    escaped = str(point).replace(" ", r"\040")
    filesystem = "cgroup2 none rw" if version == 2 else "cgroup cgroup rw," + controllers
    (self.proc / "mountinfo").write_text("30 20 0:1 {} {} rw shared:1 - {}\n".format(root, escaped, filesystem))
    (point / Path(group).relative_to(root)).mkdir(parents=True, exist_ok=True)
    return point

  def v1Quota(self, directory, quota, period=100000):
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "cpu.cfs_quota_us").write_text(str(quota))
    (directory / "cpu.cfs_period_us").write_text(str(period))

  def testV2ContainerRoot(self):
    point = self.hierarchy()
    (point / "cpu.max").write_text("200000 100000\n")
    self.assertEqual(withCpuLimit.cpuQuota(self.proc), 2)

  def testV2TightestVisibleAncestor(self):
    point = self.hierarchy(group="/parent/job")
    (point / "cpu.max").write_text("max 100000")
    (point / "parent/cpu.max").write_text("150000 100000")
    (point / "parent/job/cpu.max").write_text("400000 100000")
    self.assertEqual(withCpuLimit.cpuQuota(self.proc), Fraction(3, 2))

  def testV2BindMountAndUnlimitedChild(self):
    point = self.hierarchy(group="/docker/job/child", root="/docker/job")
    (point / "cpu.max").write_text("50000 100000")
    (point / "child/cpu.max").write_text("max 100000")
    (self.root / "cpu.max").write_text("1000 100000")
    self.assertEqual(withCpuLimit.cpuQuota(self.proc), Fraction(1, 2))

  def testV1CombinedControllerMount(self):
    point = self.hierarchy(version=1, group="/docker/job", root="/docker")
    self.v1Quota(point, 200000)
    self.v1Quota(point / "job", -1)
    self.assertEqual(withCpuLimit.cpuQuota(self.proc), 2)

  def testV1ChildQuota(self):
    point = self.hierarchy(version=1, group="/job", controllers="cpu")
    self.v1Quota(point, -1)
    self.v1Quota(point / "job", 300000, 200000)
    self.assertEqual(withCpuLimit.cpuQuota(self.proc), Fraction(3, 2))

  def testNoCpuController(self):
    self.hierarchy(version=1, controllers="cpuacct")
    self.assertIsNone(withCpuLimit.cpuQuota(self.proc))

  def testMissingAndUnlimitedQuotas(self):
    point = self.hierarchy()
    self.assertIsNone(withCpuLimit.cpuQuota(self.proc))
    (point / "cpu.max").write_text("max 100000")
    self.assertIsNone(withCpuLimit.cpuQuota(self.proc))

  def testMalformedQuotaFails(self):
    point = self.hierarchy()
    for value in ["broken", "0 100000", "200000 0", "-1 100000"]:
      with self.subTest(value=value):
        (point / "cpu.max").write_text(value)
        with self.assertRaises(ValueError):
          withCpuLimit.cpuQuota(self.proc)

  def testMissingV1PeriodFails(self):
    point = self.hierarchy(version=1)
    (point / "cpu.cfs_quota_us").write_text("200000")
    with self.assertRaises(FileNotFoundError):
      withCpuLimit.cpuQuota(self.proc)

  def testUnrelatedMountIsNotUsed(self):
    point = self.hierarchy(group="/job")
    (point / "cpu.max").write_text("200000 100000")
    mountinfo = self.proc / "mountinfo"
    mountinfo.write_text(mountinfo.read_text().replace("0:1 / ", "0:1 /other "))
    with self.assertRaises(ValueError):
      withCpuLimit.cpuQuota(self.proc)

class AffinityTests(unittest.TestCase):
  def testSelectionNeverWidensAffinity(self):
    for quota, selected in [(Fraction(2), [3, 7]), (Fraction(5, 2), [3, 7]),
                            (Fraction(1, 2), [3]), (Fraction(8), [3, 7, 11]), (None, [3, 7, 11])]:
      with self.subTest(quota=quota), \
          patch.object(withCpuLimit, "cpuQuota", return_value=quota), \
          patch.object(os, "sched_getaffinity", return_value={3, 7, 11}, create=True), \
          patch.object(os, "sched_setaffinity", create=True) as setter, \
          contextlib.redirect_stdout(io.StringIO()):
        withCpuLimit.limitCpus()
        if len(selected) < 3:
          setter.assert_called_once_with(0, selected)
        else:
          setter.assert_not_called()

  def testDetectionFailureDoesNotRunCommand(self):
    with patch.object(sys, "argv", ["withCpuLimit.py", "command"]), \
        patch.object(withCpuLimit, "limitCpus", side_effect=ValueError("unreadable quota")), \
        patch.object(os, "execvp") as execute, contextlib.redirect_stderr(io.StringIO()):
      self.assertEqual(withCpuLimit.main(), 1)
      execute.assert_not_called()

  @unittest.skipUnless(hasattr(os, "sched_getaffinity"), "Linux affinity required")
  def testExecPreservesArgumentsEnvironmentAndStatus(self):
    wrapper = str(Path(withCpuLimit.__file__))
    code = "import os,sys; print(repr(sys.argv[1:])); print(os.getenv('CPU_LIMIT_TEST')); sys.exit(23)"
    result = subprocess.run([sys.executable, wrapper, sys.executable, "-c", code, "space here", "$(literal)"],
                            env=dict(os.environ, CPU_LIMIT_TEST="inherited"),
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    self.assertEqual(result.returncode, 23, result.stderr)
    self.assertIn("['space here', '$(literal)']", result.stdout)
    self.assertIn("inherited", result.stdout)

  @unittest.skipUnless(hasattr(os, "sched_getaffinity"), "Linux affinity required")
  def testChildInheritsExistingNarrowAffinity(self):
    cpu = max(os.sched_getaffinity(0))
    wrapper = str(Path(withCpuLimit.__file__))
    code = "import os; print(sorted(os.sched_getaffinity(0)))"
    result = subprocess.run([sys.executable, wrapper, sys.executable, "-c", code],
                            preexec_fn=lambda: os.sched_setaffinity(0, {cpu}),
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    self.assertEqual(result.returncode, 0, result.stderr)
    self.assertEqual(result.stdout.splitlines()[-1], str([cpu]))

if __name__ == "__main__":
  unittest.main()
