# Git worktree commander

`git-wt` is a small two-pane terminal browser for the current repository's
registered worktrees. It uses Git and Python 3.9+ with the standard `curses`
module, available on macOS and Linux. Git must support
`worktree list --porcelain -z`.

The interface uses your terminal's default text and background colors, with
the selected worktree highlighted in reverse video.

Run directly from a terminal in any Git repository:

```bash
/path/to/dotfiles/dot.local/bin/git-wt
# Or browse another repository:
/path/to/dotfiles/dot.local/bin/git-wt /path/to/repository
```

The usual `make` installation adds `~/.local/bin/git-wt`; it can also be
installed alone with `make .local/bin/git-wt`. With `~/.local/bin` on `PATH`,
run `git-wt` or `git wt`.

The Bash helper `gwt` makes Enter change the calling shell's directory. It is
loaded with the other `dot.lib/shellrc` helpers by this repo's Bash setup. For
an existing shell, after installing:

```bash
source ~/.lib/shellrc/git-wt.bash
gwt
```

Without the helper, Enter opens a shell in the selected worktree. Exit that
shell to return to the browser. `o` always opens a shell. The helper passes
paths through a private temporary file using a NUL delimiter; spaces, shell
metacharacters and trailing newlines are supported without `eval`.

| Key | Action |
| --- | --- |
| Up/Down, j/k | Select worktree; Home/End and PgUp/PgDn also work |
| Enter | Open selected worktree; `gwt` changes the calling shell's directory |
| o | Open a subshell; `exit` returns to the browser |
| s / F3 | Show full short status |
| r / F2 | Refresh worktrees and dirty status |
| d / F8 | Remove a clean linked worktree, keeping its branch |
| R | Reset staged and unstaged changes with `git reset --hard HEAD` |
| n / N | Preview `git clean -n` / `git clean -nd` |
| c / C | Run `git clean -f` / `git clean -fd`, after preview and confirmation |
| p / P | Preview / execute `git worktree prune --verbose --expire now` |
| ? / h / F1 | Help |
| q / Esc / F10 | Quit; q/Esc/Enter closes previews |

The list shows paths, branches or detached HEADs, `*` for the worktree being
browsed from, dirty state (including untracked files and submodule changes),
missing paths, locks and prunable metadata. The right pane shows the full
selected path and HEAD. Press `r` to refresh after external changes.

The interface appears immediately, then loads the registered worktrees and
checks dirty status in the background. A spinner and worktree count show
progress; entries show `pending` until checked. Navigation and quitting remain
available during slow scans. Refresh cancels the previous scan, and quitting
stops its background Git processes.

Before reset, clean, removal or prune, the browser shows the exact command,
affected worktree or repository, and a scrollable preview. Type the displayed
uppercase word (`RESET`, `CLEAN`, `REMOVE`, or `PRUNE`) and Enter to confirm;
Esc cancels. Clean and prune use matching dry runs. The target is revalidated
after confirmation; changed previews require another review.

- Reset discards staged and unstaged tracked changes and may delete untracked
  paths obstructing tracked files. It explicitly disables submodule recursion.
- Clean keeps ignored files and nested Git repositories. Lowercase `c` removes
  files; uppercase `C` also removes untracked directories.
- Removal deletes the entire directory, including ignored files shown in its
  status preview. It never uses `--force`, unlocks worktrees or deletes branches.
  The main worktree, browsed-from worktree and directory containing the process's
  original working directory are protected from removal.
- Prune is repository-wide and expires stale metadata immediately. It deletes
  no worktree files or branches. Lock worktrees stored on removable/offline
  storage before pruning so their metadata is retained.

Git commands use argument arrays and validated worktree roots. Repository
targeting environment overrides such as `GIT_DIR`, `GIT_WORK_TREE` and
`GIT_INDEX_FILE` are ignored. Avoid editing files concurrently with a destructive
operation: previews cannot make Git commands atomic with external changes.

Run the safety integration tests (all mutations use temporary repositories):

```bash
python3 -m unittest discover -s tests -p 'test_git_wt*.py' -v
```
