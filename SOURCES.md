# SOURCES — 跟踪的上游与参考来源

## 发行版 / 上游

| 来源 | 用途 | 备注 |
|---|---|---|
| https://github.com/armada-os/armada | 上游发行版（Fedora bootc + ROCKNIX 设备层） | 支持列表含 AYN Odin 3（SM8750 ✅）；平板非官方 |
| https://github.com/mydanyi/armadaos-freedom | 平板 fork + kShimC 多启动模板 | 当前目标 tb323fu（五代/SM8850P） |
| https://github.com/enij90/armada-tb321fu | 三代移植先例 | BOE 屏限定、擦机安装、DP 无声 |

## 内核 / bring-up（四代已有活跃项目）

| 来源 | 用途 | 备注 |
|---|---|---|
| https://github.com/h0cheung/tb322fc-linux | **四代 umbrella**：构建/固件清单/状态矩阵 | 2026-10-11 活跃；≈90% 子系统实测可用；CI 出 Arch Ports 镜像 |
| https://github.com/h0cheung/tb322fc-linux-kernel | 上述的内核树 | fork 自 GEEKiDoS/linux `v7.2-elden` |
| https://github.com/GEEKiDoS/linux (`v7.2-elden`) | 四代内核上游开发分支 | h0cheung 之前的先驱版本 |
| https://github.com/xiaquwan1001/lenovo-legion-y700-gen4-tb322fc-elden-linux | 研究型 bring-up 工作区 | Q28 冷启动显示竞态、PITFALLS.md(170+)、Waydroid/Box64 进展 |
| LKML `Introduce Lenovo Legion Y700 Gen4` v1/v2 | 官方 DT（`sm8750-lenovo-elden.dts`） | Pengyu Luo；v2 2026-07-26，在审 |
| https://github.com/sm8750-mainline/linux | SM8750 主线化社区树 | 默认分支 v6.16 |
| https://github.com/sunflower2333/linux | 下游树，含 `sm8750-lenovo-y700-gen4.dts` | release-26.08.13.43 引入 |
| https://github.com/GUF296/tb321fu-linux | 三代板级工作（作者也 CC 在 gen4 补丁上） | 四代板件差异参照 |
| https://github.com/GUF296/xiaomi-pad-8-pro-linux | 同 SoC 系平板参照（SM8750 系 "piano"） | Ubuntu + Plasma on Pad 8 Pro |
| https://github.com/ll1zt/tb322fc-droidspaces-kernel | Android 侧 GKI 内核 + testkey/EDL root | 原厂 config.gz 基底、KMI/clang-r510928 要点 |

## 启动 / 刷机工具

| 来源 | 用途 | 备注 |
|---|---|---|
| https://github.com/miner7222/LTBox | EDL(9008) 分区写、root、救砖 GUI | 支持 TB322FC |
| https://github.com/polygraphene/android_device_lenovo_TB322FC | TWRP（twrp-16.0） | ZUI ≤1.5.10.138 可免解锁 EDL 刷入 |
| https://github.com/lolipuru/android_device_lenovo_elden + https://github.com/lenovo-basements | AOSP 系 device/vendor 树 | elden 定制 ROM 侧 |
| https://github.com/l11223/geekflash | macOS EDL 刷机工具 | TB322FC 专用 |
| https://github.com/18027972083/y700-flash-guide | 9008/QDL + vbmeta 诊断笔记 | — |
| https://github.com/aweiyry/lenovo-ota-tool | OTA 增量包分区提取 | 三代/四代/五代通用 |
| https://github.com/edk2-porting/edk2-msm | UEFI 备选引导 | 暂无 elden/sm8750 设备配置 |

## 情报 / 报道

- Phoronix: https://www.phoronix.com/news/Lenovo-Y700-Gen4-Linux-Patches
- IT之家: https://www.ithome.com/0/978/940.htm
- 虹墨空间站（9008/分区/fastboot 口实测）: https://www.imaegoo.com/2026/y700-tb322fc-flash-hyper/
