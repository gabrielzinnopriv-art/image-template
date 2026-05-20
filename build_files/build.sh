#!/bin/bash

set -ouex pipefail

## DNF5 Speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

## RPM Fusion (Codec e software proprietari)
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

## App di sistema e utente base (Rimosso neofetch, non esiste su Fedora 44)
dnf5 -y install nautilus kitty mpv gnome-terminal gnome-system-monitor wlr-randr htop fastfetch btop tmux fish git flatpak-builder || true

## Install Niri 
dnf5 -y install niri 

## Install Dank Linux shell (DMS) e dipendenze
curl --output-dir "/etc/yum.repos.d/" \
  --remote-name "https://copr.fedorainfracloud.org/coprs/avengemedia/dms/repo/fedora-$(rpm -E %fedora)/avengemedia-dms-fedora-$(rpm -E %fedora).repo"
dnf5 -y install quickshell dms greetd dms-greeter --allowerasing 

## Configura greetd (Login manager con DMS)
mkdir -p /etc/greetd/
cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1
[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service

## Abilita DMS per i nuovi utenti e copia config Niri (inclusa cartella dms)
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service /etc/skel/.config/systemd/user/graphical-session.target.wants/
mkdir -p /etc/skel/.config/niri/
cp -rf /ctx/dot_config/niri/* /etc/skel/.config/niri/

## Abilita podman
systemctl enable podman.socket

## Disabilita tips di Origami
mv /etc/profile.d/origami-aliases.sh /etc/profile.d/origami-aliases.sh.bak || true

## Rimuovi COSMIC shell e waybar (pulizia)
dnf5 -y remove cosmic-comp cosmic-initial-setup cosmic-settings cosmic-settings-daemon cosmic-store waybar || true

## CLEAN UP
# Pulisci la cache per ridurre le dimensioni dell'immagine finale
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
