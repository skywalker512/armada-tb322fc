# diagnostics/

四代诊断工具落点（骨架）。优先搬/参考：

- freedom `devices/lenovo-tb323fu/diagnostics/`：`y700_runtime_record.py`（运行时记录）、
  `read_drm_crtc_properties.py`、`capture-ui-sync-trace.sh`、`analyze_mango_frames.py`、
  `analyze_ui_sync_trace.py` —— 多数与机型弱相关，参数化后即可用。
- xiaquwan1001 工作区的取证脚本：Q28 三态判据（NOCARD/STORM/GOOD）+ SSH 全量 dmesg
  采集、`softlockup_panic`+`ramoops` 自动取证（`#106` 用）。
