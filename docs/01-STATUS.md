# 01 · 硬件功能状态矩阵（TB322FC / SM8750 / elden）

来源：主线补丁 v2（2026-07-26）、Phoronix 报道、sunflower2333/linux、ll1zt droidspaces 内核实测、
三代移植已知差异。截至 2026-10-14，均未在本仓库验证。

| 功能 | 主线（+elden DT） | 下游/社区树 | Android 侧实测 | 备注 |
|---|---|---|---|---|
| 按键（电源/音量） | ✅ | ✅ | — | DT 内 gpio-keys |
| USB-C ×2（数据） | ✅ | ✅ | — | 双口路由；仅长边口进 fastboot/9008 |
| USB altmode / DP 外显 | 部分（altmode ✅） | ? | — | 三代 DP 外显可用但无声 |
| 充电 / 电量计 | ✅ | ✅ | — | DT 内 charger/fuel gauge |
| framebuffer 显示 + 背光 | ✅ | ✅ | — | simplefb 级；DSI 面板驱动已上游（v2 起接 panel 节点） |
| 面板 165 Hz / VRR | ❌ | ? | Android 正常 | 三代只做了 BOE；四代主线 DT 是 CSOT `pp8807hb1-1`，需确认屏供应商 |
| GPU（Adreno 830 / Turnip） | ❌（Mesa 侧推进中） | ✅ 下游 | ✅ glmark2 2714（ll1zt 树） | Turnip on SM8750 已被 Odin 3 验证 |
| 触摸屏（NT36536） | ❌ | ✅ 下游 | Android 正常 | 需 nt36xxx/下游驱动移植 |
| Wi-Fi / BT | ❌ | ❌（报道口径） | Android 正常（cnss2） | 高通远端固件 + board 数据是常见卡点 |
| 扬声器 / 音频拓扑 | ❌ | ? | Android 正常 | 参考 tb321fu/armadaos-freedom 的 audio_topology |
| 麦克风 | ❌ | 仅下游 | — | — |
| 传感器 / 马达 | ❌ | 仅下游 | — | — |
| 摄像头 | ❌ | ❌ | Android 正常 | 优先级最低 |
| 挂起 / 续航 | ? | ? | — | Armada 上游近期在修 Odin 3 sleep |
| microSD | ?（DT 有 SDHCI） | ? | Android 正常 | TF 卡启动是 freedom 方案关键 |
| G9 2026 手柄 / RGB | ❌ | freedom 在 tb323fu 上做了匹配 `3537:1136` | — | 四代是否同款 G9 待确认 |

## 启动链事实（已验证）

- BL 可解锁；且 **ZUI ≤ 1.5.10.138 的启动链由公开 AOSP testkey 签名**——自签 boot 镜像可过 AVB，
  配合 EDL(9008) 不解锁刷写（ll1zt、polygraphene 均已验证）。
- 9008 端口未加密（ROM乐园/虹墨教程口径）；LTBox 对 TB322FC 支持完整（root、分区写、救砖）。
- 分区：UFS 6 LUN，A/B 槽；boot / vendor_boot / init_boot / dtbo / recovery 分离。
- fastboot / 9008 只认长边 USB-C 口。
