# FanchmWrt RE-SS-01 + daed 云编译工程

本目录是一个**云编译脚手架**, 不是 fanchmwrt 源码本身。
GitHub Actions 的工作方式:
1. **只在官方源码有更新时才构建**: 每 6 小时检查 `fanchmwrt/fanchmwrt-snapshot:fanchmwrt-26.05` 最新提交, 和已有 Release 记录的上游 SHA 比对, 无更新直接跳过; **本仓库的 push 不触发构建**
2. 构建时拉取官方源码 + `kenzok8/openwrt-daede` 源 (dae / daed / luci-app-daede)
3. 按 `config/re-ss-01-daed.config` 编译 **JDCloud RE-SS-01 (qualcommax/ipq60xx)** 固件
4. 内核已打开 dae 必需项: `DEBUG_INFO_BTF / BPF_EVENTS / XDP_SOCKETS`, 内核分区 12M (HLOS12M GPT 方案)
5. 固件内置 daed; **每次构建成功自动发布 Release** (tag = 日期+上游短SHA, 同上游版本自动去重)
6. 想立即构建可手动: Actions → 工作流 → `Run workflow`

> 你的机型在截图里是 `snapshot-1.0.4`, 所以必须用 snapshot 源, 不能用稳定版 `fanchmwrt-25.12`。

## 目录结构

```
.github/workflows/build.yml   GitHub 云编译工作流
config/re-ss-01-daed.config   RE-SS-01 的 .config (target + daed + 内核 BTF)
scripts/diy-part1.sh          加 daed 第三方源
scripts/diy-part2.sh          主机名/版本小定制
```

## 触发与发布机制

| 触发方式 | 是否构建 |
|---|---|
| 定时 (每 6 小时) + 上游有新提交 | ✅ 自动构建 + 自动发 Release |
| 定时 + 上游无更新 | ❌ 跳过 (不编译) |
| 本仓库 git push (改配置等) | ❌ 不触发; 改完想验证用手动触发 |
| Actions 页面 `Run workflow` 手动 | ✅ 强制构建 |

构建成功后:
- **自动创建 Release**, tag 形如 `v20260925-abc1234` (日期 + 上游短 SHA; 同一上游版本不会重复发版)
- 固件在仓库 **Releases (发行版)** 页面直接下载, Actions 底部 `Artifacts` 同时保留一份
- 内容: `*re-ss-01*squashfs-factory.bin` (首次刷机) / `*sysupgrade.bin` (页面升级) / initramfs (tftp 救砖) / manifest / luci-app-daede、vmlinux-btf、v2ray-geo* 等备用 apk (dae/daed 本体已内置固件, 无需另装)

首次部署 (Windows PowerShell, 只需要一次):

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

推送只是把配置同步上去 (push 不触发编译):
- 第一次要构建: 打开仓库 → `Actions` → `Build FanchmWrt RE-SS-01 + daed` → `Run workflow`
- 之后每个更新由定时任务自动构建 (每 6 小时查一次上游), 等 2-4 小时, 成功后 Release 页面下载

## 刷机顺序 (和官方截图一致)

0. **前提: 先刷 HLOS12M GPT** (12M 内核分区, 模板: GHNERCH/DAEWRT-AX1800PRO 的 `gpt-JDC_AX1800_Pro_dual-boot_rootfs2048M_HLOS12M_no-last-partition.bin`); 本固件内核分区 12M, 原厂 GPT 装不下
1. 不死 uboot (`/big.html` 端点) 刷 `factory.bin`
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
