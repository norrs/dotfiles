# Dotfiles

Dark magic, this is parts I've bothered actually trying to archive as
dotfiles..

# Quick start

## Installation

### Clone the repository

This repository contains my personal collection of dotfiles for various shells and tools【683637299757771†L0-L7】. To get started, clone the repository and initialize its submodules:

```bash
git clone git://github.com/norrs/dotfiles.git
git submodule init
git submodule update
```

## Create symlinks

After cloning and updating submodules, run `make` from within the repository to create the necessary directories and symlinks in your home directory:

```bash
make
```

The `Makefile` defines targets to create directories (`mkdirs`), symlink files (`symlinks`) and directories (`symdirs`) and then ties everything together through the `install` target.



# Dependencies

Various packages are required for different pieces of this dotfiles collection. Use your system's package manager to install them.

## Core dependencies

Install the `policykit-1-gnome` and `autocutsel` packages for PolicyKit integration and clipboard support:

```bash
sudo apt-get install policykit-1-gnome autocutsel
```

## GObject introspection and related libraries

If you encounter errors related to `gobject-introspection-1.0`, install the following development tools and libraries:

```bash
sudo apt-get install gnome-common intltool valac libglib2.0-dev \
    gobject-introspection libgirepository1.0-dev libgtk-3-dev \
    libclutter-gtk-1.0-dev libgnome-desktop-3-dev libcanberra-dev \
    libgdata-dev libdbus-glib-1-dev libgstreamer1.0-dev \
    libupower-glib-dev fonts-droid gawk
```
This list comes from the troubleshooting notes in the original README【683637299757771†L16-L20】.

## Rofi and dmenu

For Rofi and dmenu menu support, install:

```bash
sudo apt install numix-icon-theme-circle rofi dmenu
```
There are also Haskell bindings available via the `libghc-gi-dbusmenu-dev` and `libghc-gi-dbusmenugtk3-dev` packages【683637299757771†L24-L26】.

## Outlook message conversion

To convert Outlook `.msg` files into `.eml` so they can be imported into Thunderbird, install the following Perl modules:

```bash
sudo apt install libemail-outlook-message-perl libemail-sender-perl
```
These utilities are mentioned in the original README to streamline working with email archives【683637299757771†L27-L29】.

## Miscellaneous notes

If you see an upstream bug reference (for example, the `gobject-introspection` bug report at https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=924440), check the associated bug for work‑arounds and updates【683637299757771†L31-L31】.


# Power Management

## Hibernate and suspend when closing the laptop lid

To configure how your system behaves when the laptop lid is closed, edit `/etc/systemd/logind.conf` and set the `HandleLidSwitch` directive. For example, to suspend on lid close:

```ini
HandleLidSwitch=suspend
```

Other values include `hibernate`, `ignore`, and `lock`. After editing, restart `systemd-logind` or reboot to apply changes.


# Tools and Utilities

This section highlights various tools and utilities referenced in the dotfiles.

## Chromix-too

Chromix‑too is a browser extension and accompanying CLI service for controlling Google Chrome from the command line. Install the extension from the Chrome Web Store and explore its GitHub repository:

- Extension: <https://chrome.google.com/webstore/detail/chromix-too/ppapdfccnamacakfkpfmpfnefpeajboj>
- Repository: <https://github.com/norrs/chromix-too>

These links are collected from the original README【683637299757771†L33-L37】.

## Clipboard management

Clipboard handling under X11 can be tricky. See the following resources for background information:

- <https://mutelight.org/subtleties-of-the-x-clipboard>
- <https://www.schaertl.me/posts/autocutsel-and-an-introduction-to-systemd-user-services/>

The recommended solution is to run `autocutsel` as a user unit so that selections are automatically copied between the primary and clipboard buffers【683637299757771†L38-L43】.

## pulseaudio-ctl

For controlling PulseAudio volume levels from the command line, use the `pulseaudio-ctl` utility:

<https://github.com/graysky2/pulseaudio-ctl>【683637299757771†L44-L47】.

## Firebase CLI

Install the Firebase CLI with a one‑liner:

```bash
curl -sL https://firebase.tools | bash
```

Further installation instructions are available in the Firebase CLI documentation【683637299757771†L48-L53】.

## Fonts

To refresh your font cache, run:

```bash
fc-cache -f -v
```

Font directories include `/usr/local/share/fonts` for system‑wide fonts, `~/.local/share/fonts` for user fonts, and `~/.fonts` for legacy user fonts. Font files should have 644 permissions (`-rw-r--r--`), otherwise they may not be usable【683637299757771†L54-L57】.

If you are working with bitmap fonts, reconfigure `fontconfig` using:

```bash
sudo dpkg-reconfigure fontconfig-config
```

Sometimes you may need to log out or reboot to fully refresh certain glyphs【683637299757771†L58-L62】.

## Deckmaster

Deckmaster is a command‑line tool for controlling Elgato Stream Deck devices. On Linux, you need to configure udev rules to allow access as a regular user. Create `/etc/udev/rules.d/99-streamdeck.rules` containing:

```udev
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck-mini"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE:="666", GROUP="plugdev", SYMLINK+="streamdeck-xl"
```

After creating these rules, make sure your user belongs to the `plugdev` group and reload the rules with:

```bash
sudo udevadm control --reload-rules
```

Then unplug and reconnect the Stream Deck. These instructions are extracted from the original README【683637299757771†L69-L81】. See the Deckmaster project for additional details: <https://github.com/muesli/deckmaster>【683637299757771†L84-L84】.

## notifications-tray-icon (rebuild with Nix)

The source is in `dot.opt/notifications-tray-icon`.

Rebuild and install the binary to `~/.local/bin` using Stack's Nix integration:

```bash
cd dot.opt/notifications-tray-icon
stack --nix --no-terminal install notifications-tray-icon --local-bin-path ~/.local/bin
```

If you need to force a Nix shell with build deps explicitly:

```bash
nix-shell -p gobject-introspection pkg-config gmp --run \
  'cd dot.opt/notifications-tray-icon && stack --no-terminal install notifications-tray-icon --local-bin-path ~/.local/bin'
```

After installing a new binary, restart and inspect the user service:

```bash
systemctl --user restart github-notifications.service
systemctl --user status github-notifications.service --no-pager
journalctl --user -u github-notifications.service -n 80 --no-pager
```

Task helper:

```bash
dot.tasks/recompile-notifications-tray-icon
```

## status-notifier-item (rebuild with Nix)

The source is in `dot.opt/status-notifier-item`.

Rebuild and install with Stack + Nix:

```bash
cd dot.opt/status-notifier-item
stack --nix --no-terminal install status-notifier-item --local-bin-path ~/.local/bin
```

After installing, restart and inspect the watcher service:

```bash
systemctl --user restart status-notifier-watcher.service
systemctl --user status status-notifier-watcher.service --no-pager
journalctl --user -u status-notifier-watcher.service -n 80 --no-pager
```

Task helper:

```bash
dot.tasks/recompile-status-notifier-item
```

# Inspiration

This dotfiles collection draws ideas from other people's configurations. You may find additional inspiration in the following repositories:

* <https://github.com/IvanMalison/dotfiles>
* <https://github.com/thcipriani/dotfiles>
* <https://github.com/addyosmani/dotfiles>
