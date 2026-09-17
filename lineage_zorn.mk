#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from zorn device.
$(call inherit-product, device/xiaomi/zorn/device.mk)

## Device identifier
PRODUCT_DEVICE := zorn
PRODUCT_NAME := lineage_zorn
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24117RK2CC
PRODUCT_MANUFACTURER := Xiaomi

# bootanimation
TARGET_BOOT_ANIMATION_RES := 1440

# Redmi K80 (zorn), from OS2.0.215.0.VOKCNXM.
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Redmi/zorn/zorn:15/AQ3A.240829.003/OS2.0.215.0.VOKCNXM:user/release-keys

# GMS
PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
