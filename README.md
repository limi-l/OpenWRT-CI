# 高质量<免费>交流群

[IPQ技术讨论群](https://qm.qq.com/q/v7nMhzB4oU)

# 高质量<付费>中转站

[Krill-Code](https://www.krill-code.com/register?invite=959NHQCZGT)

# 本地编译器

https://github.com/VIKINGYFY/OWRT-Tools.git

# 自用修改版插件

https://github.com/VIKINGYFY/packages.git

# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-qsdk12.5-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

# 固件简要说明

固件每天早上5点自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

## 编译 Honk 固件

在 **Actions → WRT-TEST → Run workflow** 中选择设备对应的 `CONFIG`、`SOURCE` 和 `BRANCH`，勾选 `HONK` 并取消勾选 `TEST`。需要 ARM64 或 x86_64，以及 Linux 6.12 或更新版本。构建成功后，从该次运行的 **Artifacts** 下载 `honk-…`，按设备型号选择镜像。开启 `TEST` 时只生成配置文件。

固件包含 Honk、内嵌的 Doona 界面和 LuCI 管理页。首次启动前，在 LuCI 的 **服务 → Honk** 编辑 `/etc/honk/config.dae`，按实际网络填写接口、节点和路由规则，然后启动服务。Honk 默认关闭开机自启。

IPQ60XX 将本次内核生成的 BTF 安装在根文件系统的 `/usr/lib/debug/boot/vmlinux`，以适应设备的内核分区大小。Linksys MR7350 的 Honk 固件移除 HomeProxy 和 sing-box，为镜像留出空间。

## Star History

<a href="https://www.star-history.com/?repos=vikingyfy%2Fopenwrt-ci&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
 </picture>
</a>
