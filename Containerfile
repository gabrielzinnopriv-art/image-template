# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image: Origami con driver NVIDIA e kernel CachyOS
FROM registry.gitlab.com/origami-linux/images/origami-nvidia:latest

# Fix per far funzionare bene i repo Fedora/COPR su immagini derivate
RUN sed -i 's/^ID=.*/ID=fedora/' /etc/os-release

# Copia Homebrew e abilita i servizi (utile per installare programmi extra in futuro)
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
    
### LINTING
RUN bootc container lint
