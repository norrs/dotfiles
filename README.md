This is my personal collection of dotfiles for various shells and tools.

To use it, you need to do the following:

    git clone git://github.com/norrs/dotfiles.git
    git submodule init
    git submodule update

Then you can create symlinks by running 'Make'


## List of apt dependencies

sudo apt-get install policykit-1-gnome


### error: gobject-introspection-1.0
sudo apt-get install gnome-common intltool valac libglib2.0-dev gobject-introspection libgirepository1.0-dev libgtk-3-dev libclutter-gtk-1.0-dev libgnome-desktop-3-dev libcanberra-dev libgdata-dev libdbus-glib-1-dev libgstreamer1.0-dev libupower-glib-dev fonts-droid gawk


rockj@pandora9k:~/dotfiles/dot.config/taffybar (master *>)$ apt install gir1.2-dbusmenu-gtk3-0.4 gir1.2-dbusmenu-gtk-0.4 gir1.2-dbusmenu-glib-0.4

apt install numix-icon-theme-circle rofi dmenu

libghc-gi-dbusmenu-dev
libghc-gi-dbusmenugtk3-dev

To convert outlook msg to eml. (drag eml into thunderbird to read)
apt install libemail-outlook-message-perl libemail-sender-perl


https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=924440

## Chromeix-too

https://chrome.google.com/webstore/detail/chromix-too/ppapdfccnamacakfkpfmpfnefpeajboj
https://github.com/norrs/chromix-too

## pulseaudio-ctl

https://github.com/graysky2/pulseaudio-ctl

## firebase

`curl -sL https://firebase.tools | bash`

https://firebase.google.com/docs/cli#install-cli-mac-linux

## Fonts


fc-cache updates from /usr/local/share/fonts (system-wide), ~/.local/share/fonts (user-specific) or ~/.fonts (user-specific). These files should have the permission 644 (-rw-r--r--), otherwise they may not be usable.

dpkg-reconfigure fontconfig-config  (if bitmap fonts)

(Not sure, but my gcloud glyph started working AFTER a reboot.. so missing something else then fc-cache to be run ..)

## Hibernate/sleep with laptop lid

Configure in /etc/systemd/logind.conf , see `HandleLidSwitch=suspend` and the others.

## deckmaster

On Linux you need to set up some udev rules to be able to access the device as a
regular user. Edit `/etc/udev/rules.d/99-streamdeck.rules` and add these lines:

```
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck-mini"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck-xl"
```

Make sure your user is part of the `plugdev` group and reload the rules with
`sudo udevadm control --reload-rules`. Unplug and replug the device and you
should be good to go.

See https://github.com/muesli/deckmaster
