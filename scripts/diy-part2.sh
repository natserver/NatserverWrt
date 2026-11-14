#!/bin/bash
# diy-part2: 在 feeds install 之后、copy .config 之前执行
# 工作流调用位置: openwrt/ 目录下
# 主要做: 主机名、IP、版本标识等轻量定制, 不动内核

# 1. 默认 LAN IP 改成 192.168.100.1
sed -i 's/192\.168\.1\.1/192.168.100.1/g' package/base-files/files/bin/config_generate
if ! grep -q '192\.168\.100\.1' package/base-files/files/bin/config_generate; then
  echo "ERROR: LAN 默认 IP 192.168.100.1 未生效" >&2; exit 1
fi

# 2. 默认主机名 -> NatserverWrt (顶栏侧边品牌等取 hostname)
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

# 6. 浏览器标签页标题 + 登录窗口大标题 (fanchmwrt 主题硬编码 FanchmWrt, 与 hostname 无关)
sed -i 's|<title>FanchmWrt</title>|<title>NatserverWrt</title>|' package/fcm/luci-theme-fanchmwrt/ucode/template/themes/fanchmwrt/header.ut
if ! grep -q '<title>NatserverWrt</title>' package/fcm/luci-theme-fanchmwrt/ucode/template/themes/fanchmwrt/header.ut; then
  echo "ERROR: 浏览器标签 <title>NatserverWrt</title> 未生效 (header.ut 结构变了?)" >&2; exit 1
fi
sed -i "s/'FanchmWrt'/'NatserverWrt'/" package/fcm/luci-theme-fanchmwrt/htdocs/luci-static/resources/view/fanchmwrt/sysauth.js
if ! grep -q "'NatserverWrt'" package/fcm/luci-theme-fanchmwrt/htdocs/luci-static/resources/view/fanchmwrt/sysauth.js; then
  echo "ERROR: 登录窗口标题 NatserverWrt 未生效 (sysauth.js 结构变了?)" >&2; exit 1
fi
if grep -q "'FanchmWrt'" package/fcm/luci-theme-fanchmwrt/htdocs/luci-static/resources/view/fanchmwrt/sysauth.js; then
  echo "ERROR: sysauth.js 仍残留 'FanchmWrt'" >&2; exit 1
fi
echo "OK: 标签页/登录窗口标题 -> NatserverWrt"

# 7. 放开 GOTOOLCHAIN (2026-11-13 run 43382238766 失败的直接原因)
#    上游 dae/daed 的 go.mod 已经写成 `go 1.27.0`, 而 26.05 分支固定的 packages feed
#    只到 golang 1.26.3 (GO_DEFAULT_VERSION:=1.26, 没有 golang1.27 包); 更关键的是
#    golang-package.mk 的 GO_PKG_BUILD_VARS 里硬编码 GOTOOLCHAIN=local, 于是 go 拒绝
#    自动升级工具链, 直接报:
#      go: go.mod requires go >= 1.27.0 (running go 1.26.3; GOTOOLCHAIN=local)
#    改成 auto 后 1.26.3 会按需从 module proxy 拉 go1.27.x 工具链来编 dae/daed,
#    其余 Go 包仍旧用 1.26.3, 不用动 packages feed 的版本, 改动面最小。
GPM=feeds/packages/lang/golang/golang-package.mk
if [ ! -f "$GPM" ]; then
  echo "ERROR: 找不到 $GPM (feeds install 未完成?)" >&2; exit 1
fi
if grep -q 'GOTOOLCHAIN=local' "$GPM"; then
  sed -i 's/GOTOOLCHAIN=local/GOTOOLCHAIN=auto/g' "$GPM"
fi
if ! grep -q 'GOTOOLCHAIN=auto' "$GPM"; then
  echo "ERROR: GOTOOLCHAIN=auto 补丁未生效 ($GPM)" >&2; exit 1
fi
echo "OK: GOTOOLCHAIN -> $(grep -o 'GOTOOLCHAIN=[a-z]*' "$GPM" | head -1)"

echo "diy-part2 done"
