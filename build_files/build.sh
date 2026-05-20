#!/bin/bash
set -ouex pipefail

# ============================================
# I tuoi pacchetti extra
# Origami ha già: Kernel CachyOS, Driver NVIDIA, Cosmic Desktop, bat, eza, ripgrep...
# ============================================
dnf5 install -y \
    vim \
    htop \
    fastfetch \
    btop \
    tmux \
    fish \
    git \
    neofetch

# ============================================
# Servizi
# ============================================
systemctl enable podman.socket
