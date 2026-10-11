package com.example.farmestates_ai_dashbaord

import android.content.Context
import android.net.Uri
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

/** Persistent network work survives backgrounding; the API owns send authorization. */
class NotificationReplyWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    companion object {
        private fun drafts(context: Context) = context.getSharedPreferences("notification_replies", Context.MODE_PRIVATE)
        fun clear(context: Context) {
            WorkManager.getInstance(context).cancelAllWorkByTag("notification_reply")
            drafts(context).edit().clear().apply()
        }

        fun enqueue(context: Context, id: String, recipient: String, peer: String, text: String) {
            val storage = drafts(context)
            val generation = context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getLong("generation", 0)
            val existing = runCatching { JSONObject(storage.getString(id, "") ?: "") }.getOrNull()
            val draft = if (existing != null && existing.optString("recipient") == recipient &&
                existing.optString("peer") == peer && existing.optString("text") == text && existing.optLong("generation") == generation) existing
            else JSONObject().put("recipient", recipient).put("peer", peer).put("text", text)
                .put("generation", generation).put("readIds", FarmNotifications.incomingIds(context, recipient, peer))
                .put("created", System.currentTimeMillis())
            for ((key, value) in storage.all) {
                val created = runCatching { JSONObject(value as String).optLong("created") }.getOrDefault(0)
                if (key != id && System.currentTimeMillis() - created > TimeUnit.HOURS.toMillis(24)) storage.edit().remove(key).apply()
            }
            if (!storage.edit().putString(id, draft.toString()).commit()) return
            val work = OneTimeWorkRequestBuilder<NotificationReplyWorker>()
                .setInputData(Data.Builder().putString("requestId", id).build())
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
                .addTag("notification_reply").build()
            FarmNotifications.replyState(context, recipient, peer, text, id, "Sending when connected…")
            WorkManager.getInstance(context).enqueueUniqueWork("notification_reply:$id", ExistingWorkPolicy.KEEP, work)
        }
    }

    override fun doWork(): Result {
        val context = applicationContext
        val id = inputData.getString("requestId") ?: return Result.failure()
        val raw = drafts(context).getString(id, null) ?: return Result.failure()
        val draft = runCatching { JSONObject(raw) }.getOrNull() ?: return Result.failure()
        val recipient = draft.optString("recipient")
        val peer = draft.optString("peer")
        val text = draft.optString("text")
        val push = context.getSharedPreferences("farm_push", Context.MODE_PRIVATE)
        val session = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        fun ownsSession() = FarmNotifications.isRecipient(context, recipient) &&
            draft.optLong("generation") == push.getLong("generation", 0) &&
            session.getBoolean("flutter.is_logged_in", false) && session.getString("flutter.user_id", null) == recipient
        if (!ownsSession() || isStopped) return Result.failure()
        val jwt = session.getString("flutter.auth_jwt", null)
        if (jwt.isNullOrBlank()) return failed(recipient, peer, text, id, "Sign in to send your reply.", false)
        if (System.currentTimeMillis() - draft.optLong("created") > TimeUnit.HOURS.toMillis(24)) {
            return failed(recipient, peer, text, id, "Reply expired. Open the conversation to send it.", false)
        }
        val base = push.getString("apiBaseUrl", null)?.trimEnd('/') ?: return Result.failure()
        val url = runCatching { URL("$base/messages/conversations/${Uri.encode(peer)}") }.getOrNull() ?: return Result.failure()
        if (url.protocol != "https" && !(url.protocol == "http" && url.host in setOf("10.0.2.2", "localhost", "127.0.0.1"))) return Result.failure()
        FarmNotifications.replyState(context, recipient, peer, text, id, "Sending…")
        try {
            if (!ownsSession() || isStopped) return Result.failure()
            val code = post(url, jwt, JSONObject().put("text", text).put("request_id", id))
            if (!ownsSession() || isStopped) return Result.failure()
            if (code in 200..299) {
                FarmNotifications.replyState(context, recipient, peer, text, id, "Sent", sent = true)
                // Mark only messages visible when Reply was used, never a newer arrival.
                runCatching {
                    if (ownsSession()) post(URL("${url}/read"), jwt, JSONObject().put("message_ids", draft.optJSONArray("readIds") ?: org.json.JSONArray()))
                }
                drafts(context).edit().remove(id).apply()
                return Result.success()
            }
            if (code in setOf(401, 403)) return failed(recipient, peer, text, id, "Could not send. Open the conversation to sign in or check access.", false)
            if (code == 429 || code >= 500) return retryOrFail(recipient, peer, text, id)
            return failed(recipient, peer, text, id, "Could not send. Open the conversation to check this message.", false)
        } catch (_: Exception) {
            return if (ownsSession() && !isStopped) retryOrFail(recipient, peer, text, id) else Result.failure()
        }
    }

    private fun post(url: URL, jwt: String, payload: JSONObject): Int {
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.instanceFollowRedirects = false
            connection.connectTimeout = 10000
            connection.readTimeout = 15000
            connection.setRequestProperty("Authorization", "Bearer $jwt")
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            connection.doOutput = true
            connection.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
            return connection.responseCode
        } finally { connection.disconnect() }
    }

    private fun retryOrFail(recipient: String, peer: String, text: String, id: String): Result {
        if (runAttemptCount >= 3) return failed(recipient, peer, text, id, "Could not send. Tap Retry when connected.", true)
        FarmNotifications.replyState(applicationContext, recipient, peer, text, id, "Waiting to retry…")
        return Result.retry()
    }

    private fun failed(recipient: String, peer: String, text: String, id: String, message: String, retry: Boolean): Result {
        FarmNotifications.replyState(applicationContext, recipient, peer, text, id, message, retry = retry)
        return Result.failure()
    }
}
