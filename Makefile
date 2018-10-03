LN_FLAGS = -sf

mkdirs = .local/share/applications \
	 .config/gnome-session/sessions \
	 .urxvt \
	 .gnupg \
	 .caff/gnupghome

symlinks = .bashrc \
	   .config/systemd/user/wm.target \
	   .config/systemd/user/git-sync@.service \
	   .config/systemd/user/github-notifications.service \
	   .config/systemd/user/nm-applet.service \
	   .config/systemd/user/notification-daemon.service \
	   .config/systemd/user/status-notifier-watcher.service \
	   .config/systemd/user/taffybar.service \
	   .config/systemd/user/wallpaper.service \
	   .config/systemd/user/wallpaper.timer \
	   .local/bin/test-rofi \
	   .local/bin/rofi-systemd \
	   .local/bin/wallpaper \
	   .local/bin/git_sync_directory \
	   .local/bin/git-sync \
	   .pathrc \
	   .htoprc \
	   .Xdefaults \
	   .xsession \
	   .xmobarrc \
	   .screenrc \
	   .tmux.conf \
	   .local/share/applications/xmonad.desktop \
	   .config/gnome-session/sessions/xmonad-gnome-nopanel.session \
	   .skudd \
	   .gnupg/gpg.conf \
	   .gnupg/sks-keyservers.netCA.pem \
	   .caff/gnupghome/gnupg.conf
symdirs = .bash.d \
	.xmonad \
	.opt \
	.local/share/urxvt-scripts \
	.local/share/rofi/themes \
	.urxvt/ext \
	.lib \
	.config/rofi

.PHONY: $(mkdirs) $(symlinks) $(symdirs)

all: install

clean:
	rm -rf -- dot.vim/bundle/*

$(mkdirs):
	[ -d ~/$@ ] || mkdir -p ~/$@

$(symlinks):
	ln $(LN_FLAGS) $(PWD)/dot$@ ~/$@

$(symdirs):
	rm -f ~/$@
	ln $(LN_FLAGS) $(PWD)/dot$@/ ~/$@

install: $(mkdirs) $(symlinks) $(symdirs) 
