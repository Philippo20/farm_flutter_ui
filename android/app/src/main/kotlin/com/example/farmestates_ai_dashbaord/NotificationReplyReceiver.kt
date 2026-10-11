package com.example.farmestates_ai_dashbaord

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import java.util.UUID

/** Explicit, non-exported receiver; replying never launches an Activity. */
class NotificationReplyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(FarmNotifications.REPLY, FarmNotifications.RETRY)) return
        val recipient = intent.getStringExtra("recipientId") ?: return
        val peer = intent.getStringExtra("peerId") ?: return
        if (!FarmNotifications.isRecipient(context, recipient) || peer.isBlank() || peer.startsWith("__inbox__:")) return
        if (intent.getLongExtra("generation", -1) != context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getLong("generation", 0)) return
        val retry = intent.action == FarmNotifications.RETRY
        val text = (if (retry) intent.getStringExtra("text") else RemoteInput.getResultsFromIntent(intent)?.getCharSequence(FarmNotifications.REPLY_TEXT)?.toString())?.trim() ?: return
        if (text.isEmpty()) return
        val requestId = if (retry) intent.getStringExtra("requestId") ?: return else UUID.randomUUID().toString()
        if (text.codePointCount(0, text.length) > 4000) {
            FarmNotifications.replyState(context, recipient, peer, text, requestId, "Message too long. Open the conversation to edit it.")
            return
        }
        // WorkManager's persisted Data limit is 10 KB. UTF-8 previews/replies can
        // exceed that even within the API's character limit; keep the draft in an
        // app-private preference and pass only identifiers to the worker.
        NotificationReplyWorker.enqueue(context, requestId, recipient, peer, text)
    }
}
