#!/usr/bin/env bash
# Build a RAM-boot-only debug boot image for Lenovo TB322FC (elden).
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../../../.." && pwd)
WORK=${WORK:-"$HOME/gen4-build"}
OUT="$SCRIPT_DIR/out"

UMBRELLA_URL=https://github.com/h0cheung/tb322fc-linux
UMBRELLA_SHA=234c49c274024ae53fd8ffca597954242dcd2b95
KERNEL_URL=https://github.com/h0cheung/tb322fc-linux-kernel.git
KERNEL_SHA=6f97250ead155fc3b980856323e99a4623dae73d
KERNEL_TREE=12bc91648dd3e0f9425152cea8ed010502efec51
BUSYBOX_URL=https://busybox.net/downloads/busybox-1.36.1.tar.bz2
BUSYBOX_SHA=b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314
# AOSP mkbootimg. Distro packages import gki/ without shipping it, so the
# script downloads these two files itself and runs them with python3.
MKBOOTIMG_COMMIT=d2bb0af5ba6d3198a3e99529c97eda1be0b5a093
MKBOOTIMG_URL=https://android.googlesource.com/platform/system/tools/mkbootimg
MKBOOTIMG_PY_SHA=37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c
GKI_CERT_SHA=1bb1feec68a13da18d581aa2c631798f86f6bc10b55d587b2dd31446a0f8a203

# Applets the debug init and the interactive shell need. Already present in
# the umbrella busybox.config; forced on so a config drift cannot drop them.
BUSYBOX_APPLETS=(
  SETSID LN MKDIR LS CAT ECHO SLEEP DMESG MOUNT HEAD UNAME PS STTY
)

START_EPOCH=$(date +%s)
mkdir -p "$WORK/tmp"
export TMPDIR="$WORK/tmp"

case "$WORK" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "WORK ($WORK) is inside the git repo; refusing to fetch sources there." >&2
    exit 1
    ;;
esac

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 1
  }
}

for program in python3 make cc curl tar git sha256sum base64 \
  aarch64-linux-gnu-gcc aarch64-linux-gnu-readelf \
  clang ld.lld llvm-ar llvm-nm llvm-objcopy \
  zstd pahole flex bison bc; do
  need "$program"
done

# googlesource ?format=TEXT is base64. Decode and require the pinned sha256.
fetch_googlesource_file() {
  local url=$1 dest=$2 sha=$3
  if [[ -f "$dest" ]] && echo "$sha  $dest" | sha256sum -c --status -; then
    echo "reuse $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  curl --fail --location --silent --show-error "${url}?format=TEXT" \
    | base64 -d >"$dest.part"
  mv "$dest.part" "$dest"
  echo "$sha  $dest" | sha256sum -c -
}

ensure_commit() {
  local dir=$1 url=$2 sha=$3
  local head=""
  if [[ -d "$dir/.git" ]]; then
    head=$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)
  fi
  if [[ "$head" == "$sha" ]]; then
    echo "reuse $dir @ $sha"
    return 0
  fi
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init
  git -C "$dir" remote add origin "$url"
  git -C "$dir" fetch --depth 1 origin "$sha"
  git -C "$dir" checkout --detach FETCH_HEAD
  head=$(git -C "$dir" rev-parse HEAD)
  if [[ "$head" != "$sha" ]]; then
    echo "checkout of $url landed on $head, expected $sha" >&2
    exit 1
  fi
}

force_busybox_opt() {
  local cfg=$1 opt=$2
  local key="CONFIG_${opt}"
  if grep -qx "${key}=y" "$cfg"; then
    echo "busybox ${key}=y already"
    return 0
  fi
  echo "busybox forcing ${key}=y"
  if grep -q "^# ${key} is not set\$" "$cfg"; then
    sed -i "s/^# ${key} is not set\$/${key}=y/" "$cfg"
  elif grep -q "^${key}=" "$cfg"; then
    sed -i "s/^${key}=.*/${key}=y/" "$cfg"
  else
    printf '%s=y\n' "$key" >>"$cfg"
  fi
}

