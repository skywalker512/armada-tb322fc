# SOURCES — 跟踪的上游与参考来源

## 发行版 / 上游

| 来源 | 用途 | 备注 |
|---|---|---|
| https://github.com/armada-os/armada | 上游发行版（Fedora bootc + ROCKNIX 设备层） | 支持列表含 AYN Odin 3（SM8750 ✅）；平板非官方 |
| https://github.com/mydanyi/armadaos-freedom | 平板 fork + kShimC 多启动模板 | 当前目标 tb323fu（五代/SM8850P） |
| https://github.com/enij90/armada-tb321fu | 三代移植先例 | BOE 屏限定、擦机安装、DP 无声 |

## 内核

| 来源 | 用途 | 备注 |
|---|---|---|
| LKML `Introduce Lenovo Legion Y700 Gen4` v1/v2 | 官方 DT（`sm8750-lenovo-elden.dts`） | Pengyu Luo；v2 2026-07-26，在审 |
| https://github.com/sm8750-mainline/linux | SM8750 主线化社区树 | 默认分支 v6.16 |
| https://github.com/sunflower2333/linux | 下游树，含 `sm8750-lenovo-y700-gen4.dts` | release-26.08.13.43 引入 |
| https://github.com/GUF296/tb321fu-linux | 三代板级工作（作者也 CC 在 gen4 补丁上） | 四代板件差异参照 |
| https://github.com/ll1zt/tb322fc-droidspaces-kernel | Android 侧 GKI 内核 + testkey/EDL root | 原厂 config.gz 基底、KMI/clang-r510928 要点 |

## 启动 / 刷机工具

| 来源 | 用途 | 备注 |
|---|---|---|
| https://github.com/miner7222/LTBox | EDL(9008) 分区写、root、救砖 GUI | 支持 TB322FC |
| https://github.com/polygraphene/android_device_lenovo_TB322FC | TWRP（twrp-16.0） | ZUI ≤1.5.10.138 可免解锁 EDL 刷入 |
| https://github.com/edk2-porting/edk2-msm | UEFI 备选引导 | 暂无 elden/sm8750 设备配置 |

## 情报 / 报道

- Phoronix: https://www.phoronix.com/news/Lenovo-Y700-Gen4-Linux-Patches
- IT之家: https://www.ithome.com/0/978/940.htm
- 虹墨空间站（9008/分区/fastboot 口实测）: https://www.imaegoo.com/2026/y700-tb322fc-flash-hyper/
