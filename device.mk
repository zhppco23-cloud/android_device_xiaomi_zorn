#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/zorn

# Keep the product configuration based on sm8650-common while using only
# zorn's self-contained proprietary vendor tree.
$(call inherit-product, device/xiaomi/zorn/common.mk)

# Replace sm8650-common's basic device settings app with zorn's complete
# implementation. The local module uses a distinct Soong name, so both
# device directories can remain in PRODUCT_SOONG_NAMESPACES.
PRODUCT_PACKAGES := $(filter-out XiaomiParts,$(PRODUCT_PACKAGES))
PRODUCT_PACKAGES += XiaomiPartsZorn

TARGET_HAS_UDFPS := true
PRODUCT_BUILD_SUPER_PARTITION := true
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    device/xiaomi/sm8650-common

# zorn-specific audio tuning.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_pineapple/audio_effects.xml \
    $(DEVICE_PATH)/configs/audio/mixer_paths_overlay_static.xml:$(TARGET_COPY_OUT_ODM)/etc/audio/sku_pineapple/mixer_paths_overlay_static.xml \
    $(DEVICE_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_pineapple/audio_policy_configuration.xml

PRODUCT_PACKAGES += \
    audio.primary.default \
    libar-acdb \
    libar-gpr \
    libar-gsl \
    libats \
    libcustomva_intf \
    liblx-ar_util \
    liblx-osal \
    libaudiochargerlistener \
    libaudioroute.vendor \
    libtinycompress \
    vendor.qti.hardware.AGMIPC@1.0 \
    vendor.qti.hardware.AGMIPC@1.0-impl \
    vendor.qti.audio-adsprpc-service.rc

# Camera, fingerprint init, device settings, and zorn-only shims.
$(call inherit-product-if-exists, vendor/xiaomi/camera/miuicamera.mk)

PRODUCT_PACKAGES += \
    libcameraflare_shim \
    libcamerahdr_shim \
    libcameraplugin_shim \
    qcrilNrDb_vendor \
    sensors.xiaomi.v2 \
    init.qcom.early_boot.sh \
    init.fingerprint.rc \
    ueventd.zorn.userdebug.rc

PRODUCT_VENDOR_LINKER_CONFIG_FRAGMENTS += \
    $(DEVICE_PATH)/configs/linker.config.json

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/properties/odm_CN.prop:$(TARGET_COPY_OUT_ODM)/etc/build_CN.prop \
    $(DEVICE_PATH)/configs/properties/odm_GL.prop:$(TARGET_COPY_OUT_ODM)/etc/build_GL.prop \
    $(DEVICE_PATH)/configs/properties/odm_CN.prop:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/odm/etc/build_CN.prop \
    $(DEVICE_PATH)/configs/properties/odm_GL.prop:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/odm/etc/build_GL.prop

# Device-specific overlays supplement the common Xiaomi overlays.
PRODUCT_PACKAGES += \
    FrameworksResZorn \
    NetworkStackResZorn \
    SettingsProviderResZorn \
    SystemUIResZorn

ifneq ($(filter zorn,$(TARGET_DEVICE)),)
$(call soong_config_set,lineage_powershare,powershare_path,/sys/class/qcom-battery/reverse_chg_mode)
PRODUCT_PACKAGES += vendor.lineage.powershare-service.default
endif

PRODUCT_SYSTEM_PROPERTIES += \
    ro.miui.notch=1 \
    ro.product.mod_device=zorn
