#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/zorn
KERNEL_PATH := $(DEVICE_PATH)-kernel

# Keep the platform-wide configuration in one place.
include device/xiaomi/sm8650-common/BoardConfigCommon.mk

SELINUX_IGNORE_NEVERALLOWS := false
TARGET_SCREEN_DENSITY := 480

# zorn ships its own kernel image and modules.
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtb
TARGET_NO_KERNEL_OVERRIDE := true
TARGET_KERNEL_SOURCE := $(KERNEL_PATH)/kernel-headers
PRODUCT_COPY_FILES += \
    $(KERNEL_PATH)/kernel:kernel

BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_ramdisk/modules.load))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(KERNEL_PATH)/vendor_ramdisk/modules.blocklist
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_ramdisk/modules.load.recovery))
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_dlkm/modules.load))

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(KERNEL_PATH)/vendor_dlkm/,$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules) \
    $(call find-copy-subdir-files,*,$(KERNEL_PATH)/vendor_ramdisk/,$(TARGET_COPY_OUT_VENDOR_RAMDISK)/lib/modules) \
    $(call find-copy-subdir-files,*,$(KERNEL_PATH)/system_dlkm_flatten/,$(TARGET_COPY_OUT_SYSTEM_DLKM)/flatten/lib/modules) \
    $(call find-copy-subdir-files,*,$(KERNEL_PATH)/system_dlkm/,$(TARGET_COPY_OUT_SYSTEM_DLKM)/lib/modules/6.1.118-android14-11-ga3b9c44908dd-ab13320413)

# zorn's super partition is larger than the common baseline.
BOARD_DTBOIMG_PARTITION_SIZE := 20971520
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 11800674304

# Use ext4 for every logical partition. This overrides inherited settings.
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4))

# The inherited common board config establishes hardware defaults.  zorn owns
# complete property sets so its panel, UDFPS, and SKU values replace the
# generic SM8650 property files without duplicate assignments.
TARGET_ODM_PROP := $(DEVICE_PATH)/configs/properties/odm.prop
TARGET_PRODUCT_PROP := $(DEVICE_PATH)/configs/properties/product.prop
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/configs/properties/system.prop
TARGET_SYSTEM_EXT_PROP := $(DEVICE_PATH)/configs/properties/system_ext.prop
TARGET_VENDOR_PROP := $(DEVICE_PATH)/configs/properties/vendor.prop

# Security patch level from OS2.0.215.0.VOKCNXM.
BOOT_SECURITY_PATCH := 2025-08-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

# zorn-only policy extensions.
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

TARGET_POWERSHARE_PATH := /sys/class/qcom-battery/reverse_chg_mode
TARGET_QTI_VIBRATOR_EFFECT_LIB := libqtivibratoreffect.xiaomi
TARGET_QTI_VIBRATOR_USE_EFFECT_STREAM := true

-include vendor/xiaomi/zorn/BoardConfigVendor.mk
