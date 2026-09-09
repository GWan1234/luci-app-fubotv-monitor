include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fubotv-monitor
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

LUCI_TITLE:=FuBoTv monitor reporter for ESP8266 weather clock
LUCI_DESCRIPTION:=Report router CPU, RAM utilization and CPU temperature to an \
	ESP8266 WiFi weather clock over HTTP, compatible with the stock Windows agent.
LUCI_DEPENDS:= \
	+luci-base \
	+curl \
	+ucode \
	+ucode-mod-fs \
	+ucode-mod-uci \
	+ucode-mod-ubus \
	+ucode-mod-uloop \
	+rpcd \
	+rpcd-mod-ucode
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# luci.mk 直接从源码树拷贝文件，Windows / 未设置可执行位的 checkout 会丢权限。
# 这里在 postinst 中显式补回，保证 ucode 脚本与 init.d 可被执行。
#
# 注意：此处自定义 postinst 会覆盖 luci.mk 生成的标准 postinst，因此必须
# 手动补上 luci.mk 原本负责的两件事，否则实机会复现"页面读不到数据"：
#   1) 清除 LuCI 索引缓存（/tmp/luci-indexcache、/tmp/luci-modulecache），
#      否则新菜单与 view 不生效；
#   2) 重启 rpcd，令其重新扫描 /usr/share/rpcd/ucode/ 目录并注册
#      luci.fubotv ubus 对象。rpcd 只在启动时加载一次 ucode 脚本，
#      不重启的话 status/test RPC 会一直 "Not found"，前端拿不到任何数据。
define Package/$(PKG_NAME)/postinst
#!/bin/sh
for f in \
	/usr/share/fubotv/lib.uc \
	/usr/share/fubotv/report.uc \
	/usr/share/rpcd/ucode/luci.fubotv \
	/etc/init.d/fubotv ; do
	[ -f "$${IPKG_INSTROOT}$$f" ] && chmod 0755 "$${IPKG_INSTROOT}$$f"
done

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -f /tmp/luci-indexcache /tmp/luci-modulecache
	if [ -x /etc/init.d/rpcd ]; then
		/etc/init.d/rpcd restart
	else
		killall rpcd 2>/dev/null
	fi
fi

exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
