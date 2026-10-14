# 02 · 候选路线与待决策项

## 路线对比

### A. 参照三代：fork armada + `tb322fc/` 设备目录（enij90 路径）

- 结构照抄 `armada-tb321fu`：设备 overlay、audio_topology、disk_config、post_process。
- 启动：stock/vendor ABL + Android boot 镜像；四代可额外利用 testkey 签名（免解锁）。
- 优点：先例完整、与上游 bootc 架构一致；缺点：安装即擦 Android（除非接 B 的 kShimC）。

### B. 参照 freedom：kShimC 多启动（mydanyi 路径）

- kShimC + STAR_CHART 菜单：Android / 内置 ArmadaOS / TF 卡 ArmadaOS / 高级启动。
- freedom 的 tb323fu 目录结构（boot/kernel/rootfs/patches/diagnostics/tests）可直接当模板；
  SM8850P→SM8750 的内核与固件差异要逐块替换。
- 优点：保留 Android、TF 卡先试错；缺点：kShimC 本身要适配 elden 的引导参数。

### C. 纯主线 + 通用发行版（Fedora/postmarketOS 路线）

- 等/推主线 DT 合入，用 pmOS 或 Fedora aarch64 通用镜像 + 自打包内核。
- 优点：最干净、可反哺主线；缺点：离「能打游戏」最远，Wi-Fi/音频都缺。

**倾向：B 为主（双系统 + TF 卡开发期），A 的设备 overlay 组织方式做内容来源。**
第一步不必决定死——先把 TF 卡能点亮为主线内核 + 简单 rootfs。

## 里程碑草案

1. **设备指纹收集**：root 后抓 `/proc/config.gz`、`/sys/firmware/fdt`、`/proc/iomem`、
   面板/触控实际型号（确认 CSOT vs BOE）、固件清单。（依赖 ll1zt 方案或 TWRP）
2. **TF 卡起主线**：主线 + elden DT + initramfs，串口/ framebuffer 验证点亮。
3. **下游补齐**：触摸、Turnip、Wi-Fi（cnss2 固件/board-2）、音频拓扑。
4. **kShimC 双启动**：Android 保留 + ArmadaOS rootfs 进 userdata 子卷或 TF。
5. **ArmadaOS 集成**：bootc 镜像 + 设备 overlay（刷新率档、触控校准、G9、音频、挂起）。

## 待决策 / 待验证

- [ ] 屏供应商：国行 TB322FC 是否全是 CSOT `pp8807hb1-1`？有无 BOE 版本？（决定面板驱动工作量）
- [ ] 主线补丁合入状态：v2 之后是否进 `qcom-next`；盯 linux-arm-msm。
- [ ] SM8750 GPU：Turnip 对 Adreno 830 的支持分支（Mesa devel / WinNative Turnip 构建）。
- [ ] Wi-Fi 固件：ZUXOS 里 cnss2 所用 BDF / fw 版本，能否直接搬。
- [ ] freedom 的 kShimC 是否已支持 SM8750 启动参数，或需给 elden 加设备定义。
- [ ] G9 手柄四代兼容性（VID/PID 是否仍为 `3537:1136`）。
- [ ] testkey 漏洞在出厂较新 ZUI（>1.5.10.138）是否已修——决定「免解锁」还是「先解锁」。
