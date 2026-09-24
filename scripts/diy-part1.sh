#!/bin/bash
# diy-part1: 在 feeds update 之前执行, 主要加第三方源
# 工作流调用位置: openwrt/ 目录下

# kenzok8 的 dae/daed 源 (2026 年仍在维护 snapshot/apk, 有 aarch64_cortex-a53 预编译, 也支持从源码编)
# 提供: dae daed luci-app-daede vmlinux-btf
if ! grep -q "openwrt-daede" feeds.conf.default; then
  echo 'src-git daede https://github.com/kenzok8/openwrt-daede.git' >> feeds.conf.default
fi

# 可选: QiuSimons 的 luci-app-daed (经典名, 如果 kenzok8 的包名对不上可互补)
# 默认注释掉, 需要时打开
# if ! grep -q "luci-app-daed" feeds.conf.default; then
#   echo 'src-git daed_luci https://github.com/QiuSimons/luci-app-daed.git' >> feeds.conf.default
# fi

cat feeds.conf.default
