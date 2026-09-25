#!/bin/bash
# diy-part2: 在 feeds install 之后、copy .config 之前执行
# 工作流调用位置: openwrt/ 目录下
# 主要做: 主机名、IP、版本标识等轻量定制, 不动内核

# 1. 默认 LAN IP 改成 192.168.100.1
sed -i 's/192\.168\.1\.1/192.168.100.1/g' package/base-files/files/bin/config_generate
if ! grep -q '192\.168\.100\.1' package/base-files/files/bin/config_generate; then
  echo "ERROR: LAN 默认 IP 192.168.100.1 未生效" >&2; exit 1
fi

# 2. 默认主机名 -> NatserverWrt (LuCI 登录窗口/浏览器标签页标题都取 hostname)
sed -i "s/hostname='[^']*'/hostname='NatserverWrt'/g" package/base-files/files/bin/config_generate
if ! grep -q "hostname='NatserverWrt'" package/base-files/files/bin/config_generate; then
  echo "ERROR: hostname NatserverWrt 未生效" >&2; exit 1
fi

# 3. 固件名 -> NatserverWrt (CONFIG_VERSION_DIST 符号不存在, 改 version.mk 的兜底值;
#    影响镜像文件名前缀 + DISTRIB_ID + openwrt_release 的 %D 显示)
sed -i 's/\$(VERSION_DIST),OpenWrt)/$(VERSION_DIST),NatserverWrt)/' include/version.mk
if ! grep -q '$(VERSION_DIST),NatserverWrt)' include/version.mk; then
  echo "ERROR: VERSION_DIST NatserverWrt 未生效" >&2; exit 1
fi

# 4. 固件版本描述 (LuCI 概览/登录窗口的 Firmware Version)
if [ -f package/base-files/files/etc/openwrt_release ]; then
  echo "DISTRIB_DESCRIPTION='NatserverWrt snapshot + daed (RE-SS-01)'" >> package/base-files/files/etc/openwrt_release
fi

# 4. 确保 golang 版本足够新 (dae 需要 go 1.21+), feeds 自带一般够, 这里只打印确认
./scripts/feeds list | grep -E "^(dae|daed|luci-app-daede|vmlinux-btf|v2ray-geo)" || echo "WARN: dae 相关 feed 未列出, 请检查 diy-part1 是否生效"

# 5. RE-SS-01 内核分区扩到 12M (照抄 istoreos 方案: HLOS12M GPT + U-Boot /big.html)
#    只改 Device/jdcloud_re-ss-01 块, 不动 re-cs-02/re-cs-07/nn6000 的 6144k
sed -i '/^define Device\/jdcloud_re-ss-01$/,/^endef$/s/KERNEL_SIZE := 6144k/KERNEL_SIZE := 12288k/' target/linux/qualcommax/image/ipq60xx.mk
if ! sed -n '/^define Device\/jdcloud_re-ss-01$/,/^endef$/p' target/linux/qualcommax/image/ipq60xx.mk | grep -q 'KERNEL_SIZE := 12288k'; then
  echo "ERROR: RE-SS-01 KERNEL_SIZE 12288k 补丁未生效 (上游块结构变了?)" >&2
  exit 1
fi
if [ "$(grep -c 'KERNEL_SIZE := 12288k' target/linux/qualcommax/image/ipq60xx.mk)" != "1" ]; then
  echo "ERROR: 12288k 出现次数不是 1, 可能误改了其他设备" >&2
  exit 1
fi
echo "OK: RE-SS-01 KERNEL_SIZE := 12288k"

echo "diy-part2 done"
