package com.example.farmestates_ai_dashbaord

import android.app.Application
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.ListenableWorker
import androidx.work.testing.TestWorkerBuilder
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.net.ServerSocket
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [31], application = Application::class)
class FarmNotificationsTest {
    private lateinit var context: Context
    private val id = "request_1234567890"

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).edit().clear()
            .putString("recipient", "alice").putLong("generation", 1).commit()
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit().clear()
            .putBoolean("flutter.is_logged_in", true).putString("flutter.user_id", "alice")
            .putString("flutter.auth_jwt", "current-session-token").commit()
        context.getSharedPreferences("notification_replies", Context.MODE_PRIVATE).edit().clear().commit()
        FarmNotifications.clear(context)
    }

    private fun notification(peer: String = "bob"): Notification = shadowOf(
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).getNotification(peer, 0)

    @Test fun chatShowsSenderMessageAndReplyWithoutActivityLaunch() {
        assertTrue(FarmNotifications.show(context, "alice", "bob", "Bob", "Water level is low", "message:one"))
        val alert = notification()
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(alert)!!
        assertEquals("Water level is low", style.messages.single().text.toString())
        assertEquals("Bob", style.messages.single().person!!.name.toString())
        assertEquals("Reply", alert.actions.single().title)
        assertTrue(shadowOf(alert.actions.single().actionIntent).isBroadcastIntent)
        assertFalse(alert.actions.single().actionIntent.isImmutable)
        assertEquals("bob", shadowOf(alert.contentIntent).savedIntent.getStringExtra("peerId"))
        assertEquals("New team message", alert.publicVersion.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
    }

    @Test fun workflowUsesExpandableTextAndHasNoReplyAction() {
        FarmNotifications.show(context, "alice", "__inbox__:notice", "Maintenance due", "Clean the pH sensor before tomorrow.")
        val alert = notification("__inbox__:notice")
        assertEquals("Clean the pH sensor before tomorrow.", alert.extras.getCharSequence(Notification.EXTRA_BIG_TEXT).toString())
        assertTrue(alert.actions.isNullOrEmpty())
    }

    @Test fun historiesAreBoundedDeduplicatedAndSeparateBetweenPeers() {
        repeat(15) { FarmNotifications.show(context, "alice", "bob", "Bob", "Message $it", "message:m$it") }
        FarmNotifications.show(context, "alice", "bob", "Bob", "Message 14", "message:m14")
        FarmNotifications.show(context, "alice", "carol", "Carol", "Other conversation", "message:other")
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification())!!
        assertEquals(12, style.messages.size)
        assertEquals("Message 14", style.messages.last().text.toString())
        assertEquals(12, FarmNotifications.incomingIds(context, "alice", "bob").length())
        assertEquals(1, NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification("carol"))!!.messages.size)
    }

    @Test fun accountSwitchAndLogoutSuppressOldNotificationsAndReplies() {
        assertFalse(FarmNotifications.show(context, "other", "bob", "Bob", "Private message"))
        draft(generation = 0)
        assertEquals(ListenableWorker.Result.failure(), worker().doWork())
        draft()
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit().remove("flutter.is_logged_in").commit()
        assertFalse(FarmNotifications.show(context, "alice", "bob", "Bob", "Private message"))
        assertEquals(ListenableWorker.Result.failure(), worker().doWork())
    }

    @Test fun successfulReplyUsesCurrentJwtAndIdempotencyKeyThenShowsSent() {
        FarmNotifications.show(context, "alice", "bob", "Bob", "Hello", "message:one")
        val requests = serve(200, 200)
        draft()
        assertEquals(ListenableWorker.Result.success(), worker().doWork())
        val received = requests.get(5, TimeUnit.SECONDS)
        assertTrue(received[0].contains("Authorization: Bearer current-session-token", ignoreCase = true))
        assertTrue(received[0].startsWith("POST /messages/conversations/bob "))
        val body = JSONObject(received[0].substringAfter("\r\n\r\n"))
        assertEquals("Reply from notification", body.getString("text"))
        assertEquals(id, body.getString("request_id"))
        assertTrue(received[1].startsWith("POST /messages/conversations/bob/read "))
        assertEquals("Sent", notification().extras.getCharSequence(Notification.EXTRA_SUB_TEXT).toString())
        assertFalse(context.getSharedPreferences("notification_replies", Context.MODE_PRIVATE).contains(id))
    }

    @Test fun serverFailuresRetrySameRequestAndPermanentFailureOffersRetry() {
        FarmNotifications.show(context, "alice", "bob", "Bob", "Hello", "message:one")
        val requests = serve(503, 503)
        draft()
        assertEquals(ListenableWorker.Result.retry(), worker().doWork())
        assertEquals(ListenableWorker.Result.failure(), worker(attempts = 3).doWork())
        val received = requests.get(5, TimeUnit.SECONDS)
        assertEquals(received[0].substringAfter("\r\n\r\n"), received[1].substringAfter("\r\n\r\n"))
        assertTrue(notification().actions.any { it.title == "Retry" })
        assertTrue(context.getSharedPreferences("notification_replies", Context.MODE_PRIVATE).contains(id))
    }

    @Test fun expiredAuthenticationNeverClaimsReplyWasSent() {
        FarmNotifications.show(context, "alice", "bob", "Bob", "Hello", "message:one")
        val requests = serve(401)
        draft()
        assertEquals(ListenableWorker.Result.failure(), worker().doWork())
        requests.get(5, TimeUnit.SECONDS)
        assertTrue(notification().extras.getCharSequence(Notification.EXTRA_SUB_TEXT).toString().contains("sign in"))
        assertEquals(1, NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification())!!.messages.size)
    }

    @Test fun lateWorkerDoesNotResurrectAnOpenedConversation() {
        FarmNotifications.show(context, "alice", "bob", "Bob", "Hello", "message:one")
        FarmNotifications.clear(context, "bob")
        FarmNotifications.replyState(context, "alice", "bob", "Reply", id, "Sent", sent = true)
        assertNull(shadowOf(context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).getNotification("bob", 0))
    }

    @Test fun sessionChangeDuringSendCannotUpdateTheNewSessionNotification() {
        FarmNotifications.show(context, "alice", "bob", "Bob", "Old session message", "message:old")
        val requests = serve(401, beforeResponse = {
            context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).edit().putLong("generation", 2).commit()
            FarmNotifications.clear(context)
            FarmNotifications.show(context, "alice", "bob", "Bob", "New session message", "message:new")
        })
        draft()
        assertEquals(ListenableWorker.Result.failure(), worker().doWork())
        requests.get(5, TimeUnit.SECONDS)
        val alert = notification()
        assertNull(alert.extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
        assertEquals("New session message", NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(alert)!!.messages.single().text.toString())
    }

    private fun draft(generation: Long = 1) {
        context.getSharedPreferences("notification_replies", Context.MODE_PRIVATE).edit().putString(id,
            JSONObject().put("recipient", "alice").put("peer", "bob").put("text", "Reply from notification")
                .put("generation", generation).put("created", System.currentTimeMillis())
                .put("readIds", JSONArray().put("one")).toString()).commit()
    }

    private fun worker(attempts: Int = 0): NotificationReplyWorker {
        val executor = Executors.newSingleThreadExecutor()
        val result = TestWorkerBuilder.from(context, NotificationReplyWorker::class.java, executor)
            .setInputData(Data.Builder().putString("requestId", id).build()).setRunAttemptCount(attempts).build()
        executor.shutdown()
        return result
    }

    /** Local HTTP fixture; no production API or private configuration is used. */
    private fun serve(vararg statuses: Int, beforeResponse: (() -> Unit)? = null): java.util.concurrent.Future<List<String>> {
        val server = ServerSocket(0)
        server.soTimeout = 5000
        context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).edit()
            .putString("apiBaseUrl", "http://127.0.0.1:${server.localPort}").commit()
        val executor = Executors.newSingleThreadExecutor()
        val result = executor.submit<List<String>> {
            server.use {
                statuses.map { code ->
                    server.accept().use { socket ->
                        val input = socket.getInputStream().bufferedReader()
                        val header = StringBuilder()
                        var length = 0
                        while (true) {
                            val line = input.readLine() ?: break
                            if (line.isEmpty()) break
                            header.append(line).append("\r\n")
                            if (line.startsWith("Content-Length:", true)) length = line.substringAfter(':').trim().toInt()
                        }
                        val body = CharArray(length)
                        var offset = 0
                        while (offset < length) offset += input.read(body, offset, length - offset)
                        beforeResponse?.invoke()
                        socket.getOutputStream().write("HTTP/1.1 $code Result\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}".toByteArray())
                        header.append("\r\n").append(body).toString()
                    }
                }
            }
        }
        executor.shutdown()
        return result
    }
}
