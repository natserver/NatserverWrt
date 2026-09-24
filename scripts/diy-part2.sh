#!/bin/bash
# diy-part2: 在 feeds install 之后、copy .config 之前执行
# 工作流调用位置: openwrt/ 目录下
# 主要做: 主机名、IP、版本标识等轻量定制, 不动内核

# 1. 默认 LAN IP 改成 192.168.1.1 (和官方截图一致), 如需改自己改这里
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 2. 主机名
sed -i 's/OpenWrt/FanchmWrt-RE-SS-01/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 3. 在固件名里加上 daed 标识, 方便区分官方版
# snapshot 的 version 文件位置可能不同, 有就改, 没有就跳过
if [ -f package/base-files/files/etc/openwrt_release ]; then
  echo "DISTRIB_DESCRIPTION='FanchmWrt snapshot + daed (RE-SS-01)'" >> package/base-files/files/etc/openwrt_release
fi

# 4. 确保 golang 版本足够新 (dae 需要 go 1.21+), feeds 自带一般够, 这里只打印确认
./scripts/feeds list | grep -E "^(dae|daed|luci-app-daede|vmlinux-btf|v2ray-geo)" || echo "WARN: dae 相关 feed 未列出, 请检查 diy-part1 是否生效"

echo "diy-part2 done"
