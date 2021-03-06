LN_FLAGS = -sf

mkdirs = .local/share/applications \
	 .local/share/rofi \
	 .local/bin \
	 .local/etc/unit \
	 .config/gnome-session/sessions \
	 .config/systemd/user \
	 .urxvt \
	 .gnupg \
	 .caff/gnupghome

symlinks = .bashrc \
	   .gitconfig \
	   .gitconfig-zedge \
	   .gitconfig-unit \
	   .config/gtk-3.0/settings.ini \
	   .config/systemd/user/wm.target \
	   .config/systemd/user/chromix-too.service \
	   .config/systemd/user/chromix-too-norangshol.service \
	   .config/systemd/user/git-sync@.service \
	   .config/systemd/user/git-sync-powersavehelper.service \
	   .config/systemd/user/git-sync-yubikeyhelper.service \
	   .config/systemd/user/github-notifications.service \
	   .config/systemd/user/nm-applet.service \
	   .config/systemd/user/notification-daemon.service \
	   .config/systemd/user/status-notifier-watcher.service \
	   .config/systemd/user/taffybar.service \
	   .config/systemd/user/wallpaper.service \
	   .config/systemd/user/wallpaper.timer \
	   .local/bin/change-gcloud \
	   .local/bin/change-keyboard \
	   .local/bin/clickhouse-client \
	   .local/bin/test-rofi \
	   .local/bin/rofi-systemd \
	   .local/bin/wallpaper \
	   .local/bin/git_sync_directory \
	   .local/bin/git-sync-powersavehelper \
	   .local/bin/git-sync \
	   .local/bin/kcd \
	   .local/bin/kubernetes-add-service-account-kubeconfig \
	   .local/bin/chromix-too-norangshol \
	   .local/bin/split_current_chrome_tab \
	   .local/bin/split_current_chrome_tab_norangshol \
	   .local/bin/split_tab_by_id \
	   .local/bin/focus_tab_by_id \
	   .local/bin/focus_tab_by_id_norangshol \
	   .local/bin/vault \
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
	   .gnupg/gpg-agent.conf \
	   .gnupg/sshcontrol \
	   .gnupg/dirmngr.conf \
	   .gnupg/sks-keyservers.netCA.pem \
	   .gnupg/lets-encrypt-x3-cross-signed.pem \
	   .caff/gnupghome/gnupg.conf
symdirs = .bash.d \
	.xmonad \
	.opt \
	.config/autorandr \
	.local/share/urxvt-scripts \
	.local/share/rofi/themes \
	.local/share/fonts \
	.local/etc/unit/wireless \
	.urxvt/ext \
	.lib \
	.config/rofi \
	.config/taffybar

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
