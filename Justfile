export image_name := env("IMAGE_NAME", "foxyos") # output image name, usually same as repo name, change as needed
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file"
        just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file"
        just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        else
            sudo "$@"
        fi
    }
    sudoif {{ command }} {{ args }}

# Check if command exists
[group('Utility')]
[private]
check-cmd cmd:
    #!/usr/bin/bash
    if ! command -v {{ cmd }} &> /dev/null; then
        echo "ERROR: {{ cmd }} is not installed"
        exit 1
    fi

# Build Image
[group('Build')]
build:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd podman
    just check-cmd cosign
    
    # Build the image
    podman build -t {{ image_name }}:{{ default_tag }} .

# Push Image to Registry
[group('Build')]
push tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd podman
    just check-cmd cosign
    
    # Push the image
    podman push localhost/{{ image_name }}:{{ tag }} docker://ghcr.io/{{ env_var_or_default("GITHUB_REPOSITORY_OWNER", image_name) }}/{{ image_name }}:{{ tag }}

# Build and Push
[group('Build')]
build-and-push tag=default_tag: (build) (push tag)

# Sign Image
[group('Build')]
sign tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd cosign
    
    # Sign the image
    cosign sign --yes --key cosign.key ghcr.io/{{ env_var_or_default("GITHUB_REPOSITORY_OWNER", image_name) }}/{{ image_name }}:{{ tag }}

# Build ISO
[group('Build')]
build-iso:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd podman
    just check-cmd genisoimage
    
    # Build the ISO
    podman run --rm -it -v ./_build:/output -v ./disk_config:/config {{ bib_image }} --type iso --config /config/iso.toml

# Build QCOW2
[group('Build')]
build-qcow2:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd podman
    
    # Build the QCOW2
    podman run --rm -it -v ./_build:/output -v ./disk_config:/config {{ bib_image }} --type qcow2 --config /config/qcow2.toml

# Rebuild QCOW2
[group('Build')]
rebuild-qcow2: (clean) (build-qcow2)

# Run VM QCOW2
[group('Utility')]
run-vm-qcow2:
    #!/usr/bin/bash
    set -eoux pipefail
    just check-cmd qemu-system-x86_64
    
    # Run the VM
    qemu-system-x86_64 -m 2048 -smp 2 -drive file=./_build/disk.qcow2,format=qcow2 -enable-kvm -net nic -net user
