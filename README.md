This is my personal collection of dotfiles for various shells and tools.

To use it, you need to do the following:

    git clone git://github.com/norrs/dotfiles.git
    git submodule init
    git submodule update

Then you can create symlinks by running 'Make'


## List of apt dependencies


### error: gobject-introspection-1.0
sudo apt-get install gnome-common intltool valac libglib2.0-dev gobject-introspection libgirepository1.0-dev libgtk-3-dev libclutter-gtk-1.0-dev libgnome-desktop-3-dev libcanberra-dev libgdata-dev libdbus-glib-1-dev libgstreamer1.0-dev libupower-glib-dev fonts-droid


rockj@pandora9k:~/dotfiles/dot.config/taffybar (master *>)$ apt install gir1.2-dbusmenu-gtk3-0.4 gir1.2-dbusmenu-gtk-0.4 gir1.2-dbusmenu-glib-0.4


libghc-gi-dbusmenu-dev
libghc-gi-dbusmenugtk3-dev


https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=924440



## Fonts


fc-cache updates from /usr/local/share/fonts (system-wide), ~/.local/share/fonts (user-specific) or ~/.fonts (user-specific). These files should have the permission 644 (-rw-r--r--), otherwise they may not be usable.

dpkg-reconfigure fontconfig-config  (if bitmap fonts)
