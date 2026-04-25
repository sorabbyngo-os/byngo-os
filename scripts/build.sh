#!/usr/bin/env bash
# Byngo OS — Image Builder
# Assembles consumer OS image from Sorabbyngo kernel + rootfs overlay
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'
info()    { echo -e "${CYAN}[byngo-os]${NC} $*"; }
success() { echo -e "${GREEN}[byngo-os]${NC} $*"; }
warn()    { echo -e "${YELLOW}[byngo-os]${NC} $*"; }

KERNEL_SRC="${KERNEL_SRC:-$HOME/sorabbyngo-os}"
DEFCONFIG="sorabbyngo_consumer_defconfig"
OUTPUT="${OUTPUT:-$HOME/byngo-os/build}"

echo -e "${BOLD}"
cat << 'BANNER'
  ╔══════════════════════════════════════╗
  ║   Byngo OS — Consumer Image Builder  ║
  ║   Voice-first · Android-compat       ║
  ╚══════════════════════════════════════╝
BANNER
echo -e "${NC}"

# 1. Verify kernel source
if [[ ! -d "$KERNEL_SRC" ]]; then
    warn "Kernel source not found at $KERNEL_SRC"
    warn "Set KERNEL_SRC env var to point to sorabbyngo-os checkout"
    exit 1
fi

# 2. Apply consumer defconfig
info "Applying consumer defconfig..."
cp defconfig/$DEFCONFIG "$KERNEL_SRC/arch/arm64/configs/"
make -C "$KERNEL_SRC" $DEFCONFIG
success "Defconfig applied"

# 3. Build kernel
info "Building kernel (this takes a while)..."
make -C "$KERNEL_SRC" -j$(nproc) Image.gz dtbs modules
success "Kernel built"

# 4. Overlay rootfs
info "Overlaying Byngo OS rootfs..."
mkdir -p "$OUTPUT"
cp -r rootfs/* "$OUTPUT/"
success "Rootfs overlay applied"

# 5. Install systemd units
info "Installing systemd units..."
cp rootfs/etc/systemd/system/*.service "$OUTPUT/etc/systemd/system/"
cp rootfs/etc/systemd/system/*.target  "$OUTPUT/etc/systemd/system/"
systemctl --root="$OUTPUT" enable chameha-voice.service
systemctl --root="$OUTPUT" enable byngox-consumer.service
systemctl --root="$OUTPUT" enable sorabbyngo-identity.service
success "Systemd units installed"

info "Byngo OS image ready at $OUTPUT"
echo ""
echo "  Flash to device:  dd if=$OUTPUT/byngo-os.img of=/dev/sdX bs=4M"
echo "  Emulate (QEMU):   qemu-system-aarch64 -kernel $OUTPUT/Image.gz -M virt"
