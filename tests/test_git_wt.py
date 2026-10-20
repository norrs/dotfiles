"""Safety integration tests for git-wt; all mutations use disposable repositories."""

import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "dot.local/bin/git-wt"
LOADER = importlib.machinery.SourceFileLoader("git_wt", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
git_wt = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = git_wt
LOADER.exec_module(git_wt)


class WorktreeParsingTests(unittest.TestCase):
    def test_nul_porcelain_preserves_unusual_paths_and_optional_fields(self):
        path = "/tmp/worktree with 'quotes'\ttab\nand newline"
        data = (
            b"worktree /tmp/main\0HEAD " + b"a" * 40
            + b"\0branch refs/heads/main\0\0worktree " + os.fsencode(path)
            + b"\0HEAD " + b"b" * 40
            + b"\0detached\0locked maintenance\0\0worktree /tmp/missing"
            + b"\0HEAD " + b"c" * 40
            + b"\0branch refs/heads/topic\0prunable gitdir file points to non-existent location\0\0"
        )
        records = git_wt.parse_worktrees(data)
        self.assertEqual(len(records), 3)
        self.assertEqual(records[0].branch, "main")
        self.assertEqual(records[1].path, path)
        self.assertFalse(records[1].branch)
        self.assertEqual(records[1].locked, "maintenance")
        self.assertIn("non-existent", records[2].prunable)

    def test_empty_locked_reason_is_distinct_from_unlocked(self):
        records = git_wt.parse_worktrees(
            b"worktree /tmp/main\0bare\0\0worktree /tmp/locked\0locked\0\0"
        )
        self.assertTrue(records[0].bare)
        self.assertIsNotNone(records[1].locked)


class GitEnvironmentTests(unittest.TestCase):
    def test_interactive_shell_preserves_locale_and_prompt_settings(self):
        settings = {
            "LC_ALL": "nb_NO.UTF-8",
            "LANG": "nb_NO.UTF-8",
            "GIT_TERMINAL_PROMPT": "1",
            "GIT_OPTIONAL_LOCKS": "1",
            "GIT_DIR": "/unwanted/repository",
            "GIT_CONFIG_PARAMETERS": "'core.worktree'='/unwanted/worktree'",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.worktree",
            "GIT_CONFIG_VALUE_0": "/unwanted/worktree",
        }
        with mock.patch.dict(os.environ, settings):
            environment = git_wt.git_environment(interactive=True)
        for key in ("LC_ALL", "LANG", "GIT_TERMINAL_PROMPT", "GIT_OPTIONAL_LOCKS"):
            self.assertEqual(environment[key], settings[key])
        for key in ("GIT_DIR", "GIT_CONFIG_PARAMETERS", "GIT_CONFIG_COUNT",
                    "GIT_CONFIG_KEY_0", "GIT_CONFIG_VALUE_0"):
            self.assertNotIn(key, environment)


@unittest.skipUnless(shutil.which("git"), "Git is required")
class WorktreeSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="git-wt-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.main = self.base / "main"
        self.other = self.base / "worktree 'quoted' with spaces"
        self.main.mkdir()
        self.git_env = {
            key: value for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        self.git_env.update({
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_TERMINAL_PROMPT": "0",
        })
        self.git(self.main, "init", "-q", "-b", "main")
        self.git(self.main, "config", "user.name", "git-wt tests")
        self.git(self.main, "config", "user.email", "git-wt@example.invalid")
        self.git(self.main, "config", "commit.gpgsign", "false")
        (self.main / "tracked.txt").write_text("committed\n")
        (self.main / ".gitignore").write_text("ignored/\n")
        self.git(self.main, "add", ".")
        self.git(self.main, "commit", "-qm", "initial")
        self.git(self.main, "worktree", "add", "-qb", "topic", str(self.other))
        self.repo = git_wt.Repo(str(self.main))

    def git(self, path, *args):
        result = subprocess.run(
            ["git", "-C", str(path), *args], env=self.git_env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        if result.returncode:
            self.fail(result.stderr.decode(errors="replace"))
        return result.stdout

    def selected(self, path=None, repo=None):
        expected = (path or self.other).resolve()
        for worktree in (repo or self.repo).worktrees():
            if Path(worktree.path).resolve() == expected:
                return worktree
        self.fail("Worktree missing from registered list: %s" % expected)

    def test_current_marker_from_nested_directory_and_symlink(self):
        nested = self.other / "nested"
        nested.mkdir()
        alias = self.base / "alias"
        alias.symlink_to(nested, target_is_directory=True)
        repo = git_wt.Repo(str(alias))
        current = self.selected(self.other, repo=repo)
        self.assertTrue(current.current)
        self.assertFalse(self.selected(self.main, repo=repo).current)
        with self.assertRaises(git_wt.Error):
            repo.plan(current, "remove")

    def test_cleaning_startup_subdirectory_keeps_repository_anchor_valid(self):
        startup = self.main / "untracked-startup-directory"
        startup.mkdir()
        (startup / "remove.txt").write_text("remove\n")
        repo = git_wt.Repo(str(startup))
        selected = self.selected(self.main, repo=repo)
        repo.execute(repo.plan(selected, "clean-dirs"), "CLEAN")
        self.assertFalse(startup.exists())
        self.assertEqual(len(repo.worktrees()), 2)
        self.assertTrue(self.selected(self.main, repo=repo).current)

    def test_main_worktree_cannot_be_removed_from_linked_worktree(self):
        repo = git_wt.Repo(str(self.other))
        with self.assertRaises(git_wt.Error):
            repo.plan(self.selected(self.main, repo=repo), "remove")
        self.assertTrue((self.main / "tracked.txt").exists())

    def test_newline_and_tab_paths_survive_discovery_and_targeting(self):
        unusual = self.base / "tab\tand newline\nincluding trailing\n"
        self.git(self.main, "worktree", "add", "-qb", "unusual", str(unusual))
        repo = git_wt.Repo(str(unusual))
        selected = self.selected(unusual, repo=repo)
        self.assertEqual(selected.path, str(unusual))
        self.assertTrue(selected.current)
        (unusual / "tracked.txt").write_text("discard\n")
        repo.execute(repo.plan(selected, "reset"), "RESET")
        self.assertEqual((unusual / "tracked.txt").read_text(), "committed\n")
        self.assertTrue(self.other.is_dir())

    def test_status_includes_tracked_and_untracked_changes(self):
        self.assertFalse(self.selected().dirty)
        (self.other / "tracked.txt").write_text("changed\n")
        self.assertTrue(self.selected().dirty)
        self.git(self.other, "checkout", "--", "tracked.txt")
        (self.other / "untracked.txt").write_text("untracked\n")
        self.assertTrue(self.selected().dirty)

    def test_wrong_confirmation_does_not_mutate(self):
        (self.other / "tracked.txt").write_text("keep this\n")
        action = self.repo.plan(self.selected(), "reset")
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "reset")
        self.assertEqual((self.other / "tracked.txt").read_text(), "keep this\n")

    def test_reset_affects_only_selected_worktree_and_preserves_branch(self):
        (self.main / "tracked.txt").write_text("keep main\n")
        (self.other / "tracked.txt").write_text("staged\n")
        self.git(self.other, "add", "tracked.txt")
        (self.other / "tracked.txt").write_text("unstaged\n")
        action = self.repo.plan(self.selected(), "reset")
        self.assertIn("reset", action.command)
        self.assertIn("--hard", action.command)
        self.repo.execute(action, "RESET")
        self.assertEqual((self.other / "tracked.txt").read_text(), "committed\n")
        self.assertEqual(self.git(self.other, "status", "--porcelain"), b"")
        self.assertEqual((self.main / "tracked.txt").read_text(), "keep main\n")
        self.assertEqual(self.git(self.other, "branch", "--show-current"), b"topic\n")

    def test_clean_file_preview_matches_scope_and_execution(self):
        (self.other / "loose.txt").write_text("remove\n")
        (self.other / "directory").mkdir()
        (self.other / "directory" / "keep.txt").write_text("keep\n")
        (self.other / "ignored").mkdir()
        (self.other / "ignored" / "keep.txt").write_text("keep\n")
        (self.main / "loose.txt").write_text("keep main\n")
        action = self.repo.plan(self.selected(), "clean")
        self.assertIn("loose.txt", action.preview)
        self.assertTrue((self.other / "loose.txt").exists())
        self.repo.execute(action, "CLEAN")
        self.assertFalse((self.other / "loose.txt").exists())
        self.assertTrue((self.other / "directory" / "keep.txt").exists())
        self.assertTrue((self.other / "ignored" / "keep.txt").exists())
        self.assertTrue((self.main / "loose.txt").exists())

    def test_clean_directories_preserves_ignored_and_nested_repositories(self):
        (self.other / "directory").mkdir()
        (self.other / "directory" / "remove.txt").write_text("remove\n")
        (self.other / "ignored").mkdir()
        (self.other / "ignored" / "keep.txt").write_text("keep\n")
        nested = self.other / "nested-repo"
        nested.mkdir()
        self.git(nested, "init", "-q")
        (nested / "keep.txt").write_text("keep\n")
        action = self.repo.plan(self.selected(), "clean-dirs")
        self.assertIn("directory", action.preview)
        self.repo.execute(action, "CLEAN")
        self.assertFalse((self.other / "directory").exists())
        self.assertTrue((self.other / "ignored" / "keep.txt").exists())
        self.assertTrue((nested / "keep.txt").exists())

    def test_changed_clean_preview_requires_fresh_confirmation(self):
        first = self.other / "first.txt"
        first.write_text("keep until reviewed again\n")
        action = self.repo.plan(self.selected(), "clean")
        second = self.other / "new-after-preview.txt"
        second.write_text("not included in confirmation\n")
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "CLEAN")
        self.assertTrue(first.exists())
        self.assertTrue(second.exists())

    def test_remove_retains_branch(self):
        action = self.repo.plan(self.selected(), "remove")
        self.assertNotIn("--force", action.command)
        self.assertNotIn("-f", action.command)
        self.repo.execute(action, "REMOVE")
        self.assertFalse(self.other.exists())
        self.assertEqual(self.git(self.main, "rev-parse", "refs/heads/topic"),
                         self.git(self.main, "rev-parse", "HEAD"))

    def test_dirty_worktree_removal_is_refused(self):
        (self.other / "tracked.txt").write_text("keep dirty work\n")
        with self.assertRaises(git_wt.Error):
            action = self.repo.plan(self.selected(), "remove")
            self.repo.execute(action, "REMOVE")
        self.assertEqual((self.other / "tracked.txt").read_text(), "keep dirty work\n")
        self.git(self.main, "rev-parse", "--verify", "refs/heads/topic")

    def test_locked_worktree_removal_is_refused(self):
        self.git(self.main, "worktree", "lock", "--reason", "keep locked", str(self.other))
        worktree = self.selected()
        self.assertIsNotNone(worktree.locked)
        with self.assertRaises(git_wt.Error):
            action = self.repo.plan(worktree, "remove")
            self.repo.execute(action, "REMOVE")
        self.assertTrue(self.other.is_dir())

    def test_missing_worktree_prune_removes_metadata_and_preserves_branch(self):
        shutil.rmtree(self.other)
        missing = self.selected()
        self.assertIsNotNone(missing.prunable)
        action = self.repo.plan(None, "prune")
        self.assertTrue(action.preview)
        self.repo.execute(action, "PRUNE")
        self.assertEqual(len(self.repo.worktrees()), 1)
        self.assertTrue((self.main / "tracked.txt").exists())
        self.git(self.main, "rev-parse", "--verify", "refs/heads/topic")

    def test_prune_retains_locked_missing_worktree(self):
        self.git(self.main, "worktree", "lock", "--reason", "offline volume", str(self.other))
        shutil.rmtree(self.other)
        self.repo.execute(self.repo.plan(None, "prune"), "PRUNE")
        missing = self.selected()
        self.assertEqual(missing.locked, "offline volume")
        self.assertEqual(len(self.repo.worktrees()), 2)
        self.git(self.main, "rev-parse", "--verify", "refs/heads/topic")

    def test_replaced_source_repository_blocks_prune(self):
        action = self.repo.plan(None, "prune")
        original_git_directory = self.base / "original-git-directory"
        (self.main / ".git").rename(original_git_directory)
        self.git(self.main, "init", "-q")
        with self.assertRaises(git_wt.Error):
            self.repo.plan(None, "prune")
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "PRUNE")
        self.assertTrue(original_git_directory.is_dir())
        self.assertTrue((self.main / ".git").is_dir())

    def test_replaced_checkout_is_rejected_before_destructive_plan(self):
        worktree = self.selected()
        (self.other / ".git").unlink()
        self.git(self.other, "init", "-q")
        for kind in ("reset", "clean", "clean-dirs", "remove"):
            with self.subTest(kind=kind), self.assertRaises(git_wt.Error):
                self.repo.plan(worktree, kind)
        self.assertEqual((self.other / "tracked.txt").read_text(), "committed\n")

    def test_replaced_checkout_is_rejected_after_confirmation_preview(self):
        (self.other / "tracked.txt").write_text("keep foreign checkout\n")
        action = self.repo.plan(self.selected(), "reset")
        (self.other / ".git").unlink()
        self.git(self.other, "init", "-q")
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "RESET")
        self.assertEqual((self.other / "tracked.txt").read_text(), "keep foreign checkout\n")

    def test_missing_git_file_cannot_fall_back_to_parent_repository(self):
        nested = self.main / "nested-worktree"
        self.git(self.main, "worktree", "add", "-qb", "nested", str(nested))
        action = self.repo.plan(self.selected(nested), "clean-dirs")
        (self.main / "keep-untracked-directory").mkdir()
        (self.main / "keep-untracked-directory" / "keep.txt").write_text("keep\n")
        (nested / ".git").unlink()
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "CLEAN")
        self.assertTrue((self.main / "keep-untracked-directory" / "keep.txt").exists())
        with self.assertRaises(git_wt.Error):
            self.repo.plan(self.selected(nested), "reset")

    def test_changed_head_requires_refresh_before_reset(self):
        action = self.repo.plan(self.selected(), "reset")
        (self.other / "tracked.txt").write_text("new commit\n")
        self.git(self.other, "add", "tracked.txt")
        self.git(self.other, "commit", "-qm", "advance selected branch")
        (self.other / "tracked.txt").write_text("keep unreviewed change\n")
        with self.assertRaises(git_wt.Error):
            self.repo.execute(action, "RESET")
        self.assertEqual((self.other / "tracked.txt").read_text(), "keep unreviewed change\n")

    def test_inherited_git_targeting_variables_cannot_redirect_reset(self):
        (self.main / "tracked.txt").write_text("keep main\n")
        (self.other / "tracked.txt").write_text("discard other\n")
        poisoned = {
            "GIT_DIR": str(self.main / ".git"),
            "GIT_WORK_TREE": str(self.main),
            "GIT_INDEX_FILE": str(self.main / ".git" / "index"),
            "GIT_COMMON_DIR": str(self.main / ".git"),
        }
        with mock.patch.dict(os.environ, poisoned):
            try:
                repo = git_wt.Repo(str(self.other))
                action = repo.plan(self.selected(repo=repo), "reset")
                repo.execute(action, "RESET")
            except git_wt.Error:
                pass  # Explicitly refusing a poisoned environment is safe too.
        self.assertEqual((self.main / "tracked.txt").read_text(), "keep main\n")

    def test_counted_git_config_cannot_redirect_reset(self):
        (self.main / "tracked.txt").write_text("keep main\n")
        (self.other / "tracked.txt").write_text("discard other\n")
        poisoned = {
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.worktree",
            "GIT_CONFIG_VALUE_0": str(self.main),
        }
        with mock.patch.dict(os.environ, poisoned):
            repo = git_wt.Repo(str(self.other))
            selected = self.selected(repo=repo)
            self.assertTrue(selected.current)
            repo.execute(repo.plan(selected, "reset"), "RESET")
        self.assertEqual((self.main / "tracked.txt").read_text(), "keep main\n")
        self.assertEqual((self.other / "tracked.txt").read_text(), "committed\n")


if __name__ == "__main__":
    unittest.main()