# List newc cpio names and confirm they match initramfs.list, with no firmware
# and with /init identical to the committed init.
verify_cpio() {
  local cpio_path=$1
  python3 - "$cpio_path" "$SCRIPT_DIR/initramfs.list" "$SCRIPT_DIR/init" <<'PY'
import gzip
import pathlib
import sys

cpio_path, list_path, init_path = sys.argv[1:]
blob = pathlib.Path(cpio_path).read_bytes()
if blob[:2] == b"\x1f\x8b":
    blob = gzip.decompress(blob)

def parse(data: bytes):
    entries = []
    off = 0
    while off + 110 <= len(data):
        if data[off:off + 6] != b"070701":
            break
        def field(at: int) -> int:
            return int(data[off + at:off + at + 8], 16)
        filesize = field(54)
        namesize = field(94)
        name_start = off + 110
        raw_name = data[name_start:name_start + namesize].split(b"\0", 1)[0]
        name = raw_name.decode()
        name_end = (name_start + namesize + 3) & ~3
        payload = data[name_end:name_end + filesize]
        entries.append((name, payload))
        if name == "TRAILER!!!":
            break
        off = (name_end + filesize + 3) & ~3
    return entries

entries = parse(blob)
names = []
payloads = {}
for name, payload in entries:
    if name in ("TRAILER!!!", ""):
        continue
    norm = name[1:] if name.startswith("/") else name
    names.append(norm)
    payloads[norm] = payload

expected = []
for line in pathlib.Path(list_path).read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    kind, path, *_rest = line.split()
    if kind not in {"dir", "file", "slink", "nod"}:
        sys.exit(f"unknown initramfs.list entry: {line}")
    norm = path[1:] if path.startswith("/") else path
    expected.append(norm)

if names != expected:
    print("cpio entries:", names, file=sys.stderr)
    print("list entries:", expected, file=sys.stderr)
    sys.exit(f"{cpio_path}: entries do not match initramfs.list")

for name in names:
    if "firmware" in name or name.endswith(".bin") and name != "bin/busybox":
        sys.exit(f"{cpio_path}: firmware-like path {name}")

init_bytes = pathlib.Path(init_path).read_bytes()
if payloads.get("init") != init_bytes:
    sys.exit(f"{cpio_path}: /init does not match {init_path}")
# gen_init_cpio stores the symlink target with a trailing NUL.
link = payloads.get("bin/sh", b"").split(b"\0", 1)[0]
if link != b"/bin/busybox":
    sys.exit(f"{cpio_path}: /bin/sh symlink target is {payloads.get('bin/sh')!r}")
print(f"cpio ok: {cpio_path} ({len(names)} entries)")
PY
}

echo "=== fetch pinned sources ==="
fetch_googlesource_file \
  "$MKBOOTIMG_URL/+/$MKBOOTIMG_COMMIT/mkbootimg.py" \
  "$WORK/mkbootimg/mkbootimg.py" \
  "$MKBOOTIMG_PY_SHA"
fetch_googlesource_file \
  "$MKBOOTIMG_URL/+/$MKBOOTIMG_COMMIT/gki/generate_gki_certificate.py" \
  "$WORK/mkbootimg/gki/generate_gki_certificate.py" \
  "$GKI_CERT_SHA"
ensure_commit "$WORK/kernel" "$KERNEL_URL" "$KERNEL_SHA"
ensure_commit "$WORK/umbrella" "$UMBRELLA_URL" "$UMBRELLA_SHA"
actual_tree=$(git -C "$WORK/kernel" write-tree)
if [[ "$actual_tree" != "$KERNEL_TREE" ]]; then
  echo "kernel write-tree $actual_tree != $KERNEL_TREE" >&2
  exit 1
fi
echo "kernel write-tree $actual_tree"

for rel in configs/kernel.config configs/busybox.config configs/cmdline.txt; do
  if [[ ! -f "$WORK/umbrella/$rel" ]]; then
    echo "umbrella is missing $rel" >&2
    exit 1
  fi
done

echo "=== busybox ==="
archive="$WORK/busybox-1.36.1.tar.bz2"
if [[ ! -f "$archive" ]]; then
  curl --fail --location --output "$archive.part" "$BUSYBOX_URL"
  mv "$archive.part" "$archive"
fi
echo "$BUSYBOX_SHA  $archive" | sha256sum -c -
if [[ ! -f "$WORK/sources/busybox/Makefile" ]]; then
  mkdir -p "$WORK/sources/busybox"
  tar -xf "$archive" -C "$WORK/sources/busybox" --strip-components=1
fi
mkdir -p "$WORK/build/busybox"
cp "$WORK/umbrella/configs/busybox.config" "$WORK/build/busybox/.config"
for opt in "${BUSYBOX_APPLETS[@]}"; do
  force_busybox_opt "$WORK/build/busybox/.config" "$opt"
done
# busybox's own Kconfig: oldconfig keeps the forced =y values and fills defaults.
make -C "$WORK/sources/busybox" O="$WORK/build/busybox" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- oldconfig </dev/null
for opt in "${BUSYBOX_APPLETS[@]}"; do
  grep -qx "CONFIG_${opt}=y" "$WORK/build/busybox/.config" || {
    echo "busybox CONFIG_${opt} did not resolve to y" >&2
    exit 1
  }
