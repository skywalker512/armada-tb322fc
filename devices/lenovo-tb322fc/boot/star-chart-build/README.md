# STAR_CHART 打包配方（elden / TB322FC）

沿用 freedom `devices/lenovo-tb323fu/boot/star-chart-build/` 的契约，
脚本已就位但**尚未用真机输入跑通过**——以下输入均需自行从设备/OTA 提取。

## 文件

| 文件 | 用途 |
|---|---|
| `build.sh` | `/work` 流水线：runtime → packer 准备 → QEMU manifest → boot 组装校验 |
| `build_offline_boot.py` | 八条目 manifest 组装与校验（条目名已改 TB322FC；`KSHIM_BOOT_SIZE` 可调 boot 分区大小，默认 96 MiB **待真机 GPT 核实**） |
| `repack_boot_v4.py` | boot v4 窄重打包（与 tb323fu 共用，设备无关） |
| `menu-required-text.txt` | 中英文菜单字形清单（WenKai 子集；菜单文案若改需重新生成） |

## 输入（`inputs/`，不入库）

| 输入 | 来源 |
|---|---|
| `boot-stock.img` | 原厂 boot 分区完整 dump（需等于 boot 分区大小） |
| `Image.stock` | stock boot 内的原始内核 Image |
| `Image.linux` | h0cheung `v7.2-elden` 系内核 Image |
| `internal.dtb` | Linux payload DTB，须含 `/chosen` 的 `armada,boot-stage="os"` |
| `tf.dtb` | TF 卡启动用 DTB（同 contract） |
| `avbtool.py` | AOSP avbtool（testkey 重签） |

## 打包器

`build.sh` 会把 [Project-Aloha/DualBootKernelPatcher `feature/2610`](https://github.com/Project-Aloha/DualBootKernelPatcher/tree/feature/2610)
克隆为 `source/` 的兄弟目录 `MultiBootKernelPatcher`，检出上游基线
`2276163d`，再用 `PATCHES_DIR`（默认 `/work/patches-boot`，可指向仓库
`devices/lenovo-tb323fu/patches/boot/`）施加 freedom 的本地基线 mbox
与共享 PayloadFrom 补丁。

## 验收门槛（evidence/）

`build.sh` 每步写 `evidence/<step>.log` + `.exit`。产物须通过
`build_offline_boot.py` 内置的 pack→unpack→repack 回读校验；
即便如此，`validation.json` 恒为 `hardware_tested:false`——
真机验收路径只能是 `fastboot boot`（**禁止直接刷分区**）：

- [ ] `fastboot boot boot-candidate/…img` 进入 STAR_CHART 菜单
- [ ] 菜单按键导航（PMIC 键；触摸驱动未移植）
- [ ] Android 条目 → 回原厂系统
- [ ] 机身 ArmadaOS 条目 → Linux 内置启动
- [ ] TF 卡 ArmadaOS 条目 → TF 启动
- [ ] 高级启动各动作（诊断/Recovery/Fastboot/9008）逐项验收后再标可用
