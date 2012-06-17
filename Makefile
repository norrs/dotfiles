LN_FLAGS = -sf

symlinks = .bashrc .pathrc .htoprc .Xdefaults .xsession .screenrc 
symdirs = .xmonad

.PHONY: $(symlinks) $(symdirs)

all: install

clean:
	rm -rf -- dot.vim/bundle/*

$(symlinks):
	ln $(LN_FLAGS) $(PWD)/dot$@ ~/$@

$(symdirs):
	rm -f ~/$@
	ln $(LN_FLAGS) $(PWD)/dot$@/ ~/$@

install: $(symlinks) $(symdirs) 
