package com.example.farmestates_ai_dashbaord

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.google.firebase.messaging.FirebaseMessaging

class MainActivity: FlutterActivity() {
    private val channelId = "team_messages"
    private var channel: MethodChannel? = null
    private val notifications get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                        notifications.cancelAll()
                        prefs.edit().putString("recipient", recipient).remove("delivered").apply()
                    }
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
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        val prefs = getSharedPreferences("message_notifications", MODE_PRIVATE)
                        if (!prefs.getBoolean("asked", false)) {
                            prefs.edit().putBoolean("asked", true).apply()
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 901)
                        }
                    }
                    result.success(null)
                }
                "show" -> {
                    val peer = call.argument<String>("peerId") ?: ""
                    val recipient = call.argument<String>("recipientId") ?: ""
                    if (Build.VERSION.SDK_INT < 33 ||
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                        val tap = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            action = "message:$recipient:$peer"
                            putExtra("peerId", peer)
                            putExtra("recipientId", recipient)
                        }
                        val pending = PendingIntent.getActivity(this, peer.hashCode(), tap,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, if (call.argument<Boolean>("silent") == true) "farm_updates_silent" else if (peer.startsWith("__inbox__:")) "farm_updates" else channelId)
                                      else Notification.Builder(this)
                        notifications.notify(peer, 0, builder
                            .setSmallIcon(R.drawable.ic_message_notification)
                            .setContentTitle(call.argument<String>("title"))
                            .setContentText(call.argument<String>("body"))
                            .setCategory(if (peer.startsWith("__inbox__:")) Notification.CATEGORY_EVENT else Notification.CATEGORY_MESSAGE)
                            .setVisibility(Notification.VISIBILITY_PRIVATE)
                            .setAutoCancel(true).setContentIntent(pending).build())
                        result.success(true)
                    } else { result.success(false) }
                }
                "dismiss" -> {
                    notifications.cancel(call.argument<String>("peerId"), 0)
                    result.success(null)
                }
                "clear" -> { notifications.cancelAll(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        FarmPushService.foreground = true
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