done
grep -qx 'CONFIG_STATIC=y' "$WORK/build/busybox/.config" || {
  echo "busybox is not CONFIG_STATIC=y" >&2
  exit 1
}
make -C "$WORK/sources/busybox" O="$WORK/build/busybox" ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- -j"$(nproc)" busybox
BUSYBOX_BIN="$WORK/build/busybox/busybox"
if aarch64-linux-gnu-readelf -l "$BUSYBOX_BIN" | grep -q 'INTERP'; then
  echo "busybox is dynamically linked" >&2
  exit 1
fi
aarch64-linux-gnu-readelf -h "$BUSYBOX_BIN" | grep -q 'AArch64' || {
  echo "busybox is not AArch64" >&2
  exit 1
}

echo "=== initramfs ==="
cc -O2 -o "$WORK/build/gen_init_cpio" "$WORK/kernel/usr/gen_init_cpio.c"
export INIT="$SCRIPT_DIR/init"
export BUSYBOX="$BUSYBOX_BIN"
"$WORK/build/gen_init_cpio" -t 0 "$SCRIPT_DIR/initramfs.list" >"$WORK/initramfs.cpio"
verify_cpio "$WORK/initramfs.cpio"

echo "=== kernel config ==="
mkdir -p "$WORK/build/kernel" "$WORK/artifacts"
cp "$WORK/umbrella/configs/kernel.config" "$WORK/build/kernel/.config"
umbrella_cmdline=$(grep -E '^CONFIG_CMDLINE=' "$WORK/umbrella/configs/kernel.config")
"$WORK/kernel/scripts/config" --file "$WORK/build/kernel/.config" \
  --set-str INITRAMFS_SOURCE "$WORK/initramfs.cpio" \
  --set-str EXTRA_FIRMWARE "" \
  --set-str EXTRA_FIRMWARE_DIR "" \
  --enable USB_CONFIGFS_ACM \
  --enable USB_CONFIGFS_SERIAL \
  --enable USB_CONFIGFS \
  --enable USB_LIBCOMPOSITE
make -C "$WORK/kernel" O="$WORK/build/kernel" ARCH=arm64 LLVM=1 olddefconfig

checks_file="$WORK/config-checks.txt"
: >"$checks_file"
config_ok=1
check_line() {
  local line=$1
  if grep -qxF "$line" "$WORK/build/kernel/.config"; then
    printf 'PASS %s\n' "$line" | tee -a "$checks_file"
  else
    printf 'FAIL %s\n' "$line" | tee -a "$checks_file"
    config_ok=0
  fi
}
check_line 'CONFIG_USB_CONFIGFS_ACM=y'
check_line 'CONFIG_USB_F_ACM=y'
check_line 'CONFIG_USB_U_SERIAL=y'
check_line 'CONFIG_BUILTIN_DTB=y'
check_line 'CONFIG_BUILTIN_DTB_NAME="qcom/sm8750-lenovo-elden"'
check_line 'CONFIG_CMDLINE_FORCE=y'
check_line 'CONFIG_EXTRA_FIRMWARE=""'
check_line 'CONFIG_DEBUG_INFO_BTF=y'
check_line 'CONFIG_SCHED_CLASS_EXT=y'
resolved_cmdline=$(grep -E '^CONFIG_CMDLINE=' "$WORK/build/kernel/.config")
if [[ "$resolved_cmdline" == "$umbrella_cmdline" ]]; then
  printf 'PASS CONFIG_CMDLINE byte-identical to umbrella\n' | tee -a "$checks_file"
else
  printf 'FAIL CONFIG_CMDLINE\n' | tee -a "$checks_file"
  printf 'umbrella: %s\n' "$umbrella_cmdline" | tee -a "$checks_file"
  printf 'resolved: %s\n' "$resolved_cmdline" | tee -a "$checks_file"
  config_ok=0
fi
if [[ "$config_ok" -ne 1 ]]; then
  echo "resolved kernel config failed required checks" >&2
  exit 1
fi

echo "=== kernel build ==="
make -C "$WORK/kernel" O="$WORK/build/kernel" ARCH=arm64 LLVM=1 \
  CC="${KERNEL_CC:-clang}" \
  -j"$(nproc)" Image qcom/sm8750-lenovo-elden.dtb

cp "$WORK/build/kernel/arch/arm64/boot/Image" "$WORK/artifacts/Image"
cp "$WORK/build/kernel/arch/arm64/boot/dts/qcom/sm8750-lenovo-elden.dtb" \
  "$WORK/artifacts/sm8750-lenovo-elden.dtb"
