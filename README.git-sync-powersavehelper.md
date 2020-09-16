# How to configure systemd to react on udev events from power_supply

Source: http://www.linuxembedded.fr/2018/03/kernel-udev-et-systemd-la-gestion-du-hotplug/


udevadm monitor

Check for events and most likley find something like:

udevadm info -a /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:19/PNP0C09:00/ACPI0003:00/power_supply/AC

Create udev rule:

cat /etc/udev/rules.d/40-stop-git-sync.rules 
SUBSYSTEM=="power_supply" DRIVERS=="ac" TAG+="systemd" ENV{SYSTEMD_ALIAS}+="/sys/subsystem/power_supply/main_AC"


systemctl daemon-reload

systemctl list-units --type=device

It should list the new aliased systemd device:

systemctl status sys-subsystem-power_supply-main_AC.device


See blog for details.

## Configuration for the yubikey as well

cat /etc/udev/rules.d/40-stop-git-sync-yubikey.rules 

SUBSYSTEM=="usb" ACTION=="add" ATTR{idVendor}=="1050" ATTR{manufacturer}=="Yubico" TAG+="systemd" ENV{SYSTEMD_ALIAS}+="/sys/subsystem/usb/yubikey"
#ACTION=="add", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="1050", ENV{ID_MODEL_ID}=="0407", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/sys/subsystem/usb/yubikey
ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="1050/407/*", TAG+="systemd"

#SUBSYSTEM=="usb" ACTION=="remove" ATTR{idVendor}=="1050" ATTR{manufacturer}=="Yubico" TAG+="systemd"

