# elden kShimC 移植备忘（已核对的硬数据）

数据来源：主线 `sm8750-lenovo-elden.dts` v2（LKML 补丁）+ sunflower2333/linux
`sm8750.dtsi` + kShimC `feature/2610` 源码通读。尚未从真机 fdt 复核。

## 按键/TLMM（菜单输入的必需路径）

- TLMM：`compatible = "qcom,sm8750-tlmm"`，`reg = <0x0 0x0f100000 0x0 0x102000>`，
  `gpio-ranges = <&tlmm 0 0 216>` → **GPIO 数 216**。
- `kshim dt/keys.c` 的 `Layouts[]` 目前只认 `qcom,sm8450-tlmm`/`qcom,sm8550-tlmm`
  （各 210）——需要加 `{"qcom,sm8750-tlmm", 216U}`。
- elden 的实际按键走 **PMIC 路径**而非 TLMM：
  - `gpio-keys` → `key-volume-up` = `&pm8550_gpios 6 GPIO_ACTIVE_LOW`
  - `&pon_resin` → `KEY_VOLUMEDOWN`；电源键走 pon。
  keys.c 的 `qcom,pm*`/`qcom,spmi*` 兼容匹配应能直接命中，重点是 SPMI
  寄存器解析（`kshim_dt_spmi_reg`/`kshim_dt_spmi_identity`）对 pm8550 系列成立。
- `kshim_dt_soc()`（`dt/gpio.c`）只识别 8150/8250 → `CrAndroidPin` 布局表
  （CrDK `Library/cr_android.h`）无 sm8750 条目。**初版不需要**：PMIC 按键路径
  不经过 TLMM pin 布局表；只有当菜单要用 TLMM GPIO（如面板背光复位）时才需要
  为 sm8750 补 pin/function 表。

## 显示（菜单渲染）

- kShimC 用 `qcom,sde-kms` DT 节点找 splash/framebuffer（`dt/splash.c`），
  **复用 bootloader 已点亮的画面缓冲，不自行初始化 DSI**——elden 的 bonded
  双 DSI 复杂性（Q28）不影响菜单。
- 原生扫出 1904×3040（dtb 内核侧亦同），`KSHIM_UI_ROTATION_CCW=270` 与
  `KSHIM_LVGL_BUFFER_BYTES=243712`（20 行 × 3040px）沿用 tb323fu 设定；
  若 stock splash 的 framebuffer stride 不同需按实测调整。
- 冷知识：Q28 是 **Linux 内核 DSI 重新初始化**时的竞态；kShimC 菜单不碰它，
  但选 Linux payload 后内核自己仍会撞——菜单里加一个「Linux 启动尝试计数/
  上次启动状态」显示对调试 Q28 很有帮助（可选增强）。

## 电源/复位

- `qcom_reboot.c` + PMIC `pon` 路径通用；高级菜单的 9008/fastboot/recovery
  动作用的是标准 reboot 原因码，elden 应直接可用（需真机验证各模式入口）。

## ramoops / 保留内存

- freedom 快照里的 `src/dt/tb323fu_ramoops*.c` 是 tb323fu 专属文件
  （上游 feature/2610 不含）。elden 需要自己的版本：从真机 `/proc/iomem` +
  stock fdt 的 `reserved-memory` 提取 ramoops/pstore 区域后实现对应导出。
  **当前阻塞项**：需要 root 后的设备 dump。

## Wi-Fi（顺带记录，给 Linux payload 侧）

- elden Wi-Fi 是 **PCIe** 挂的 ath12k（`&pcie0` 下 `pci17cb,1107`，
  wake-gpio tlmm 104 / reset-gpio tlmm 102）——不是 SDIO。h0cheung 树已验证
  Peach 固件可用。
