#!/bin/bash
# diy-part1: 在 feeds update 之前执行, 主要加第三方源
# 工作流调用位置: openwrt/ 目录下
set -e

# kenzok8 的 honk 源 (2026-11 仍在日更): honk = dae 的 Rust 重写版, eBPF 内核态分流,
# 核心自带 doona Web 面板。提供: honk(预编译 aarch64 核心) + luci-app-honk(+zh-cn 翻译)
# 2026-11-17 起取代 kenzok8/openwrt-daede (dae + daed + luci-app-daede), daed 已停更
if ! grep -q "openwrt-honk" feeds.conf.default; then
  echo 'src-git honk https://github.com/kenzok8/openwrt-honk.git' >> feeds.conf.default
fi

cat feeds.conf.default
