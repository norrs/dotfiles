# gwt: browse worktrees and change this shell's directory on Enter.
gwt() {
    local gwt_file gwt_path gwt_status
    gwt_file=$(mktemp "${TMPDIR:-/tmp}/git-wt.XXXXXXXX") || return 1
    command git-wt --cd-file "$gwt_file" "$@"
    gwt_status=$?
    if [ "$gwt_status" -eq 0 ] && IFS= read -r -d '' gwt_path < "$gwt_file"; then
        cd -- "$gwt_path" || gwt_status=$?
    fi
    rm -f -- "$gwt_file"
    return "$gwt_status"
}
