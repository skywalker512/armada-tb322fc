#!/usr/bin/env bash
# Materialize a pinned kShimC workspace for elden (TB322FC) STAR_CHART work.
#
#   usage: fetch-kshim.sh <workdir>
#
# Produces <workdir>/source/ = kShimC feature/2610 @ KSHIM_COMMIT with
# submodules restored at pinned commits, ports/crdk patches applied, and
# devices/lenovo-tb322fc/boot/kshim-elden/ overlaid on top. No firmware,
# no device payload — build inputs are supplied separately (see
# star-chart-build/README.md).
set -euo pipefail

WORK=${1:?usage: $0 <workdir>}
DEVDIR=$(cd "$(dirname "$0")/.." && pwd)

# Pins — keep in sync with devices/lenovo-tb322fc/docs/SOURCES.md.
KSHIM_URL=https://github.com/sunflower2333/kShimC.git
KSHIM_BRANCH=feature/2610
KSHIM_COMMIT=${KSHIM_COMMIT:-feature/2610}   # TODO: freeze to sha once elden layer settles
CRDK_COMMIT=b6c3335136b7f6b28271917de11e8f11982975fc
PICOLIBC_COMMIT=f7edb0869e64b9d687f46961adeef7154921fe92
LVGL_COMMIT=7f07a129e8d77f4984fff8e623fd5be18ff42e74

mkdir -p "$WORK"

echo "==> clone kShimC ($KSHIM_BRANCH)"
if [ ! -d "$WORK/source/.git" ]; then
    git clone "$KSHIM_URL" "$WORK/source"
fi
git -C "$WORK/source" fetch origin "$KSHIM_COMMIT"
git -C "$WORK/source" checkout --detach "$KSHIM_COMMIT"
git -C "$WORK/source" submodule update --init --recursive

restore_submodule() {
    local path=$1 commit=$2
    echo "==> $path @ $commit"
    git -C "$WORK/source/$path" fetch origin "$commit" || true
    git -C "$WORK/source/$path" checkout --detach "$commit"
}
restore_submodule lib/CrDK         "$CRDK_COMMIT"
restore_submodule lib/picolibc     "$PICOLIBC_COMMIT"
restore_submodule third_party/lvgl "$LVGL_COMMIT"

echo "==> ports/crdk patch layer"
if [ -d "$WORK/source/ports/crdk/patches" ]; then
    for p in "$WORK"/source/ports/crdk/patches/*.patch; do
        [ -e "$p" ] || continue
        git -C "$WORK/source/lib/CrDK" apply "$p" || { echo "FAILED: $p"; exit 1; }
    done
fi

echo "==> libfdt ships in-tree upstream (lib/libfdt/) — nothing to do"

echo "==> overlay elden device files"
cp -v "$DEVDIR/boot/kshim-elden/elden_defconfig" "$WORK/source/configs/elden_defconfig"
if [ -d "$DEVDIR/boot/kshim-elden/patches" ]; then
    for p in "$DEVDIR"/boot/kshim-elden/patches/*.patch; do
        [ -e "$p" ] || continue
        git -C "$WORK/source" apply "$p" && echo "applied $(basename "$p")"
    done
fi

echo "==> done. Next: tools/build_runtime.py --config configs/elden_defconfig --out out/runtime"
