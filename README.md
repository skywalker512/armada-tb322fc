# armada-tb322fc

ArmadaOS（SteamOS-like ARM Linux）适配 Lenovo Legion Y700 Gen 4 / Legion Tab Gen 4
（TB322FC，骁龙 8 Elite / SM8750，代号 `elden`）的移植仓库。

> [!WARNING]
> 当前处于调研 / 启动阶段：仓库只有文档与来源跟踪，没有可刷镜像。
> 上游 [armada-os/armada](https://github.com/armada-os/armada) 官方支持列表不含任何平板；
> 本移植与上游无关，问题请提到本仓库，不要去官方 Armada 报。
>
> **四代的主线 Linux bring-up 已有人在做**（h0cheung/GEEKiDoS、xiaquwan1001，
> 完成度已很高），缺的是 **ArmadaOS 发行版层**的适配——见 `docs/00-RESEARCH.md` §5。

## 设备

| 项 | 值 |
|---|---|
| 型号 | Lenovo Legion Y700 Gen 4（国行 TB322FC） |
| SoC | Snapdragon 8 Elite / SM8750 |
| 代号 | `elden`（主线 DT 中 `lenovo,elden`） |
| 屏幕 | 8.8" 3040×1904 IPS，165 Hz；DT 里面板是 `csot,pp8807hb1-1`（Novatek NT36536 触控） |
| 内存 / 存储 | 12/16 GB LPDDR5X，最高 1 TB UFS 4.0 + microSD |
| USB | 双 USB-C；仅长边口支持 fastboot/9008 |
| 原厂系统 | ZUXOS（Android 16） |

## 路线参考

- 三代移植：[enij90/armada-tb321fu](https://github.com/enij90/armada-tb321fu)（TB321FU / SM8650，完成度高，仅 BOE 屏，整机擦除安装）
- 平板多系统路线：[mydanyi/armadaos-freedom](https://github.com/mydanyi/armadaos-freedom)（kShimC 多启动，当前目标是五代 TB323FU / SM8850P）
- 四代板级基础：[GUF296/tb321fu-linux](https://github.com/GUF296/tb321fu-linux) 同一作者已进主线 gen4 DT 补丁的 CC 列表

## 文档

- `docs/00-RESEARCH.md` — 互联网上四代 Linux / Armada 相关工作的完整盘点（谁在做、做到哪）
- `docs/01-STATUS.md` — 硬件功能状态矩阵（主线 vs 下游 vs Android 侧）
- `docs/02-PLAN.md` — 候选技术路线与待决策项
- `SOURCES.md` — 跟踪的上游仓库 / 补丁集 / 版本 pin

## 仓库结构

本仓以 [mydanyi/armadaos-freedom](https://github.com/mydanyi/armadaos-freedom)
（本身是 armada-os/armada 的 fork）为基底合并而来，携带 armada 上游全部历史 +
kShimC STAR_CHART 快照 + tb323fu 设备目录样板。

- `devices/lenovo-tb322fc/` — 四代适配目录（内核 pin、固件清单、rootfs 起步件、
  kShimC elden 适配层、构建骨架），是本仓的工作重心
- `devices/lenovo-tb323fu/` — freedom 带来的五代参照实现，勿删
- 其余目录（`build_files/`、`system_files/`、`packages/`、`decky/` 等）为
  armada/freedom 上游结构，设备集成时按需接入
- `README-armada.md` — 上游 armada 原版 README
