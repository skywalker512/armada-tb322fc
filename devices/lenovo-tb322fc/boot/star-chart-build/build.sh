#!/bin/sh
# elden (TB322FC) STAR_CHART 打包流水线 —— Linux 容器/工作目录内执行。
#
# 工作目录约定（沿用 freedom star-chart-build）：
#   /work/
#     source/                 # 已由 ../fetch-kshim.sh 物化（或 bind-mount）
#     MultiBootKernelPatcher/ # 本脚本克隆/检出；manifest_qemu.py 要求其为
#                             # source 的兄弟目录
#     patches-boot/           # freedom devices/lenovo-tb323fu/patches/boot/
#                             # 的拷贝（也可用 PATCHES_DIR 指到仓库内路径）
#     inputs/                 # 真机/本地输入，不入库（见 README.md）
#     out/ qemu-manifest/ boot-candidate/ evidence/
#
# 注意：本脚本只做离线打包验证；产物未经真机 fastboot boot 验收前
# 不得标注为可用（见 evidence/ 与 validation.json 的 hardware_tested:false）。
set -eu
cd /work
mkdir -p evidence

PATCHES_DIR=${PATCHES_DIR:-/work/patches-boot}
PACKER_URL=https://github.com/Project-Aloha/DualBootKernelPatcher.git
PACKER_BASELINE=${PACKER_COMMIT:-2276163d066596cb0750e76cbfeec5c193b1779f}

step() {
    label=$1
    shift
    printf '%s\n' "$label"
    set +e
    "$@" > "evidence/$label.log" 2>&1
    status=$?
    set -e
    printf '%s\n' "$status" > "evidence/$label.exit"
    if [ "$status" != 0 ]; then tail -n 60 "evidence/$label.log"; exit "$status"; fi
}

# 1. ARM64 runtime（4 MiB manifest 槽；elden_defconfig）
step runtime python3 source/tools/build_runtime.py \
    --config source/configs/elden_defconfig --out out/runtime --jobs "${JOBS:-$(nproc)}"

# 2. 打包器：上游基线 → freedom 本地基线（mbox）→ 共享 PayloadFrom 补丁
if [ ! -d MultiBootKernelPatcher/.git ]; then
    step packer-clone git clone "$PACKER_URL" MultiBootKernelPatcher
fi
git -C MultiBootKernelPatcher fetch origin "$PACKER_BASELINE" || true
step packer-checkout git -C MultiBootKernelPatcher checkout --detach "$PACKER_BASELINE"
if [ -f "$PATCHES_DIR/0001-patcher-local-commits.mbox" ] &&
    [ "$(git -C MultiBootKernelPatcher log -1 --format=%s)" != \
        "fix: enforce eight-byte device tree alignment" ]; then
    step packer-mbox git -c user.name=armada-tb322fc -c user.email=build@localhost \
        -C MultiBootKernelPatcher am "$PATCHES_DIR/0001-patcher-local-commits.mbox"
fi
if [ -f "$PATCHES_DIR/0002-patcher-shared-payload-working-tree.patch" ] &&
    ! git -C MultiBootKernelPatcher apply -R --check \
        "$PATCHES_DIR/0002-patcher-shared-payload-working-tree.patch" >/dev/null 2>&1; then
    step packer-patch git -C MultiBootKernelPatcher apply \
        "$PATCHES_DIR/0002-patcher-shared-payload-working-tree.patch"
fi
# 3. QEMU manifest ABI 演练（构建 packer/UnpackTool 并跑 manifest 契约）
step qemu python3 source/tests/manifest_qemu.py \
    --runtime out/runtime/kShimC.bin --out qemu-manifest

# PayloadFrom 契约回归（针对刚构建的 packer；需要 dtc）
if [ -f "$PATCHES_DIR/payload_from.py" ] && command -v dtc >/dev/null 2>&1; then
    step payload-contract python3 "$PATCHES_DIR/payload_from.py" \
        --packer qemu-manifest/packer/MultiBootKernelPatcher \
        --unpacker qemu-manifest/packer/UnpackTool \
        --out payload-contract
fi

# 4. 离线 boot 组装 + 校验（stock boot/img、Linux Image、双 DTB、avbtool）
step boot python3 -B build_offline_boot.py \
    --stock-boot inputs/boot-stock.img \
    --stock-image inputs/Image.stock \
    --linux-image inputs/Image.linux \
    --runtime out/runtime/kShimC.bin \
    --tf-dtb inputs/tf.dtb \
    --internal-dtb inputs/internal.dtb \
    --packer qemu-manifest/packer/MultiBootKernelPatcher \
    --unpacker qemu-manifest/packer/UnpackTool \
    --repacker repack_boot_v4.py \
    --avbtool inputs/avbtool.py \
    --out boot-candidate

cp out/runtime/validation.json evidence/runtime-validation.json
cp qemu-manifest/validation.json evidence/qemu-validation.json
cp out/runtime/.config evidence/runtime.config
printf '0\n' > build.exit
