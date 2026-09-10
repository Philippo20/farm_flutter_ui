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

class MainActivity: FlutterActivity() {
    private val channelId = "team_messages"
    private var channel: MethodChannel? = null
    private val notifications get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= 26) {
            notifications.createNotificationChannel(NotificationChannel(
                channelId, "Team messages", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "New messages from your farm team" })
        }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "farmestates/message_notifications")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
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
                        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channelId)
                                      else Notification.Builder(this)
                        notifications.notify(peer, 0, builder
                            .setSmallIcon(R.drawable.ic_message_notification)
                            .setContentTitle(call.argument<String>("title"))
                            .setContentText(call.argument<String>("body"))
                            .setCategory(Notification.CATEGORY_MESSAGE)
                            .setVisibility(Notification.VISIBILITY_PRIVATE)
                            .setAutoCancel(true).setContentIntent(pending).build())
                    }
                    result.success(null)
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
