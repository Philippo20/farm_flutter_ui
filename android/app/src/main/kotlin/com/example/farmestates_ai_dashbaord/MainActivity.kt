package com.example.farmestates_ai_dashbaord

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import com.google.firebase.messaging.FirebaseMessaging

class MainActivity: FlutterFragmentActivity() {
    private var biometricSignIn: AndroidBiometricSignIn? = null
    private var notificationPermission: AndroidNotificationPermission? = null
    private val channelId = "team_messages"
    private var channel: MethodChannel? = null
    private val notifications get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        biometricSignIn = AndroidBiometricSignIn(this).also { it.attach(flutterEngine) }
        notificationPermission = AndroidNotificationPermission(this)
        AndroidAppUpdates(this).attach(flutterEngine)
        if (Build.VERSION.SDK_INT >= 26) {
            notifications.createNotificationChannel(NotificationChannel(
                channelId, "Team messages", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "New messages from your farm team" })
        }
        if (Build.VERSION.SDK_INT >= 26) {
            notifications.createNotificationChannel(NotificationChannel(
                "farm_updates", "Farm updates", NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "Tasks, deliveries, production and farm alerts" })
        }
        if (Build.VERSION.SDK_INT >= 26) {
            notifications.createNotificationChannel(NotificationChannel(
                "farm_updates_silent", "Silent farm updates", NotificationManager.IMPORTANCE_LOW
            ).apply { setSound(null, null); enableVibration(false) })
        }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "farmestates/message_notifications")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "pushToken" -> FirebaseMessaging.getInstance().token
                    .addOnSuccessListener { result.success(it) }
                    .addOnFailureListener { result.error("push_unavailable", "Push registration unavailable", null) }
                "pushRecipient" -> {
                    val recipient = call.argument<String>("recipientId") ?: ""
                    val prefs = getSharedPreferences("farm_push", MODE_PRIVATE)
                    if (prefs.getString("recipient", "") != recipient) {
                        FarmNotifications.clear(this)
                        NotificationReplyWorker.clear(this)
                        prefs.edit().putString("recipient", recipient).remove("delivered")
                            .putLong("generation", prefs.getLong("generation", 0) + 1).commit()
                    }
                    prefs.edit().putString("apiBaseUrl", call.argument<String>("apiBaseUrl")).apply()
                    result.success(null)
                }
                "pushDelivered" -> result.success(FarmPushService.delivered(this).toList())
                "initialMessage" -> {
                    val peer = intent.getStringExtra("peerId")
                    result.success(if (peer == null) null else mapOf(
                        "peerId" to peer, "recipientId" to intent.getStringExtra("recipientId")))
                    intent.removeExtra("peerId")
                    intent.removeExtra("recipientId")
                }
                "requestPermission" -> {
                    notificationPermission!!.request { result.success(it) }
                }
                "show" -> {
                    val peer = call.argument<String>("peerId") ?: ""
                    val recipient = call.argument<String>("recipientId") ?: ""
                    result.success(FarmNotifications.show(this, recipient, peer,
                        call.argument<String>("title") ?: "Farm Estates", call.argument<String>("body") ?: "",
                        call.argument<String>("messageId") ?: "", call.argument<Number>("timestamp")?.toLong() ?: System.currentTimeMillis(),
                        call.argument<Boolean>("silent") == true))
                }
                "dismiss" -> {
                    call.argument<String>("peerId")?.let { FarmNotifications.clear(this, it) }
                    result.success(null)
                }
                "clear" -> { FarmNotifications.clear(this); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        FarmPushService.foreground = true
    }

    override fun onDestroy() {
        biometricSignIn?.dispose()
        notificationPermission?.dispose()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        notificationPermission?.onResult(requestCode, grantResults)
    }

    override fun onStop() {
        FarmPushService.foreground = false
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val peer = intent.getStringExtra("peerId") ?: return
        channel?.invokeMethod("openMessage", mapOf(
            "peerId" to peer, "recipientId" to intent.getStringExtra("recipientId")))
        intent.removeExtra("peerId")
        intent.removeExtra("recipientId")
    }
}
