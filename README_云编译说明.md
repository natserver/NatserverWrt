# FanchmWrt RE-SS-01 + daed 云编译工程

本目录是一个**云编译脚手架**, 不是 fanchmwrt 源码本身。
推送到你自己的 GitHub 仓库后, GitHub Actions 会自动:
1. 拉取 `fanchmwrt/fanchmwrt-snapshot:fanchmwrt-26.05` 官方源码
2. 加入 `kenzok8/openwrt-daede` 源 (dae / daed / luci-app-daede)
3. 按 `config/re-ss-01-daed.config` 编译 **JDCloud RE-SS-01 (qualcommax/ipq60xx)** 固件
4. 内核已打开 dae 必需项: `DEBUG_INFO_BTF / BPF_EVENTS / XDP_SOCKETS`
5. 固件内置 daed, 另附 dae/daed 的 ipk/apks

> 你的机型在截图里是 `snapshot-1.0.4`, 所以必须用 snapshot 源, 不能用稳定版 `fanchmwrt-25.12`。

## 目录结构

```
.github/workflows/build.yml   GitHub 云编译工作流
config/re-ss-01-daed.config   RE-SS-01 的 .config (target + daed + 内核 BTF)
scripts/diy-part1.sh          加 daed 第三方源
scripts/diy-part2.sh          主机名/版本小定制
```

## 一键推送触发编译 (Windows PowerShell)

```powershell
cd "C:\Users\Administrator\Desktop\ax1800pro项目\fanchmwrt"

# 1. 初始化 git (本目录现在是空文件夹, 第一次需要)
git init
git add .
git commit -m "RE-SS-01 + daed cloud build"

# 2. 在 github.com 新建一个私有仓库, 例如 fanchmwrt-re-ss-01-daed, 不要勾 README
# 3. 关联并推送 (把 YOUR_GITHUB_NAME 换成你自己的)
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_NAME/fanchmwrt-re-ss-01-daed.git
git push -u origin main
```

推送完成后:
- 打开仓库页面 → `Actions` → `Build FanchmWrt RE-SS-01 + daed` → 等 2-4 小时
- 编完后在该次运行底部 `Artifacts` 下载 `fanchmwrt-re-ss-01-daed`
- 里面有:
  - `*re-ss-01*squashfs-factory.bin` (不死 uboot 首次刷机用)
  - `*re-ss-01*squashfs-sysupgrade.bin` (fanchmwrt 页面升级用)
  - `dae_*.apk / daed_*.apk / luci-app-daede_*.apk` (备用离线安装包)

发正式版:
```powershell
git tag v1.0
git push origin v1.0
# 会自动建一个 Release, 固件直接挂在 Release 下
```

## 刷机顺序 (和官方截图一致)

1. 不死 uboot 先刷 `factory.bin`
2. 进 fanchmwrt (192.168.1.1 / root / password) 页面再升级 `sysupgrade.bin`
3. 注意截图里的红字警告: 1.0.3 → 1.0.4 保配置升级前先卸载用户连接数和 DPI Pro 模块

## daed 使用说明

- 固件已内置 `daed`, 启动后访问 `http://192.168.1.1:2023` (daed 默认端口)
- LuCI 里也有 `服务 → daed` (包名可能是 daede, 同一个东西)
- 依赖已内置: `ca-bundle, kmod-sched-bpf, kmod-veth, v2ray-geoip/geosite, nft/tproxy`
- rootfs 已放到 300MB, 不会因为 daed 22MB 单体导致空间不足

### 如果云编译失败 (常见坑)

1. `dae` 编译报 Go / clang 错误 → 在 Actions 日志搜 `error:`, 一般是 snapshot 源码那天坏了, 第二天重跑即可 (snapshot 非稳定版正常现象)
2. `luci-app-daede` 找不到 → feed 改名了, 把 `scripts/diy-part1.sh` 里注释掉的 QiuSimons 源打开再推一次
3. 固件超过 GitHub Artifact 2GB 上限 → 不可能, RE-SS-01 单机型只有几十 MB
4. 想只拿 ipk 不进固件: 把 `config/re-ss-01-daed.config` 里 `CONFIG_PACKAGE_dae=y` 改成 `=m`, 重推即只产出安装包

### 你本地已有的离线方案 (不用重编也能跑 daed)

你 `ax1800pro项目` 目录下已经有:
- `25-luci-app-dead_1.28-aarch64_cortex-a53.run` (自解压包)
- `luci-app-run-1.0.0-r9.apk`

这是 wkccd 的 run 离线安装路线, 在官方 1.0.4 固件上:
```sh
# 上传 run 文件到 /tmp 并执行
chmod +x /tmp/25-luci-app-dead_1.28-aarch64_cortex-a53.run
/tmp/25-luci-app-dead_1.28-aarch64_cortex-a53.run
./install.sh
```
云编译是更干净的一体固件路线, 二选一即可, 云编译的固件不需要再装 run 包。

## 源码出处 (保留版权信息)

- https://github.com/fanchmwrt/fanchmwrt-snapshot (branch fanchmwrt-26.05)
- https://github.com/kenzok8/openwrt-daede (dae/daed feed)
- https://github.com/daeuniverse/daed
- 上游 https://github.com/openwrt/openwrt
