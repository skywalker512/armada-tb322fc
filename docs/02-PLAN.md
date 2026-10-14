# 02 · 路线与待决策项

## 定位（调研后修正）

四代内核/板件层已有人做到 ~90%（h0cheung/GEEKiDoS 的 `tb322fc-linux` 系、
xiaquwan1001 的研究工作区）。**本项目的增量价值在发行版层**：ArmadaOS 的
bootc 镜像、游戏栈（Steam/FEX/Proton）、设备 overlay，以及保留 Android 的多启动方案。
不要重造内核层——直接 pin 并跟踪 h0cheung/tb322fc-linux-kernel（上游 GEEKiDoS/linux `v7.2-elden`）。

## 路线对比

### A. ArmadaOS 设备层（enij90 三代路径）

- fork armada，加 `devices/lenovo-tb322fc`（或顶层 `tb322fc/` 目录，参照
  armada-tb321fu 与 freedom 的目录组织）。
- 内核 pin 到 `v7.2-elden` 系 + 发行版所需 config 增量（FEX/Proton 对内核的要求：
  大页、namespace、手柄 udev 等，逐项对照 Odin 3 / tb321fu 的设备 config）。
- 已知短板：enij90 式安装擦整机 → 与 B 组合解决。

### B. kShimC 多启动（mydanyi freedom 路径）

- kShimC + STAR_CHART：Android / 内置 ArmadaOS / TF 卡 ArmadaOS / 高级启动。
- freedom 的 `devices/lenovo-tb323fu` 是结构模板；内核与固件换成 h0cheung pin。
- 开发期收益巨大：TF 卡先试，不动机身 Android。

### C. 纯 Arch/通用发行版

- h0cheung 的 CI 已能产 Arch Linux Ports Plasma 镜像——想先玩起来可以直接用他的产物，
  但不是本项目目标（目标是 SteamOS-like 游戏栈）。

**结论：A 的内容组织 + B 的启动方案 + h0cheung 的内核层。**

## 里程碑草案（已开始执行）

1. ~~吃透现有 bring-up~~ ✅ 2026-10-14：pin 表与起步文件已落 `devices/lenovo-tb322fc/`
   （`sources.json`/`firmware.json`/`kernel/`/`rootfs/`/`patches/`，来自 h0cheung pin）。
   另发现 h0cheung `packages/` 已是 Arch 版 Armada 用户态全套——bootc 集成时可对照。
2. **kShimC elden 适配**（进行中）：runtime 已可构建——`elden_defconfig`
   本机（aarch64-elf-gcc）与 CI（ubuntu aarch64-linux-gnu-gcc，`kshim-elden.yml`）
   均产出精确 4 MiB、无未解析符号的 `kShimC.bin`（hash 因编译器不同而异，见
   `boot/README.md`）。剩余：payload 打包（stock boot.img/DTB、avbtool、
   MultiBootKernelPatcher、UnpackTool 均为本地输入，不入库）→ `fastboot boot`
   验收菜单 → 定稿 ramoops/PMIC 参数。菜单触摸初版关闭（NT36536 驱动未移植），走 PMIC 按键。
3. **复现 baseline**：按 h0cheung 流程构建 `boot.img` + Arch rootfs，`fastboot boot` 验证；
   记录 Q28 复现率。
4. **ArmadaOS bootc 集成**：设备层已注册进 Armada 用户态——
   `system_files/usr/libexec/armada/device-env` 识别 elden model 字符串，
   `usr/lib/armada/devices/lenovo-tb322fc.conf`（SM8750 拓扑继承共享默认、
   NT36536 触摸、s2idle）、gamescope `lenovo.tb322fc.lcd.lua`（CSOT PP8807HB1）、
   InputPlumber `06-lenovo-tb322fc-legion-g9.yaml`（VID/PID 待真机复核）。
   已验证：device-env 解析正确、`controller-profile-test` 通过。
   剩余：bootc 镜像构建 + rootfs 件接线（`devices/lenovo-tb322fc/rootfs/`）。
5. **多启动验收**：kShimC STAR_CHART 出包 → Android 保留 + TF 卡 ArmadaOS。
6. **游戏栈验收**：Turnip 档位、Steam/FEX/Proton 冒烟、刷新率档、触控校准、G9、音频、挂起。

## 头号风险

- **Q28 冷启动显示竞态**（xiaquwan1001 定性：bonded 双 DSI 首条 DCS 的 cmd-DMA hang，
  三态判据 NOCARD/STORM/GOOD）。任何发行版都会撞上，跟进其 dossier，必要时参与修。
- `#106` 亮屏进桌面后整机冻结（无栈，取证手段已装未抓到）。
- 充电/电量上报问题未收口。

## 待决策 / 待验证

- [x] 内核基线 pin：h0cheung `v7.2.8-elden` 分支 `6f97250e`（Linux 7.2.8 之上 75 个 elden 提交；`v7.2-elden` 分支 tip `09e22021` 是较旧的 7.2 基线线）。
      已并入 Armada 通用内核（7.2.6）为 `packages/kernel/patches/0803-0850` + `dts/sm8750-lenovo-elden.dts`。
- [ ] h0cheung 与 xiaquwan1001 两条线的关系：是同组人的两份记录还是独立团队？
      前者概率大（时间点、术语一致性），需确认再决定跟踪谁。
- [ ] 与 h0cheung/xiaquwan1001 沟通：ArmadaOS 层是否有合作空间（至少同步 pin）。
- [ ] 主线补丁合入状态：v2 之后是否进 `qcom-next`；盯 linux-arm-msm。
- [x] ~~freedom 的 kShimC 是否已支持 SM8750 启动参数~~ → 已答：加 `elden_defconfig`
      + tlmm(216) 按键布局补丁即可，runtime 构建 PASS；真机启动行为仍待验证。
- [ ] testkey 漏洞在出厂较新 ZUI（>1.5.10.138）是否已修——决定「免解锁」还是「先解锁」。
- [ ] G9 手柄四代兼容性（VID/PID 是否仍为 `3537:1136`）。
- [ ] 屏供应商：国行是否全 CSOT PP8807HB1；Q28 是否与面板批次相关。
