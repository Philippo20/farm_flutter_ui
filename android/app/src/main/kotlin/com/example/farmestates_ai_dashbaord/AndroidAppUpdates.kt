package com.example.farmestates_ai_dashbaord

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/** User-approved sideload updates. Downloads survive app/phone suspension. */
class AndroidAppUpdates(private val activity: FlutterActivity) {
    private val prefs = activity.getSharedPreferences("app_updates", Context.MODE_PRIVATE)
    private val downloads get() = activity.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val apk get() = File(requireNotNull(activity.getExternalFilesDir(null)), "updates/farmestates-update.apk")

    fun attach(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "farmestates/app_updates")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "installedVersion" -> {
                            val installed = installedInfo()
                            if (prefs.getLong("build", 0) <= version(installed)) clearDownload()
                            result.success(mapOf("packageName" to activity.packageName,
                                "version" to installed.versionName, "buildNumber" to version(installed)))
                        }
                        "startDownload" -> result.success(startDownload(call))
                        "downloadState" -> result.success(downloadState())
                        "verifyDownload" -> background(result) { verifyDownload(); null }
                        "canInstall" -> result.success(canInstall())
                        "allowInstallation" -> {
                            if (Build.VERSION.SDK_INT >= 26) activity.startActivity(Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:${activity.packageName}")))
                            result.success(null)
                        }
                        "installDownload" -> {
                            if (!canInstall()) result.success("permission")
                            else background(result) {
                                verifyDownload()
                                activity.runOnUiThread {
                                    try {
                                        val uri = FileProvider.getUriForFile(activity,
                                            "${activity.packageName}.app_updates", apk)
                                        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                                            setDataAndType(uri, "application/vnd.android.package-archive")
                                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        })
                                        result.success("opened")
                                    } catch (error: Exception) {
                                        result.error("installer_unavailable", "Unable to open Android installer", null)
                                    }
                                }
                                // Completion is delivered by the UI runnable above.
                                DeferredResult
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("update_unavailable", "Unable to process app update", null)
                }
            }
    }

    private object DeferredResult
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            try {
                val value = work()
                if (value !== DeferredResult) activity.runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runCatching { clearDownload() }
                activity.runOnUiThread { result.error("invalid_update", "Update verification failed", null) }
            }
        }.start()
    }

    @Suppress("DEPRECATION")
    private fun installedInfo(): PackageInfo = activity.packageManager.getPackageInfo(
        activity.packageName, if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES)
    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun clearDownload() {
        val id = prefs.getLong("id", -1)
        if (id != -1L) downloads.remove(id)
        if (apk.exists()) apk.delete()
        prefs.edit().clear().apply()
    }

    private fun startDownload(call: MethodCall): Map<String, Any> {
        val url = Uri.parse(call.argument<String>("url") ?: "")
        val hash = call.argument<String>("sha256") ?: ""
        val build = call.argument<Number>("buildNumber")?.toLong() ?: 0
        val size = call.argument<Number>("sizeBytes")?.toLong() ?: 0
        require(url.scheme == "https" && !url.host.isNullOrEmpty() && url.userInfo.isNullOrEmpty())
        require(Regex("^[a-f0-9]{64}$").matches(hash) && build > version(installedInfo()))
        require(size in 1..(300L * 1024 * 1024))
        if (prefs.getLong("build", 0) == build && prefs.getString("hash", "") == hash) {
            val state = downloadState()
            if (state["status"] !in listOf("failed", "missing", "none")) return state
        }
        clearDownload()
        require(apk.parentFile?.mkdirs() == true || apk.parentFile?.isDirectory == true)
        val request = DownloadManager.Request(url)
            .setTitle("Farm Estates app update")
            .setDescription("Download the latest Farm Estates version")
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalFilesDir(activity, null, "updates/farmestates-update.apk")
        val id = downloads.enqueue(request)
        prefs.edit().putLong("id", id).putLong("build", build)
            .putLong("size", size).putString("hash", hash).apply()
        return downloadState()
    }

    private fun downloadState(): Map<String, Any> {
        val id = prefs.getLong("id", -1)
        if (id == -1L) return mapOf("status" to "none")
        val metadata = mapOf("buildNumber" to prefs.getLong("build", 0), "sha256" to (prefs.getString("hash", "") ?: ""))
        downloads.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
            if (!cursor.moveToFirst()) return metadata + mapOf("status" to "missing")
            val status = when (cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))) {
                DownloadManager.STATUS_SUCCESSFUL -> "complete"
                DownloadManager.STATUS_FAILED -> "failed"
                DownloadManager.STATUS_PAUSED -> "paused"
                DownloadManager.STATUS_RUNNING -> "running"
                else -> "pending"
            }
            return metadata + mapOf("status" to status,
                "receivedBytes" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)),
                "totalBytes" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)))
        }
    }

    @Suppress("DEPRECATION")
    private fun signingKeys(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        return signatures?.map { sha256(it.toByteArray()) }?.toSet() ?: emptySet()
    }
    private fun sha256(bytes: ByteArray): String = MessageDigest.getInstance("SHA-256")
        .digest(bytes).joinToString("") { "%02x".format(it.toInt() and 0xff) }

    private fun verifyDownload() {
        require(downloadState()["status"] == "complete")
        require(apk.isFile && apk.length() == prefs.getLong("size", 0))
        val digest = MessageDigest.getInstance("SHA-256")
        apk.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
        require(hash == prefs.getString("hash", ""))
        val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        val archive = activity.packageManager.getPackageArchiveInfo(apk.absolutePath, flags)
            ?: throw IllegalArgumentException("Invalid APK")
        val installed = installedInfo()
        require(archive.packageName == activity.packageName && version(archive) == prefs.getLong("build", 0))
        require(version(archive) > version(installed))
        val keys = signingKeys(archive)
        require(keys.isNotEmpty() && keys == signingKeys(installed))
    }
    private fun canInstall(): Boolean = Build.VERSION.SDK_INT < 26 || activity.packageManager.canRequestPackageInstalls()
}
