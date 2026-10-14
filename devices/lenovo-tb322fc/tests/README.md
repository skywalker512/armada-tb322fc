# tests/

四代回归测试落点（骨架）。

- 沿用 freedom `devices/lenovo-tb323fu/tests/` 的模式（`test_tb323fu_usb_port.py`、
  `test-tb323fu-speaker-gain.sh`、`test_y700_runtime_record.py`）按 tb322fc 命名。
- 首条测试应是冷启动显示三态判据（Q28 回归）：冷起后 SSH 判定
  card0 存在性 + cmd-DMA/DPU 风暴特征，输出 NOCARD/STORM/GOOD。
