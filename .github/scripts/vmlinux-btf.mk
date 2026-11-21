# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=vmlinux-btf
PKG_VERSION:=$(LINUX_VERSION)
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_FILE_DEPENDS:=$(LINUX_DIR)/vmlinux

include $(INCLUDE_DIR)/package.mk

define Package/vmlinux-btf
  SECTION:=kernel
  CATEGORY:=Kernel
  TITLE:=Detached BTF for the built kernel
  EXTRA_DEPENDS:=kernel (=$(LINUX_VERSION)~$(LINUX_VERMAGIC)-r$(LINUX_RELEASE))
endef

define Build/Compile
	pahole --btf_encode_detached="$(PKG_BUILD_DIR)/vmlinux" "$(LINUX_DIR)/vmlinux"
	od -An -tx1 -N2 "$(PKG_BUILD_DIR)/vmlinux" | tr -d ' \n' | grep -Fxq 9feb
endef

define Package/vmlinux-btf/install
	$(INSTALL_DIR) $(1)/usr/lib/debug/boot
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/vmlinux $(1)/usr/lib/debug/boot/vmlinux
	$(LN) vmlinux $(1)/usr/lib/debug/boot/vmlinux-$(LINUX_UNAME_VERSION)
endef

$(eval $(call BuildPackage,vmlinux-btf))
