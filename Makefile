LN_FLAGS = -sf

mkdirs = .local/share/applications .config/gnome-session/sessions .urxvt
symlinks = .bashrc .pathrc .htoprc .Xdefaults .xsession .xmobarrc .screenrc .tmux.conf .local/share/applications/xmonad.desktop .config/gnome-session/sessions/xmonad-gnome-nopanel.session .skudd 
symdirs = .xmonad .local/share/urxvt-scripts .urxvt/ext

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
