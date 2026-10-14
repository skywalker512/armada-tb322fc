# TB322FC 内核基线

## 来源

- 源码 pin：`sources.json` → `h0cheung/tb322fc-linux-kernel @ 6f97250e`
  （上游 `GEEKiDoS/linux` 分支 `v7.2-elden`，基线 Linux 7.2，release 串 `7.2.0-y700+`）。
- 构建/验证流程：直接用 h0cheung umbrella 的 `scripts/fetch-sources.py` +
  `scripts/build-boot.sh`，产物 `boot.img`/`Image`/`sm8750-lenovo-elden.dtb`。
  不在本仓 vendor 内核源码。

## 本目录文件

| 文件 | 说明 |
|---|---|
| `cmdline.txt` | h0cheung 基线 cmdline。注意 `root=PARTLABEL=rootfs` + `init=/init` 是直通 initramfs 的写法；接入 bootc/btrfs 后 root/boot karg 由镜像 kargs.d 决定，此文件只留设备必需的项（`clk_ignore_unused`/`pd_ignore_unused`/`regulator_ignore_unused`/`initcall_blacklist=...`/`mem_sleep_default=s2idle` 等） |
| `kernel.config` | h0cheung 基线 config（12314 行）。已核对覆盖：btrfs/overlayfs/ext4、user ns/cgroup v2/PSI、uinput/uhid/hidraw、HID_{STEAM,SONY,MICROSOFT,NINTENDO,PLAYSTATION}、binderfs（Waydroid 就绪）、sched_ext、dma-heaps、ath12k、zram |
| `armada.config.fragment` | 叠加在基线上的 Armada 增量（初版见下，按 Armada 需求逐项审） |

## Armada 增量方向（TODO）

- `CONFIG_ZSWAP=y`（基线关闭；zram+swap 组合按需）
- FEX/Box64 友好项复核（大四栈、`CONFIG_COMPAT` 已 ✅）
- InputPlumber 虚拟手柄链路已具备（uinput/uhid/evdev ✅）
- SGSR/帧生成相关项跟随 enij90/freedom 的内核侧依赖核对
- Q28 相关：关注 xiaquwan1001 dossier 的修复动向，bump pin 时优先吸收

## 已验证范围（h0cheung validation.json @ kernel `b0c05eb7`）

78 项固件校验通过；显示 CRC 采样 32 组；前后摄各 16 帧；音频 30 段 PCM 采样；
accel/gyro/ALS 采样正常；非 rootfs UFS 分区只读校验通过。
