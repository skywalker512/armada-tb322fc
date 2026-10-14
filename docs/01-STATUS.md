# 01 · 硬件功能状态矩阵（TB322FC / SM8750 / elden）

来源：主线补丁 v2（2026-07-26）、**h0cheung/tb322fc-linux 实测表**（kernel pin `6f97250e` @ `v7.2.8-elden`，2026-10-11）、
xiaquwan1001 工作区（Q28/Q24/#106 记录）。比 Phoronix 报道时点的状态新很多——下游树已点亮大半。

| 功能 | 主线 | h0cheung/GEEKiDoS 下游树（真机） | 备注 |
|---|---|---|---|
| Kernel / UFS | ✅（elden DT 在审） | ✅ Linux 7.2 + ext4 rootfs | `GEEKiDoS/linux@v7.2-elden` |
| 按键 | ✅ | ✅ | — |
| 显示 | 补丁含 DSI/panel 节点 | ✅ 24/40/60/90/120/144/165 Hz | **冷启动竞态 Q28 未解决**（双 DSI bonded 首条 DCS cmd-DMA hang，NOCARD/STORM/GOOD 三态）；xiaquwan1001 另有 `#106` 亮屏后整机冻结记录 |
| 触摸 | ❌ | ✅ Novatek NT36536 | 面板实为 CSOT PP8807HB1 + NT36536（与三代 BOE-only 不同局面） |
| GPU（Adreno 830） | ❌ | ✅ Mesa Turnip + Zink | Turnip on SM8750 亦经 Odin 3 验证 |
| Wi-Fi | ❌ | ✅ Qualcomm Peach / ath12k | — |
| 蓝牙 | ❌ | ✅ QCA UART 固件加载 + 配对（h0cheung 复核通过） | — |
| 扬声器 | ❌ | ✅ AW88461 + AudioReach tplg/UCM | — |
| 内置麦克风 | ❌ | ✅ AMIC1/AMIC4 via WCD9395 | — |
| 触觉 | ❌ | ✅ 双 AW86927 系，FF replay | — |
| 传感器（ADSP/SSC） | ❌ | ✅ 需 patched hexagonrpc / iio-sensor-proxy | patches/ 里有现成补丁 |
| 摄像头 | ❌ | ⚠️ 前后摄可出流，应用/调优未完 | xiaquwan1001: 与熄屏互斥（Q24），日常按需加载 |
| 挂起 | ❌ | ✅ s2idle（USB 挂起唤醒）；hibernate 未测 | GEEKiDoS 早期版本曾标 unreliable，h0cheung 已复核为 working |
| 电池/充电 | ⚠️ DT 有 charger/fg | ⚠️ 充电唤醒与上报仍有问题 | — |
| DisplayPort 外显 | altmode ✅ | xiaquwan1001 记 ✅ | 音频待验 |
| G9 2026 手柄/RGB | — | 未见四代适配 | freedom 在 tb323fu 上做了 `3537:1136`，四代待确认 |

## 启动链事实（已验证）

- BL 可解锁；且 **ZUI ≤ 1.5.10.138 的启动链由公开 AOSP testkey 签名**——自签 boot 镜像可过 AVB，
  配合 EDL(9008) 不解锁刷写（ll1zt、polygraphene 均已验证）。
- 9008 端口未加密（ROM乐园/虹墨教程口径）；LTBox 对 TB322FC 支持完整（root、分区写、救砖）。
- 分区：UFS 6 LUN，A/B 槽；boot / vendor_boot / init_boot / dtbo / recovery 分离。
- fastboot / 9008 只认长边 USB-C 口。
- h0cheung 工作流约定：**用 `fastboot boot` 试内核，不写分区**；固件从自己机器提取（firmware.json 哈希清单）。
