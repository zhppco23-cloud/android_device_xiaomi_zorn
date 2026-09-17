/*
 * Copyright (C) 2015 The CyanogenMod Project
 *               2017-2019 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.lineageos.settings;

import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.database.ContentObserver;
import android.hardware.display.DisplayManager;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.os.ServiceManager;
import android.os.UserHandle;
import android.provider.Settings;
import android.util.Log;
import android.view.Display;
import android.view.Display.HdrCapabilities;

import vendor.xiaomi.hw.touchfeature.ITouchFeature;

import org.lineageos.settings.display.ColorModeService;
import org.lineageos.settings.doze.PocketService;
import org.lineageos.settings.thermal.ThermalUtils;
import org.lineageos.settings.thermal.ThermalTileService;
import org.lineageos.settings.refreshrate.RefreshUtils;
import org.lineageos.settings.turbocharging.TurboChargingService;

public class BootCompletedReceiver extends BroadcastReceiver {
    private static final String TAG = "XiaomiParts";
    private static final boolean DEBUG = true;
    private static final int DOUBLE_TAP_TO_WAKE_MODE = 14;
    private static final int Touch_Fod_Enable     = 10;
    private static final int Touch_Aod_Enable     = 11;
    private static final int Touch_FodIcon_Enable = 16;

    private ITouchFeature xiaomiTouchFeatureAidl;

    @Override
    public void onReceive(final Context context, Intent intent) {
        if (DEBUG) Log.i(TAG, "Received intent: " + intent.getAction());
        switch (intent.getAction()) {
            case Intent.ACTION_LOCKED_BOOT_COMPLETED:
                handleLockedBootCompleted(context);
                break;
            case Intent.ACTION_BOOT_COMPLETED:
                handleBootCompleted(context);
                break;
        }
    }

    private void handleLockedBootCompleted(Context context) {
        if (DEBUG) Log.i(TAG, "Handling locked boot completed.");
        try {
            // Start necessary services
            startServices(context);

            // Override HDR types
            overrideHdrTypes(context);

            // Register observer for Double Tap to Wake.
            registerDoubleTapToWakeObserver(context);

            initializeTouchFeatures(context);
        } catch (Exception e) {
            Log.e(TAG, "Error during locked boot completed processing", e);
        }
    }

    private void handleBootCompleted(Context context) {
        if (DEBUG) Log.i(TAG, "Handling boot completed.");
        // LOCKED_BOOT_COMPLETED can run before the vendor TouchFeature service
        // is ready.  Retry after normal boot so wake gestures and SoFOD do not
        // remain disabled for the rest of the session.
        initializeTouchFeatures(context);
    }

    private void startServices(Context context) {
        if (DEBUG) Log.i(TAG, "Starting services...");

        // Start Color Mode Service
        context.startServiceAsUser(new Intent(context, ColorModeService.class), UserHandle.CURRENT);

        // Start Thermal Management Services
        ThermalUtils.getInstance(context).startService();
        context.startServiceAsUser(new Intent(context, ThermalTileService.class), UserHandle.CURRENT);

        // Start Refresh Rate Service
        RefreshUtils.startService(context);

        // Start Pocket Mode Service
        PocketService.startService(context);

        // Start TurboChargingService
        Intent turboChargingIntent = new Intent(context, TurboChargingService.class);
        context.startService(turboChargingIntent);
    }

    private void overrideHdrTypes(Context context) {
        try {
            final DisplayManager dm = context.getSystemService(DisplayManager.class);
            if (dm != null) {
                dm.overrideHdrTypes(Display.DEFAULT_DISPLAY, new int[]{
                        HdrCapabilities.HDR_TYPE_DOLBY_VISION,
                        HdrCapabilities.HDR_TYPE_HDR10,
                        HdrCapabilities.HDR_TYPE_HLG,
                        HdrCapabilities.HDR_TYPE_HDR10_PLUS
                });
                if (DEBUG) Log.i(TAG, "HDR types overridden successfully.");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error overriding HDR types", e);
        }
    }

    private void registerDoubleTapToWakeObserver(Context context) {
        if (DEBUG) Log.i(TAG, "Registering Double Tap to Wake observer.");
        ContentObserver observer = new ContentObserver(new Handler()) {
            @Override
            public void onChange(boolean selfChange) {
                updateTapToWakeStatus(context);
            }
        };
        context.getContentResolver().registerContentObserver(
                Settings.Secure.getUriFor(Settings.Secure.DOUBLE_TAP_TO_WAKE),
                true,
                observer
        );
        updateTapToWakeStatus(context);
    }

    private void updateTapToWakeStatus(Context context) {
        if (DEBUG) Log.i(TAG, "Updating Double Tap to Wake status.");
        try {
            if (xiaomiTouchFeatureAidl == null) initTouchFeatureService();
            if (xiaomiTouchFeatureAidl == null) {
                Log.w(TAG, "TouchFeature service is unavailable");
                return;
            }
            boolean enabled = Settings.Secure.getInt(
                    context.getContentResolver(),
                    Settings.Secure.DOUBLE_TAP_TO_WAKE,
                    0
            ) == 1;
            // Some vendor implementations expose the V1 AIDL contract only.
            // setTouchMode() was added later and returns "Unimplemented" there;
            // setModeValue() is the compatible equivalent for this operation.
            xiaomiTouchFeatureAidl.setModeValue(
                    0, DOUBLE_TAP_TO_WAKE_MODE, enabled ? 1 : 0);
        } catch (Exception e) {
            Log.e(TAG, "Failed to update Tap to Wake status", e);
        }
    }

    private void initializeTouchFeatures(Context context) {
        initTouchFeatureService();
        if (xiaomiTouchFeatureAidl == null) {
            Log.w(TAG, "Cannot initialize touch features: service is unavailable");
            return;
        }

        updateTapToWakeStatus(context);
        try {
            xiaomiTouchFeatureAidl.setModeValue(0, Touch_Fod_Enable, 1);
            xiaomiTouchFeatureAidl.setModeValue(0, Touch_Aod_Enable, 1);
            xiaomiTouchFeatureAidl.setModeValue(0, Touch_FodIcon_Enable, 1);
            if (DEBUG) Log.i(TAG, "SoFOD features enabled on lock screen");
        } catch (Exception e) {
            Log.e(TAG, "Failed to enable SoFOD features", e);
        }
    }

    private void initTouchFeatureService() {
        if (xiaomiTouchFeatureAidl != null) return;
        try {
            String name = "default";
            String fqName = ITouchFeature.DESCRIPTOR + "/" + name;
            IBinder binder = Binder.allowBlocking(
                    ServiceManager.waitForDeclaredService(fqName)
            );
            if (binder == null) {
                Log.w(TAG, "TouchFeature service is not declared");
                return;
            }
            xiaomiTouchFeatureAidl = ITouchFeature.Stub.asInterface(binder);
            if (DEBUG) Log.i(TAG, "TouchFeature service connected");
        } catch (Exception e) {
            Log.e(TAG, "Failed to connect to TouchFeature service", e);
        }
    }
}
