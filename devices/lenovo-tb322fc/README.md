# Lenovo Legion Y700 Gen 4 / TB322FC（elden）

本目录是 ArmadaOS 的 TB322FC / SM8750 平板适配目录，结构沿用
[`devices/lenovo-tb323fu`](../lenovo-tb323fu)（freedom 五代适配）的组织方式。
组件来源与固定版本见 [docs/SOURCES.md](docs/SOURCES.md)；整仓调研见
[顶层 docs/00-RESEARCH.md](../../docs/00-RESEARCH.md)。

**状态：骨架阶段。** 内核与用户态设备文件以 h0cheung/tb322fc-linux 的固定版本为基底
搬运进来（见下）；尚未与 ArmadaOS 的 bootc 构建集成，也不能直接刷机。

## 与现成工作的分工

- **内核/板件层**：不自建。pin 到 `h0cheung/tb322fc-linux-kernel`
  （fork 自 `GEEKiDoS/linux` 的 `v7.2-elden` 分支），pin 值见 `sources.json`。
- **用户态设备配置**：`rootfs/` 起步文件同样来自 h0cheung（UCM2、传感器、电源、
  散热、摄像头规则），需要逐个核对并接入 ArmadaOS 的 system_files / packages 层。
- **本仓新增的工作**：ArmadaOS bootc 集成、kShimC 多启动的 elden 设备定义、
  安装/回退流程。

## 目录

| 路径 | 内容 |
|---|---|
| `sources.json` | 内核及用户态组件 pin（h0cheung 格式） |
| `firmware.json` | 需从本机原厂系统提取的固件清单（78 项，含 sha256） |
| `kernel/` | 内核基线说明、cmdline、`kernel.config`、Armada 增量 fragment |
| `boot/` | kShimC elden 移植说明与 STAR_CHART 构建骨架 |
| `rootfs/` | 设备用户态配置（audio/sensors/power/thermald/camera） |
| `patches/` | libcamera / hexagonrpc 补丁（h0cheung 维护版） |
| `diagnostics/`、`tests/` | 诊断与回归测试（骨架） |

## 头号风险

`Q28` 冷启动显示竞态（bonded 双 DSI 首条 DCS cmd-DMA hang，
三态判据 NOCARD/STORM/GOOD），以及 `#106` 亮屏进桌面整机冻结——
详见 xiaquwan1001 工作区的 INDEX/TASKS/PITFALLS。kShimC 菜单本身跑在
bootloader 初始化的 framebuffer 上不受影响，但 Linux payload 每次冷起都会撞 Q28。
