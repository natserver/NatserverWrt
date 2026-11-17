# NatserverWrt for 京东云亚瑟 AX1800 Pro（RE-SS-01）

## 内置软件

- **eBPF / BTF 内核支持**：已开启 BTF、XDP、BPF Events、CGROUPS、BPF 工具链，并内置 honk 所需内核模块（kmod-sched-core / kmod-sched-bpf / kmod-veth / kmod-nft-queue）；
- **honk 已预装**：dae 的 Rust 重写版，eBPF 内核态分流，核心自带 doona Web 面板，刷机即用；本固件不含 dae/daed。

## 刷机流程

1. 刷 **12M 大分区 U-Boot**（HLOS 12MiB）；
2. 刷 **2GB GPT 模板**（rootfs 扩到 2048MiB，用于装固件，不能省略）；
3. U-Boot 页面刷本项目 `factory.bin`
4. Web 升级 `sysupgrade.bin`。

### 刷机文件下载

| 文件 | 下载 |
| --- | --- |
| 12M 大分区 U-Boot（jdcloud_re-ss-01） | [直接下载 .bin](https://github.com/chenxin527/uboot-qsdk12.5-build/releases/download/26.08.16-14.22.36-3011049/uboot-ipq60xx-jdcloud_re-ss-01-260816_142236_3011049.bin) |
| GPT 模板（rootfs2048M / HLOS12M） | [直接下载 .bin](https://github.com/natserver/NatserverWrt/raw/main/files/gpt/gpt-JDC_AX1800_Pro_dual-boot_rootfs2048M_HLOS12M_no-last-partition.bin) |

> GPT 模板已存入本仓库 `files/gpt/`，不再依赖第三方仓库（原 GHNERCH/DAEWRT-AX1800PRO 已删除，旧链接 404）。
>
> - 大小：17408 字节（前 34 扇区），`sha256 = 3793689a65556b39b277e967dc0e553ed1e3a4be766d11a3de460014bcbf1312`
> - 校验：`sha256sum gpt-*.bin`，或 `python -c "import sys;d=open(sys.argv[1],'rb').read();print(d[512:520])" gpt-*.bin` 应输出 `b'EFI PART'`
> - 布局：`0:HLOS` 12MiB、`0:HLOS_1` 12MiB（双槽都能放 12M 内核）、`rootfs` 2048MiB、`rootfs_1` 60MiB、`rootfs_data` 200MiB，无 plugin/log/swap 尾分区
> - 写入：U-Boot 的 `/ptable.html` 上传此文件即可（只写主 GPT，CRC 有效）；分区偏移会变，**刷完必须重刷 factory.bin**。ART 仍为 p15、偏移不变，刷分区表和 factory.bin 都不会动它；保险起见可先备份 `dd if=/dev/mmcblk0p15 of=/tmp/art.bin bs=512`

## 鸣谢

fanchmwrt：[仓库链接](https://github.com/fanchmwrt/fanchmwrt-snapshot)
