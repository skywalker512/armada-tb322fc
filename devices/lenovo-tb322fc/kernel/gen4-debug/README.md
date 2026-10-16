# TB322FC（elden）调试启动镜像

给联想拯救者 Y700 四代（TB322FC，SM8750，代号 elden）用的 **DEBUG boot 镜像**。只允许 `fastboot boot` 进内存：内核把 initramfs 编进镜像（`CONFIG_BUILTIN_DTB=y`，引导程序的 initrd 不会被用到），init 在 USB CDC-ACM（`/dev/ttyGS0`）上打开一个 root shell。

这个 init **不会**挂载、写入、重新分区或格式化任何磁盘，也不会调用 reboot / poweroff。镜像里没有专有固件。

## 固定版本

| 输入 | 版本 |
|---|---|
| [h0cheung/tb322fc-linux](https://github.com/h0cheung/tb322fc-linux) | `234c49c274024ae53fd8ffca597954242dcd2b95`（`configs/kernel.config`、`configs/busybox.config`、`configs/cmdline.txt`） |
| [h0cheung/tb322fc-linux-kernel](https://github.com/h0cheung/tb322fc-linux-kernel) | `6f97250ead155fc3b980856323e99a4623dae73d`（checkout 后 `git write-tree` 必须是 `12bc91648dd3e0f9425152cea8ed010502efec51`） |
| BusyBox 1.36.1 | sha256 `b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314` |

## 构建

主机工具：clang / ld.lld / LLVM、`gcc-aarch64-linux-gnu`、`libc6-dev-arm64-cross`、python3、curl、flex、bison、bc、libssl-dev、libelf-dev、pahole（dwarves）、zstd。`mkbootimg` 不装发行版包；`build.sh` 从 AOSP 固定提交下载 `mkbootimg.py` 和 `gki/generate_gki_certificate.py`，校验 sha256 后用 python3 运行。

```console
./devices/lenovo-tb322fc/kernel/gen4-debug/build.sh
```

源码和中间文件放在仓库外的 `${WORK:-$HOME/gen4-build}`。`out/` 里会生成：

- `boot-gen4-debug.img.zst`（`zstd -19`，不进 git）
- `kernel.config`（olddefconfig 之后的配置）
- `SHA256SUMS`（未压缩的 boot.img、Image、.zst、kernel.config）
- `BUILD-INFO.txt`

二进制（`*.img`、`*.zst`、`Image`、`*.dtb`）由 `out/.gitignore` 排除。工作目录里还有未压缩的 `boot.img`、`Image` 和 `sm8750-lenovo-elden.dtb`。

## 在设备上使用

用平板 **长边** USB-C 口连接已解锁的 bootloader：

```console
zstd -d out/boot-gen4-debug.img.zst -o boot-gen4-debug.img
fastboot boot boot-gen4-debug.img
```

出现 USB 串口后：

- macOS：`screen /dev/cu.usbmodem* 115200`
- Linux：`screen /dev/ttyACM0 115200`

屏幕上每 10 秒打印一行 `ARMADA-DBG alive <uptime>`。主机关掉串口后，shell 会隔 1 秒重新拉起。
