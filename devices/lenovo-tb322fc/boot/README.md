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

## 目录

- `kshim-elden/elden_defconfig` — 设备 defconfig 草稿（基于 tb323fu_defconfig 修改点标注）
- `star-chart-build/` — 构建骨架（沿用 freedom `star-chart-build` 约定，输入路径同其 README）
- `quiet-thermal-no-gpu.dtsi` — elden 版温区 GPU 解绑片段（TODO：照 tb323fu 同名文件改 elden DT 节点名）

## 参考

- freedom 构建配方：`devices/lenovo-tb323fu/boot/star-chart-build/README.md`
- freedom 打包器补丁：`devices/lenovo-tb323fu/patches/boot/`（PayloadFrom 共享改动对 elden 仍需复核）
