# 00 · 调研：Y700 Gen 4 (TB322FC) Linux / ArmadaOS 生态盘点

调查日期：2026-10-14（GitHub API 复核后修正）。结论先行：**四代的主线 Linux bring-up
已经有人在做，而且完成度不低**（h0cheung/GEEKiDoS、xiaquwan1001 至少两条活跃路线）；
**还没有人做的是「ArmadaOS 发行版层」的适配**。对我们而言这意味着不需要从零做板级内核，
重点是发行版集成与差异化（多启动、游戏栈）。

## 1. 主线内核：已有官方 DT 补丁（最重要）

- 提交者：**Pengyu Luo** `<mitltlatltl@gmail.com>`；CC 里有 `guf296`（就是三代
  [GUF296/tb321fu-linux](https://github.com/GUF296/tb321fu-linux) 的作者，说明同一人已在四代上干活）。
- 补丁集：`[PATCH v2 0/2] Introduce Lenovo Legion Y700 Gen4`
  - v1：2026-07-19 — https://lore.kernel.org/linux-devicetree/20260719093226.197740-1-mitltlatltl@gmail.com/
  - v2：2026-07-26 — https://lkml.iu.edu/hypermail/linux/kernel/2607.3/03457.html
  - Patchew v1↔v2 对比：https://patchew.org/linux/20260719093226.197740-1-mitltlatltl@gmail.com/diff/20260726143048.130116-1-mitltlatltl@gmail.com/
- 内容：`sm8750-lenovo-elden.dts`（~1170 行，基于 `sm8750-qrd`）+ `qcom.yaml` 绑定里加 `lenovo,elden`。
- Phoronix 报道（2026-07）：https://www.phoronix.com/news/Lenovo-Y700-Gen4-Linux-Patches
  - 已工作：按键、双 USB（含 altmode）、充电/电量计、framebuffer 显示、背光。
  - 需下游补丁：GPU（Turnip）、Novatek 触摸屏。
  - 未工作：Wi-Fi、蓝牙、摄像头；麦克风/传感器/马达也仅下游。
- 面板注意：上游 DT 写的是 `csot,pp8807hb1-1` + `novatek,nt36536`。
  三代 enij90 移植只支持 BOE（CSOT 黑屏），四代至少要确认国行屏的供应商分布——可能与三代相反。

### 下游 / 社区内核树 —— 四代 bring-up 已在进行（重要更正）

- **[h0cheung/tb322fc-linux](https://github.com/h0cheung/tb322fc-linux)**（活跃，2026-10-11 更新）：
  umbrella 仓库，结构沿用 GUF296/tb321fu-linux 风格；内核在
  [h0cheung/tb322fc-linux-kernel](https://github.com/h0cheung/tb322fc-linux-kernel)
  （fork 自 GEEKiDoS/linux `v7.2-elden` 分支）。**实测已工作**：显示 24/40/60/90/120/144/165 Hz、
  NT36536 触摸、Adreno 830（Mesa Turnip + Zink）、Wi-Fi（Peach/ath12k）、蓝牙、
  扬声器（AW88461 + AudioReach 拓扑/UCM）、内置麦、双 AW86927 触觉、ADSP/SSC 传感器、
  s2idle 挂起；摄像头部分可用；剩余问题在充电唤醒/电量上报与休眠到盘。
  CI 可直接产出 Arch Linux Ports Plasma 的 `boot.img` + `rootfs.img`（尚需固件配套验证）。
  **其 `packages/` 已经是一整套 Arch 版 Armada 用户态**：armada-control/armada-store
  decky 插件源码、armada-powerd（含 `lenovo-y700-gen4.conf`）、gamescope-armada
  （29 个补丁 + `csot.pp8807hb1-1.lua` 面板 profile）、gamescope-session-steam、
  steamos-manager（`sm8750.toml` platform profile）、mesa-y700-gen4-git（a8xx Turnip
  补丁集）、steam-bootstrap、y700-charge decky 插件、tb322fc-sensors（gyro/hall 桥）、
  iio-sensor-proxy-y700、thermald 配置等——即「Arch Ports 上的 Armada」也已在路上，
  缺的同样是发行版集成与多启动。
- **[GEEKiDoS/tb322fc-linux](https://github.com/GEEKiDoS/tb322fc-linux)**（2026-09-12 创建）：
  同一 umbrella 的先驱版本，内核开发在其 linux 仓库 `v7.2-elden` 分支；README 明确说明结构
  沿袭 tb321fu-linux，h0cheung 版是其后继/协作 fork（状态更新到 BT、suspend、mic 已验证）。
- **[xiaquwan1001/lenovo-legion-y700-gen4-tb322fc-elden-linux](https://github.com/xiaquwan1001/lenovo-legion-y700-gen4-tb322fc-elden-linux)**
  （2026-10-10 建，研究记录型工作区，中文文档极详细）：
  目标 G1 完整上游 Linux（自称 ≈90%，27/30 项可用）、G2 Waydroid 安卓容器（≈50%，
  容器传感器 HAL 已打通）、G3 Box64+Wine/Steam（PoC 已过）。
  **关键已知问题**：`Q28` 冷启动显示竞态（bonded 双 DSI 首条 DCS 命令的 cmd-DMA hang，
  表现为 NOCARD/STORM/GOOD 三态）、`#106` 亮屏进桌面后整机卡死、`Q24` 相机×熄屏互斥。
  其 `PITFALLS.md`（170+ 条踩坑）和 `q28-DOSSIER` 是四代显示子系统最值钱的一手资料。
- [sunflower2333/linux](https://github.com/sunflower2333/linux)：release `26.08.13.43`
  含 `sm8750-lenovo-y700-gen4.dts`（1018 行）。
  commit: https://github.com/sunflower2333/linux/commit/f4b4bf129702d16ef5a61933d493161063e7cb4d
- [sm8750-mainline/linux](https://github.com/sm8750-mainline/linux)：SM8750 主线化组织 fork（默认分支 v6.16），
  SM8750 SoC 级支持的主要来源。
- 同 SoC 参照：[GUF296/xiaomi-pad-8-pro-linux](https://github.com/GUF296/xiaomi-pad-8-pro-linux)
  （三代作者 GUF296 现在做 Xiaomi Pad 8 Pro "piano" 的 Ubuntu——同为 SM8750 系平板，
  其 ADSP/SSC 传感器、音频拓扑打包件可对照）。

## 2. Android 侧（root / 容器 / Recovery，可复用的启动链知识）

- [ll1zt/tb322fc-droidspaces-kernel](https://github.com/ll1zt/tb322fc-droidspaces-kernel)：**锁 BL 状态**下跑
  Droidspaces 容器的 GKI 内核（6.6.89-android15）+ KernelSU-Next。要点：
  - 联想用**公开 AOSP testkey** 签启动链 → 自签内核可过 AVB；配 EDL(9008) 经 LTBox 写入，
    不解锁、不清数据拿到内核级 root。
  - Turnip 已工作（Mesa 26.3.0-devel，glmark2 2714）；Wi-Fi/BT 正常。
  - KMI 契约要求精确 clang r510928；`CONFIG_SYSVIPC` 需 kABI 补丁。
- [polygraphene/android_device_lenovo_TB322FC](https://github.com/polygraphene/android_device_lenovo_TB322FC)：
  TWRP（twrp-16.0），有 release。注明 ZUI ≤ 1.5.10.138 可用 testkey 漏洞免解锁经 EDL 刷入。
- 定制 ROM 侧：[lolipuru/android_device_lenovo_elden](https://github.com/lolipuru/android_device_lenovo_elden)
  + [lenovo-basements](https://github.com/lenovo-basements) org（`android_device_lenovo_elden-kernel`、
  `proprietary_vendor_lenovo_elden`）——AOSP 系 device/vendor 树已有人搭。
- 周边工具：[l11223/geekflash](https://github.com/l11223/geekflash)（macOS EDL 刷机 GUI）、
  [18027972083/y700-flash-guide](https://github.com/18027972083/y700-flash-guide)（9008/QDL + vbmeta 笔记）、
  [aweiyry/lenovo-ota-tool](https://github.com/aweiyry/lenovo-ota-tool)（三代/四代/五代 OTA 分区提取）。
- [miner7222/LTBox](https://github.com/miner7222/LTBox)：跨平台刷机 GUI，支持 TB322FC
  （EDL 写分区、root、救砖；TB323FU/TB324ZC 反而限制更多——四代是工具链支持较好的一代）。
- 酷安 GUF26 的澎湃 OS 3 移植 + 虹墨空间站教程（https://www.imaegoo.com/2026/y700-tb322fc-flash-hyper/）：
  确认 9008 端口**未加密**、UFS 6 LUN rawprogram 结构、只有长边 USB-C 口支持 fastboot。

## 3. ArmadaOS 侧

- 上游 [armada-os/armada](https://github.com/armada-os/armada)：Fedora bootc + ROCKNIX 设备层，
  Steam/FEX/CachyOS Proton 11 + KDE。支持列表里 **SM8750 已有 AYN Odin 3（✅ Tested）**——
  即 SoC 级 Armada 支持已存在，四代移植主要是板级 + 启动链 + 面板。
- 平板不在官方范围：[issue #429](https://github.com/armada-os/armada/issues/429)（Xiaomi Pad 6S Pro
  用户 fork 成功，官方回应"平板考虑过但没排期，且 bootc 是硬要求"）。→ 四代只能走社区 fork，
  同三代路径。
- 三代移植 [enij90/armada-tb321fu](https://github.com/enij90/armada-tb321fu)：完成度参考
  （165 Hz BOE 屏、触摸、GPU、Wi-Fi、BT、扬声器、G9 手柄+灯带、VRR、DP 外显可用；
  限制：仅 BOE 屏、安装即擦 Android、外显无声）。架构：fork armada + `tb321fu/` 设备目录 +
  ABL 启动链。
- [mydanyi/armadaos-freedom](https://github.com/mydanyi/armadaos-freedom)：kShimC 多启动方案
  （STAR_CHART 菜单：Android / 机身 ArmadaOS / TF 卡 ArmadaOS / 诊断 / Recovery / Fastboot / 9008），
  当前设备目录是 `devices/lenovo-tb323fu`（五代 SM8850P）。**四代可复用同一套 kShimC 方案**，
  避免三代"整机擦除"的限制。

## 4. UEFI / 引导备选

- [edk2-porting/edk2-msm](https://github.com/edk2-porting/edk2-msm)（Renegade Project）：高通平台
  EDK2 UEFI + SimpleInit 多启动。目前未见 SM8750/elden 设备配置；移植需要 `/sys/firmware/fdt`、
  `/proc/iomem`、boot.img 解包等（ Porting guide: https://renegade-project.tech/en/porting ）。
- 更现实的路径仍是 Android boot 镜像格式（boot/vendor_boot/init_boot + dtbo）：
  Android 侧整条链（TWRP/GKI/testkey 签名）已验证可行。

## 5. 结论：谁在做四代？

| 路线 | 状态 | 负责人/仓库 |
|---|---|---|
| 主线 DT | ✅ 补丁在审（v2，2026-07-26） | Pengyu Luo（+ guf296 参与） |
| SM8750 SoC 主线化 | ✅ 社区 org 活跃 | sm8750-mainline、sunflower2333 等 |
| **四代主线 Linux bring-up** | ✅ **已在做，≈90% 子系统可用** | **h0cheung/GEEKiDoS（tb322fc-linux，10-11 活跃）；xiaquwan1001（研究型工作区）** |
| 四代 Armada 用户态 | ⚠️ Arch Ports 版在 h0cheung 仓 `packages/`（非 bootc） | 同上 |
| **ArmadaOS（bootc 发行版）四代移植** | ❌ 无公开仓库 | **本仓库要填的空——但应站在上面两个 bring-up 之上，别重造内核层** |
| ArmadaOS 三代移植 | ✅ 高完成度 | enij90/armada-tb321fu |
| ArmadaOS 五代/平板 multiboot | ✅ 进行中 | mydanyi/armadaos-freedom（tb323fu） |
| Android root/容器/Recovery/ROM | ✅ 可用 | ll1zt、polygraphene、LTBox、lolipuru、lenovo-basements |
| UEFI (edk2) | ❌ 无 elden 配置 | — |

定位修正：四代不是「没人做」而是「**内核/板件层有人做到九成，发行版/游戏栈层没人接**」。
合理切入点是直接复用 h0cheung/tb322fc-linux（或其上游 GEEKiDoS/linux `v7.2-elden`）的内核与
固件清单，在其上套 ArmadaOS rootfs/bootc 层 + freedom 的 kShimC 多启动；
并优先消化 xiaquwan1001 记录的 Q28 冷启动显示竞态——那是四代目前最大的硬伤，
任何发行版都会撞上。
