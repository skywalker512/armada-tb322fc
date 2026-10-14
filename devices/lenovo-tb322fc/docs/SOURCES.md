# TB322FC 组件来源与固定版本

## 发行版与板级

| 组件 | 来源 / 固定版本 |
|---|---|
| ArmadaOS 维护起点 | [armada-os/armada](https://github.com/armada-os/armada)，经 freedom 继承于 `887fd306b17b3060a70cc749e09630e1a640af14` |
| 本仓直接基底 | [mydanyi/armadaos-freedom](https://github.com/mydanyi/armadaos-freedom)，`2c8c433e806e5bc0a0e7195f450af305c1bca460` |
| 内核 umbrella（构建脚本/清单/流程来源） | [h0cheung/tb322fc-linux](https://github.com/h0cheung/tb322fc-linux)，2026-10-11 头 |
| 内核源码 | [h0cheung/tb322fc-linux-kernel](https://github.com/h0cheung/tb322fc-linux-kernel) `6f97250ead155fc3b980856323e99a4623dae73d`（上游 [GEEKiDoS/linux `v7.2-elden`](https://github.com/GEEKiDoS/linux/tree/v7.2-elden)） |
| 主线 DT 参照 | LKML `sm8750-lenovo-elden.dts` v2（Pengyu Luo, 2026-07-26） |
| G9 手柄 / RGB 参考 | [enij90/armada-tb321fu](https://github.com/enij90/armada-tb321fu) `62076530bf1ff34295d671016658965e54e597f1`（经 freedom 沿用） |
| 四代研究/踩坑库 | [xiaquwan1001/lenovo-legion-y700-gen4-tb322fc-elden-linux](https://github.com/xiaquwan1001/lenovo-legion-y700-gen4-tb322fc-elden-linux)（INDEX/TASKS/PITFALLS/Q28 dossier） |

`sources.json`、`firmware.json`、`kernel/`、`rootfs/`、`patches/` 的当前内容均来自
h0cheung/tb322fc-linux 上述 pin，作为起步快照；后续 bump 以该仓为准。

## kShimC 与打包器（沿用 freedom 的 pin，elden 适配在本仓 `boot/` 内做）

| 组件 | 来源 / 固定版本 |
|---|---|
| kShimC | [sunflower2333/kShimC `feature/2610`](https://github.com/sunflower2333/kShimC/tree/feature/2610)；freedom 快照归档 sha256 `3f8dc6d08e3945c874d8f1ab0789917db9781f62f77db98fecec547c6b9b1c5e`，另有 2026-10-14 许可同步（GPL-3.0-only + 删 FTM4） |
| 打包器 | [Project-Aloha/DualBootKernelPatcher `feature/2610`](https://github.com/Project-Aloha/DualBootKernelPatcher/tree/feature/2610)；上游基线 `2276163d066596cb0750e76cbfeec5c193b1779f`，本地基线 `aa819b0d1be76e83256f64cf77c0f6dfe4174eea` + `patches/boot/` 共享 PayloadFrom 修改 |
| Project-Aloha/CrDK | `b6c3335136b7f6b28271917de11e8f11982975fc`（需 `ports/crdk/` 补丁层） |
| picolibc | `f7edb0869e64b9d687f46961adeef7154921fe92` |
| LVGL | `7f07a129e8d77f4984fff8e623fd5be18ff42e74` |
| libfdt | 单独准备 `lib/libfdt` + `libfdt_env.h`（`.gitmodules` 不足以还原） |
| WenKai 菜单字体 | LXGW WenKai Regular v1.522，`e8b5b48b79f19f29aa68b0a178eab3472ea9f7e8`（OFL） |

## 用户态组件 pin（随内核 umbrella）

见 `sources.json`：libcamera `a6ef49cd`、hexagonrpc `598b591a`（+ `patches/hexagonrpc.patch`）、
libssc `54dd13e3`、audioreach-topology `e7b20b2b`、wireless-regdb `b488e68e`。

## 注意

- 固件二进制不进 Git（`firmware.json` 只是清单+哈希）；从自己的设备提取。
- 打包器补丁 `devices/lenovo-tb323fu/patches/boot/` 对 tb322fc 的适用性需逐个复核，
  不要无条件套用到 elden payload。
