"""Regression tests for responsive loading and cancellable worktree scans."""

import dataclasses
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import queue
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock

if os.name == "posix":
    import fcntl
    import pty
    import select
    import struct
    import termios


SCRIPT = Path(__file__).resolve().parents[1] / "dot.local/bin/git-wt"
LOADER = importlib.machinery.SourceFileLoader("git_wt_loading", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
git_wt = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = git_wt
LOADER.exec_module(git_wt)


class SlowRepo:
    def __init__(self):
        self.trees = [git_wt.Worktree("/tmp/first-worktree", branch="first")]
        self.started = threading.Event()
        self.release = threading.Event()
        self.cancelled = threading.Event()

    def worktrees(self, check_status=True, cancel=None):
        if check_status:
            raise AssertionError("Loading the worktree list must skip dirty checks")
        return self.trees

    def inspect(self, wt, cancel=None):
        self.started.set()
        while not self.release.wait(0.01):
            if cancel.is_set():
                self.cancelled.set()
                raise git_wt.Cancelled("Scan cancelled")
        return dataclasses.replace(wt, dirty=False)


class WorktreeScanTests(unittest.TestCase):
    def test_list_is_published_while_status_is_still_blocked(self):
        repo = SlowRepo()
        scan = git_wt.WorktreeScan(repo)
        self.addCleanup(scan.close)
        self.addCleanup(repo.release.set)

        kind, trees = scan.updates.get(timeout=3)
        self.assertEqual(kind, "list")
        self.assertEqual(trees, repo.trees)
        self.assertTrue(repo.started.wait(3), "Status inspection never started")
        self.assertIsNone(trees[0].dirty)

        repo.release.set()
        updates = []
        while True:
            update = scan.updates.get(timeout=3)
            updates.append(update)
            if update[0] == "done":
                break
        checked = [payload for kind, payload in updates if kind == "status"]
        self.assertEqual(len(checked), 1)
        self.assertFalse(checked[0].dirty)
        self.assertIsNone(trees[0].dirty, "The worker must not mutate a displayed row")
        progress = [payload for kind, payload in updates if kind == "progress"]
        self.assertTrue(progress, "Loading progress must identify the worktree")
        self.assertEqual(progress[0][1:], (1, repo.trees[0].path))

    def test_close_cancels_an_in_progress_status_check(self):
        repo = SlowRepo()
        scan = git_wt.WorktreeScan(repo)
        self.addCleanup(scan.close)
        self.addCleanup(repo.release.set)
        self.assertTrue(repo.started.wait(3), "Status inspection never started")

        scan.close()

        self.assertTrue(scan.cancel.is_set())
        self.assertTrue(repo.cancelled.wait(1), "Closing must interrupt the status check")

    def test_discovery_failure_is_reported_and_finishes_the_scan(self):
        class BrokenRepo:
            def worktrees(self, check_status=True, cancel=None):
                raise git_wt.Error("Cannot list registered worktrees")

        scan = git_wt.WorktreeScan(BrokenRepo())
        self.addCleanup(scan.close)
        self.assertEqual(scan.updates.get(timeout=3),
                         ("error", "Cannot list registered worktrees"))
        self.assertEqual(scan.updates.get(timeout=3), ("done", None))


class SelectedWorktreeTests(unittest.TestCase):
    def make_repo(self):
        selected = git_wt.Worktree("/tmp/git-wt-selected", branch="selected", head="a" * 40)
        other = git_wt.Worktree("/tmp/git-wt-unrelated", branch="unrelated", head="b" * 40)
        repo = git_wt.Repo.__new__(git_wt.Repo)
        repo.cwd = "/tmp/git-wt-launch-directory"
        repo.check_repository = mock.Mock()
        repo.check_identity = mock.Mock()
        repo.worktrees = mock.Mock(return_value=[selected, other])

        def inspect(wt, cancel=None):
            if wt.path == other.path:
                raise AssertionError("An action must not wait for an unrelated worktree")
            return dataclasses.replace(wt, dirty=False)

        repo.inspect = mock.Mock(side_effect=inspect)
        return repo, selected

    def test_navigation_validation_does_not_scan_dirty_status(self):
        repo, selected = self.make_repo()
        self.assertEqual(repo.validate(selected).path, selected.path)
        repo.worktrees.assert_called_once_with(check_status=False)
        repo.inspect.assert_not_called()

    def test_removal_validation_scans_only_its_selected_worktree(self):
        repo, selected = self.make_repo()
        self.assertFalse(repo.validate(selected, removal=True).dirty)
        repo.worktrees.assert_called_once_with(check_status=False)
        repo.inspect.assert_called_once_with(selected)

    def test_drawing_state_uses_cached_path_existence(self):
        with mock.patch.object(git_wt.os.path, "isdir", side_effect=AssertionError("UI path probe")):
            missing = git_wt.Worktree("/tmp/offline-worktree", missing=True)
            pending = git_wt.Worktree("/tmp/checking-worktree", missing=None)
            checked = git_wt.Worktree("/tmp/checked-worktree", missing=False, dirty=False)
            self.assertIn("missing", missing.state)
            self.assertIn("pending", pending.state)
            self.assertIn("clean", checked.state)


class BrowserScanLifecycleTests(unittest.TestCase):
    def browser_without_terminal(self, repo):
        browser = git_wt.Browser.__new__(git_wt.Browser)
        browser.repo = repo
        browser.scan = None
        browser.scans = []
        browser.trees = []
        browser.index = 0
        return browser

    def test_refresh_ignores_updates_from_a_retired_scan(self):
        browser = self.browser_without_terminal(object())
        old = mock.Mock()
        old.updates = queue.Queue()
        current = mock.Mock()
        current.updates = queue.Queue()
        pending = git_wt.Worktree("/tmp/refreshed-worktree", dirty=None)
        current.updates.put(("list", [pending]))
        old.updates.put(("status", dataclasses.replace(pending, dirty=True)))
        old.updates.put(("done", None))
        browser.scan = old
        browser.scans = [old]

        with mock.patch.object(git_wt, "WorktreeScan", return_value=current):
            browser.refresh()
        browser.poll_scan()

        old.close.assert_called_once_with(wait=False)
        self.assertEqual(browser.trees, [pending])
        self.assertIsNone(browser.trees[0].dirty)
        self.assertTrue(browser.loading, "A retired completion must not finish the new scan")
        self.assertEqual(old.updates.qsize(), 2)

    def test_quit_waits_for_current_and_retired_workers_to_stop(self):
        class ClosingRepo(SlowRepo):
            def inspect(self, wt, cancel=None):
                self.started.set()
                cancel.wait(5)
                self.cancelled.set()
                self.release.wait(5)
                raise git_wt.Cancelled("Scan cancelled")

        old_repo, new_repo = ClosingRepo(), ClosingRepo()
        browser = self.browser_without_terminal(old_repo)

        def cleanup_scans():
            old_repo.release.set()
            new_repo.release.set()
            for scan in browser.scans:
                scan.close()

        self.addCleanup(cleanup_scans)
        finished = threading.Event()
        browser.refresh()
        self.assertTrue(old_repo.started.wait(3))
        browser.repo = new_repo
        browser.refresh()
        self.assertTrue(old_repo.cancelled.wait(3))
        self.assertTrue(new_repo.started.wait(3))
        scans = list(browser.scans)
        self.assertEqual(len(scans), 2, "Refresh must retain a worker still stopping")
        browser.browse = lambda: None

        def quit_browser():
            try:
                browser.run()
            finally:
                finished.set()

        quitter = threading.Thread(target=quit_browser, daemon=True)
        try:
            quitter.start()
            self.assertTrue(new_repo.cancelled.wait(0.5))
            self.assertFalse(finished.is_set(), "Quit returned while workers were still stopping")
            old_repo.release.set()
            new_repo.release.set()
            self.assertTrue(finished.wait(3))
            self.assertTrue(all(not scan.thread.is_alive() for scan in scans))
        finally:
            old_repo.release.set()
            new_repo.release.set()
            for scan in scans:
                scan.close()
            quitter.join(3)


@unittest.skipUnless(os.name == "posix", "Process groups require POSIX")
class GitCancellationTests(unittest.TestCase):
    def test_cancel_stops_git_and_its_child_process(self):
        with tempfile.TemporaryDirectory(prefix="git-wt-cancel-") as temporary:
            base = Path(temporary)
            ready = base / "ready"
            lock = base / "child.lock"
            parent_pid = base / "parent.pid"
            child_pid = base / "child.pid"
            child_code = "\n".join([
                "import fcntl, os, pathlib, sys, time",
                "lock = open(sys.argv[1], 'w')",
                "fcntl.flock(lock, fcntl.LOCK_EX)",
                "pathlib.Path(sys.argv[2]).write_text(str(os.getpid()))",
                "pathlib.Path(sys.argv[3]).touch()",
                "time.sleep(60)",
            ])
            parent_code = "\n".join([
                "import os, pathlib, subprocess, sys, time",
                "pathlib.Path(sys.argv[1]).write_text(str(os.getpid()))",
                "subprocess.Popen([sys.executable, '-c', sys.argv[2], *sys.argv[3:]])",
                "time.sleep(60)",
            ])
            repo = git_wt.Repo.__new__(git_wt.Repo)
            command = [sys.executable, "-c", parent_code, str(parent_pid), child_code,
                       str(lock), str(child_pid), str(ready)]
            repo.command = lambda *args, path=None: command
            cancel = threading.Event()
            outcome = queue.Queue()

            def run_command():
                try:
                    outcome.put(repo.run("status", cancel=cancel))
                except Exception as exc:
                    outcome.put(exc)

            worker = threading.Thread(target=run_command, daemon=True)
            worker.start()
            try:
                deadline = time.monotonic() + 5
                while not ready.exists() and time.monotonic() < deadline:
                    if not outcome.empty():
                        self.fail("Command stopped before starting its child: %r" % outcome.get())
                    cancel.wait(0.01)
                self.assertTrue(ready.exists(), "The simulated Git child never became ready")
                cancel.set()
                result = outcome.get(timeout=5)
                self.assertIsInstance(result, git_wt.Cancelled)
                worker.join(1)
                self.assertFalse(worker.is_alive())
                # Locks are released even by an unreaped process, avoiding a flaky
                # PID-existence check while proving the child stopped running.
                with lock.open("a") as descriptor:
                    fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
            finally:
                cancel.set()
                for marker in (child_pid, parent_pid):
                    if marker.exists():
                        try:
                            os.kill(int(marker.read_text()), signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                worker.join(2)


@unittest.skipUnless(os.name == "posix", "A real terminal requires POSIX pty support")
class BrowserLoadingTests(unittest.TestCase):
    def test_slow_status_keeps_list_visible_and_accepts_navigation_and_quit(self):
        # The fake status check cannot finish before cancellation. Seeing both
        # branches therefore proves the list was drawn independently of status.
        child_code = "\n".join([
            "import curses, dataclasses, importlib.machinery, importlib.util, sys",
            "loader = importlib.machinery.SourceFileLoader('git_wt_pty', %r)" % str(SCRIPT),
            "spec = importlib.util.spec_from_loader(loader.name, loader)",
            "module = importlib.util.module_from_spec(spec)",
            "sys.modules[spec.name] = module",
            "loader.exec_module(module)",
            "class SlowRepo:",
            "    anchor = '/tmp/git-wt-loading-test'",
            "    def worktrees(self, check_status=True, cancel=None):",
            "        assert not check_status",
            "        return [module.Worktree('/tmp/first-loading-worktree', branch='first-loading-branch', current=True),",
            "                module.Worktree('/tmp/second-loading-worktree', branch='second-loading-branch')]",
            "    def inspect(self, wt, cancel=None):",
            "        cancel.wait(30)",
            "        raise module.Cancelled('Scan cancelled')",
            "def run(screen):",
            "    browser = module.Browser(screen, SlowRepo())",
            "    browser.run()",
            "    return browser.index",
            "index = curses.wrapper(run)",
            "print('FINAL_INDEX=' + str(index), flush=True)",
        ])
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        environment = os.environ.copy()
        environment["TERM"] = "xterm-256color"
        output = bytearray()
        process = subprocess.Popen([sys.executable, "-c", child_code], stdin=slave,
                                   stdout=slave, stderr=slave, env=environment,
                                   close_fds=True)
        os.close(slave)

        def pump_until(predicate, timeout):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if predicate():
                    return True
                readable, _, _ = select.select([master], [], [], 0.05)
                if readable:
                    try:
                        data = os.read(master, 65536)
                    except OSError:
                        data = b""
                    if data:
                        output.extend(data)
                    elif process.poll() is not None:
                        return predicate()
                elif process.poll() is not None:
                    return predicate()
            return predicate()

        try:
            visible_list = lambda: (b"first-loading-branch" in output
                                    and b"second-loading-branch" in output)
            self.assertTrue(pump_until(visible_list, 5),
                            "Slow status hid the worktree list: %r" % bytes(output))
            self.assertIsNone(process.poll(), "Status was supposed to remain pending")
            self.assertIn(b"checking status", bytes(output).lower(),
                             "Pending status must have a visible loading indicator")
            os.write(master, b"jq")
            self.assertTrue(pump_until(lambda: b"FINAL_INDEX=1" in output, 5),
                            "Navigation/quit blocked behind status: %r" % bytes(output))
            self.assertTrue(pump_until(lambda: process.poll() is not None, 3),
                            "Browser did not exit after cancelling its scan")
            self.assertEqual(process.returncode, 0, bytes(output))
        finally:
            if process.poll() is None:
                process.kill()
                pump_until(lambda: process.poll() is not None, 3)
            os.close(master)
            process.wait(timeout=3)


if __name__ == "__main__":
    unittest.main()
