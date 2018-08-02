#!/bin/bash
#export WINDOW_MANAGER=xmonad
export _JAVA_AWT_WM_NONREPARENTING=1

function source_directory_files {
	for filename in "$1"/*; do
		#environment_variable_exists SHELL_STARTUP_DEBUG && echo "Sourcing $filename"
               source "$filename"
	done
}

# Only way to load functions before systemd user units start? 
# Hm, need to research this later, as it is also in my .bashrc!
# -norangshol 2.aug.2018
source_directory_files "$HOME/.lib/shellenv"


[[ -f "$HOME/.pathrc" ]] && source $HOME/.pathrc
systemctl --user import-environment PATH
# Load resources
 
xrdb -merge ~/.Xresources

# Set up an icon tray
 
#status-notifier-watcher &
#trayer --edge top --align right --SetDockType true --SetPartialStrut true \
# --expand true --width 10 --transparent true --tint 0x191970 --height 18 &

GNOME_PK=/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 
[ -x $GNOME_PK ] && $GNOME_PK &
 
# Set the background color<

[ -x /usr/bin/dropbox ] && dropbox start -i &

status-notifier-watcher &
taffybar &

xsetroot -solid black
#feh --bg-scale $HOME/Pictures/wallpapers/current
#gconftool --type string --set /desktop/gnome/background/picture_filename "/path/to/your/image.png
 
# Fire up apps
 
#gajim &
 
#xscreensaver -no-splash &
#gnome-screensaver &
 

gnome-settings-daemon &

# Network manager
#if [ -x /usr/bin/nm-applet ] ; then
#   nm-applet --sm-disable &
#fi
# 
#if [ -x /usr/bin/gnome-power-manager ] ; then
#   sleep 3
#   gnome-power-manager &
#fi
#
#if [ -x /usr/bin/gsettings ]; then
#  gsettings set org.gnome.settings-daemon.plugins.xrandr active false
#fi
#
#if [[ $HOSTNAME == "luna" ]]
#then
#  xmodmap -e "keycode 36 = KP_Enter"
#  xmodmap -e "keycode 104 = Return"
#fi
#
# Fixes drawing of cursor in xmonad with gnome >=3.12
# https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1238047.html
if [ $(gsettings get org.gnome.settings-daemon.plugins.cursor active) = "true" ];then
  gsettings set org.gnome.settings-daemon.plugins.cursor active false
fi

# Export socket with Debian Sid (2014.10)
# until I move to systemd --user session start instead of this .xsession
# (currently /etc/X11/Xsession.d/90x11-common_ssh-agent seems to be the issue)
if [ -x /usr/bin/gnome-keyring-daemon ]; then
 /usr/bin/gnome-keyring-daemon -s
 SSH_AUTH_SOCKET=/run/user/$(id -u)/keyring/ssh
 [ -S $SSH_AUTH_SOCKET ] && export SSH_AUTH_SOCK=$SSH_AUTH_SOCKET
fi

exec xmonad
#exec ck-launch-session dbus-launch xmonad
#exec gnome-session --session=xmonad-gnome-nopanel "$@"
