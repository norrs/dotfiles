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
