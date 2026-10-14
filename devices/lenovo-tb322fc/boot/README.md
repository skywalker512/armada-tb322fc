# kShimC on elden（TB322FC）— 移植说明

## 方案

kShimC（[sunflower2333/kShimC `feature/2610`](https://github.com/sunflower2333/kShimC/tree/feature/2610)）
是注入在 Android boot 镜像内的裸机 shim：启动时先跑 kShimC，画 LVGL
STAR_CHART 菜单（中/英），按选择把控制权交给 Android payload 内核或 Linux 内核
（机身分区或 TF 卡），并对 DT 做交接处理。freedom 在 tb323fu 上的 STAR_CHART
快照在 `../lenovo-tb323fu/boot/kshim-success-source/`，本目录维护 elden 适配层，
不再复制整套源码。

## elden 与 tb323fu 的差异点（移植工作量所在）

| 项 | tb323fu（SM8850P） | elden/TB322FC（SM8750） | 动作 |
|---|---|---|---|
| 面板 | NT36523 "baldur"，单 DSI（90/165Hz 补丁） | **bonded 双 DSI + DSC**，CSOT PP8807HB1 | 菜单用 bootloader 已点亮的 framebuffer（simplefb 风格），不自初始化 DSI —— 需要确认 kShimC 的 framebuffer 来源在 elden 上等价可用；**注意 Q28 是内核侧 DSI init 竞态，与菜单无关** |
| 触摸（菜单内） | st_ftm5（FTM4 已从快照删除） | Novatek NT36536 | 初版关闭 `KSHIM_TOUCH`（同 tb323fu），按键导航；要触摸需写 NT36536 i2c 驱动 |
| PMIC/SPMI | pm8550 系列（tb323fu 树） | pm8550 + pmk8550 + pmih0108（见主线 elden dts） | SPMI SID/寄存器表按 elden fdt 核对 |
| 按键 | PMIC vol/power | 同（gpio-keys via PMIC） | `CONFIG_QCOM_KEYS` 沿用，键位扫描码按 elden 实测 |
| ramoops 导出 | `src/dt/tb323fu_ramoops*.c` | elden 保留内存地址不同 | 从 `/proc/iomem` 与 stock fdt 提取 ramoops/pstore 区域，写 `elden_ramoops` 对应文件 |
| 内存布局 | SM8850 memory map | SM8750，需 stock fdt 的 reserved-memory | `memory_overlay`/handoff reservations 逐项核 |
| 显示控制器代次 | SSPP v13 | SM8750 DPU 代次待查（同代或 v12） | 若 kShimC 需要操作 DPU（如旋转/清屏路径），按 elden 实际代次 |

## 需要先从真机取的输入（构建前置）

- `boot-stock.img` / `Image.stock`（原厂 boot 解包）
- `Image.linux`（h0cheung 构建产物或本仓内核流水线产物）
- `tf.dtb` / `internal.dtb`（payload 用 elden dtb 变体）
- `/sys/firmware/fdt`、`/proc/iomem`、`/proc/config.gz`（root 后提取；testkey+EDL 免解锁路径见顶层 docs/01-STATUS.md）
- `avbtool.py`（AOSP）

## 已核对的移植面（详见 `elden-porting-notes.md`）

- 按键：PMIC 路径已具备——VOL+ 在 `pm8550_gpios` pin6，VOL- 走 `pon_resin`，
  POWER 走 pon；kShimC `keys.c`/`spmi.c` 基本通用。
- 必改：`keys.c` 的 TLMM `Layouts[]` 加 `{"qcom,sm8750-tlmm", 216}`；
  `gpio.c` 的 `kshim_dt_soc` 只有 8150/8250，PMIC 按键路径用不到可先不动。
- ramoops 导出是 tb323fu 专属文件，elden 版需真机 `/proc/iomem` 后写。

## 构建冒烟（2026-10-14 已验证）

`fetch-kshim.sh` 拉取 pin 定源码 → `build_runtime.py` 用 `elden_defconfig`
构建 **PASS**：`kShimC.bin` 精确 4 MiB、无未解析符号。

- 本机 macOS + aarch64-elf-gcc 16.2：sha256 `65792e8e…a0b6`
  （经 `kshim-elden/patches/0002` env 工具链覆盖）。
- CI ubuntu-24.04 + aarch64-linux-gnu-gcc：sha256 `a458cbb6…e7d3`，
  workflow `kshim-elden.yml`（push/手动触发，产物上传为 artifact）。
  两边编译器版本不同，二进制 hash 不一致属预期。

```sh
devices/lenovo-tb322fc/boot/fetch-kshim.sh /tmp/kshim-elden
cd /tmp/kshim-elden/source
# Linux: 默认 /usr/bin/aarch64-linux-gnu-*；macOS/其他环境用 env 覆盖：
KSHIM_CC=aarch64-elf-gcc KSHIM_OBJCOPY=aarch64-elf-objcopy KSHIM_NM=aarch64-elf-nm \
  python3 tools/build_runtime.py --config configs/elden_defconfig --out out/runtime
```

依赖：`kconfiglib`（genconfig 需在 PATH）、cmake、ninja、aarch64 gcc。
lib/CrDK、lib/picolibc、third_party/lvgl 子模块由脚本按 pin 还原；
libfdt 上游已内置于 `lib/libfdt/`。

## 目录

- `fetch-kshim.sh` — pin 定源码 + 子模块 + elden overlay 的一键准备脚本
- `kshim-elden/elden_defconfig` — 设备 defconfig（runtime 构建已验证）
- `kshim-elden/patches/` — elden overlay 补丁：`0001` sm8750-tlmm(216) 按键布局、
  `0002` KSHIM_CC/OBJCOPY/NM env 覆盖（本机/CI 验证用，上游默认值不变）
- `elden-porting-notes.md` — 已核对硬数据（TLMM/按键/面板/PMIC/Wi-Fi）
- `star-chart-build/` — payload 打包骨架（沿用 freedom `star-chart-build` 约定）
- `quiet-thermal-no-gpu.dtsi` — elden 版温区 GPU 解绑片段（TODO：照 tb323fu 同名文件改 elden DT 节点名）

## 参考

- freedom 构建配方：`devices/lenovo-tb323fu/boot/star-chart-build/README.md`
- freedom 打包器补丁：`devices/lenovo-tb323fu/patches/boot/`（PayloadFrom 共享改动对 elden 仍需复核）
