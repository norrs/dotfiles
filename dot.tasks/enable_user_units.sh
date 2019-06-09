#!/usr/bin/env sh
set -e
enable_git_sync () {
	[ -e "$1" ] || git clone $2 $1
	unit_name=$(systemd-escape -p "$1" --template git-sync@.service)
	echo $unit_name
	cd $1
	git config --bool branch.master.sync true
	git config --bool branch.master.syncNewFiles true
	git branch --set-upstream-to=origin/master
	systemctl --user enable "$unit_name"
	systemctl --user restart "$unit_name"
}

cd "$HOME/.config/systemd/user/"
find -L * -type f | grep -v git-sync | grep -v wants | grep -E "\.service$" | xargs -I unitname sh -x -c 'echo unitname && systemctl --user enable unitname'
#
enable_git_sync "$HOME/notes" git@gitlab.com:norrs/notes.git
#enable_git_sync "$HOME/config" git@bitbucket.org:ivanmalison/config.git
#enable_git_sync "$HOME/.password-store" git@bitbucket.org:ivanmalison/pass.git
