# STAR_CHART 构建骨架（elden）

沿用 freedom `devices/lenovo-tb323fu/boot/star-chart-build/` 的配方约定，
本目录暂不含可一键出包流程——先把 kShimC 源码 pin 与 elden 设备文件层定下来。

## 预期工作区（容器内）

```text
/work/
  source/                 # sunflower2333/kShimC feature/2610 + 固定依赖
                          # (CrDK b6c33351 + ports/crdk 补丁、picolibc f7edb086、
                          #  lvgl 7f07a129、lib/libfdt)
  overlay/elden/          # 本仓 boot/kshim-elden/：elden_defconfig、
                          # elden_ramoops*.c、设备专属 dt 片段
  inputs/
    boot-stock.img        # 原厂 boot（自行从设备/OTA 包提取）
    Image.stock
    Image.linux           # v7.2-elden 内核 Image
    tf.dtb / internal.dtb # elden payload dtb（TF / 内置 两种启动目标）
    avbtool.py
  out/
```

## 与 tb323fu 流程的差异

- runtime 槽位 4 MiB 限制不变；elden boot 分区大小按 stock `boot-stock.img` 实测核对。
- 菜单 manifest 条目改 elden 语义：Android(ZUXOS) / ArmadaOS 内置 / ArmadaOS TF /
  高级启动（Linux 诊断、Recovery、Fastboot、9008）。
- `menu-required-text.txt` 字形清单按新文案重新生成（WenKai 子集）。
- 打包器：DualBootKernelPatcher feature/2610 + freedom `patches/boot/` 的共享
  PayloadFrom 修改；对 elden 的 Android payload 结构（GKI2 vendor_boot 分离、
  init_boot）逐项核对后再用。

## TODO

- [ ] 真机取输入（见 `../README.md`）
- [x] `elden_defconfig` + `../fetch-kshim.sh` + `../kshim-elden/patches/`
      runtime 构建冒烟 **本机已 PASS**（4 MiB 精确、无未定义符号；
      macOS aarch64-elf-gcc 经 0002 env 覆盖补丁）。
      CI 冒烟同走 `.github/workflows/kshim-elden.yml`；跑通后回填 `KSHIM_COMMIT` sha
- [ ] QEMU manifest 流程对 elden 复用（`tests/manifest_qemu.py`）
- [ ] boot v4 重打包结构对 TB322FC boot.img 验证（`repack_boot_v4.py`）