cp "$WORK/build/kernel/.config" "$WORK/artifacts/kernel.config"
: >"$WORK/empty-ramdisk"
python3 "$WORK/mkbootimg/mkbootimg.py" --header_version 4 \
  --kernel "$WORK/artifacts/Image" \
  --ramdisk "$WORK/empty-ramdisk" \
  --os_version 15.0.0 \
  --os_patch_level 2026-08 \
  --cmdline "$(cat "$WORK/umbrella/configs/cmdline.txt")" \
  --output "$WORK/artifacts/boot.img"

echo "=== embedded initramfs ==="
embedded=""
for cand in \
  "$WORK/build/kernel/usr/initramfs_data.cpio.gz" \
  "$WORK/build/kernel/usr/initramfs_data.cpio" \
  "$WORK/build/kernel/usr/initramfs_inc_data"; do
  if [[ -f "$cand" ]]; then
    embedded=$cand
    break
  fi
done
if [[ -z "$embedded" ]]; then
  echo "could not find usr/initramfs_data.cpio in the kernel build" >&2
  exit 1
fi
verify_cpio "$embedded"
# Also pull the gzip member back out of the linked Image.
python3 - "$WORK/artifacts/Image" "$WORK/initramfs.from-image" <<'PY'
import pathlib
import sys
import zlib

image = pathlib.Path(sys.argv[1]).read_bytes()
out = pathlib.Path(sys.argv[2])
idx = 0
found_at = None
while True:
    j = image.find(b"\x1f\x8b", idx)
    if j < 0:
        break
    # gzip.decompress() treats the bytes that follow this member in Image
    # as another gzip member and raises BadGzipFile. decompressobj stops
    # after the first member.
    decomp = zlib.decompressobj(16 + zlib.MAX_WBITS)
    try:
        data = decomp.decompress(image[j:])
        data += decomp.flush()
    except zlib.error:
        idx = j + 1
        continue
    if data.startswith(b"070701"):
        found_at = j
        out.write_bytes(data)
        break
    idx = j + 1
if found_at is None:
    sys.exit("no gzip newc cpio found inside Image")
print(f"extracted initramfs gzip from Image at offset {found_at}")
PY
verify_cpio "$WORK/initramfs.from-image"

echo "=== package ==="
mkdir -p "$OUT"
zstd -19 -f -o "$OUT/boot-gen4-debug.img.zst" "$WORK/artifacts/boot.img"
cp "$WORK/artifacts/kernel.config" "$OUT/kernel.config"

end_epoch=$(date +%s)
duration=$((end_epoch - START_EPOCH))
{
  echo "TB322FC gen4 debug boot image"
  echo "built_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "duration_sec: $duration"
  echo "nproc: $(nproc)"
  echo
  echo "pins:"
  echo "  umbrella: $UMBRELLA_URL $UMBRELLA_SHA"
  echo "  kernel: $KERNEL_URL $KERNEL_SHA"
  echo "  kernel_write_tree: $actual_tree"
  echo "  busybox: 1.36.1 $BUSYBOX_SHA"
  echo "  mkbootimg: $MKBOOTIMG_URL $MKBOOTIMG_COMMIT"
  echo "    mkbootimg.py $MKBOOTIMG_PY_SHA"
  echo "    gki/generate_gki_certificate.py $GKI_CERT_SHA"
  echo "  mkbootimg_choice: fetched AOSP sources in the work dir and ran them with python3; the host mkbootimg package is not used"
  echo
  echo "compilers:"
  echo "  clang: $(clang --version | head -n 1)"
  echo "  ld.lld: $(ld.lld --version | head -n 1)"
  echo "  aarch64-linux-gnu-gcc: $(aarch64-linux-gnu-gcc --version | head -n 1)"
  echo "  pahole: $(pahole --version)"
  echo
  echo "config checks:"
  cat "$checks_file"
  echo
  echo "resolved CONFIG_CMDLINE:"
  echo "$resolved_cmdline"
} >"$OUT/BUILD-INFO.txt"

{
  sha256sum "$WORK/artifacts/boot.img" | awk '{print $1 "  boot.img"}'
  sha256sum "$WORK/artifacts/Image" | awk '{print $1 "  Image"}'
  sha256sum "$OUT/boot-gen4-debug.img.zst" | awk '{print $1 "  boot-gen4-debug.img.zst"}'
  sha256sum "$OUT/kernel.config" | awk '{print $1 "  kernel.config"}'
} >"$OUT/SHA256SUMS"

zst_bytes=$(stat -c %s "$OUT/boot-gen4-debug.img.zst")
echo "boot-gen4-debug.img.zst bytes: $zst_bytes"
if [[ "$zst_bytes" -ge $((95 * 1024 * 1024)) ]]; then
  echo "compressed image is >= 95 MiB; not safe to commit" >&2
  exit 1
fi
echo "Built $OUT/boot-gen4-debug.img.zst in ${duration}s"
