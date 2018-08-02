LN_FLAGS = -sf

mkdirs = .local/share/applications .config/gnome-session/sessions .urxvt .gnupg .caff/gnupghome
symlinks = .bashrc .pathrc .htoprc .Xdefaults .xsession .xmobarrc .screenrc .tmux.conf .local/share/applications/xmonad.desktop .config/gnome-session/sessions/xmonad-gnome-nopanel.session .skudd .gnupg/gpg.conf .gnupg/sks-keyservers.netCA.pem .caff/gnupghome/gnupg.conf
symdirs = .bash.d .xmonad .opt .local/share/urxvt-scripts .urxvt/ext .lib .config/rofi

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
