package com.fanqie.mobile;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.os.Build;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "openim/screen_share_service";
    private static final String NOTI_CHANNEL_ID = "screen_share";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startMediaProjectionService")) {
                        startForegroundServiceForProjection();
                        result.success(null);
                    } else if (call.method.equals("stopMediaProjectionService")) {
                        stopForegroundServiceForProjection();
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void startForegroundServiceForProjection() {
        Context ctx = this.getApplicationContext();
        Intent intent = new Intent(ctx, ProjectionService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ctx.startForegroundService(intent);
        } else {
            ctx.startService(intent);
        }
    }

    private void stopForegroundServiceForProjection() {
        Context ctx = this.getApplicationContext();
        Intent intent = new Intent(ctx, ProjectionService.class);
        ctx.stopService(intent);
    }
}
