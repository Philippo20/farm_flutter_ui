package com.example.farmestates_ai_dashbaord

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** The encrypted secret can only be decrypted by a biometric-authorized Keystore operation.
 * No plaintext password, biometric image or reusable authentication flag is written to disk.
 * Each retrieved credential is submitted to the normal backend login endpoint.
 */
class AndroidBiometricSignIn(private val activity: FlutterFragmentActivity) {
    private val prefs = activity.getSharedPreferences("biometric_signin", Context.MODE_PRIVATE)
    private val alias = "farmestates.biometric.signin.v1"
    private var pending: MethodChannel.Result? = null
    private var prompt: BiometricPrompt? = null
    private val store get() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun attach(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "farmestates/biometric_signin")
            .setMethodCallHandler { call, result ->
                if (pending != null) {
                    result.error("busy", "Finish the current biometric request first.", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "status" -> result.success(status())
                        "disable" -> { clear(); result.success(null) }
                        "enable" -> {
                            val email = call.argument<String>("email")?.trim().orEmpty()
                            val password = call.argument<String>("password").orEmpty()
                            require(email.isNotEmpty() && password.isNotEmpty())
                            if (!available()) result.error("unavailable", "Set up a fingerprint in your phone settings first.", null)
                            else enable(email, password, result)
                        }
                        "credentials" -> {
                            if (!available()) result.error("unavailable", "Biometric sign-in is unavailable. Use your password.", null)
                            else unlock(result)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    // Changed enrollment, removed screen lock, missing/restored key, or corrupt data.
                    if (call.method != "status") runCatching { clear() }
                    result.error("invalidated", "Sign in with your password to set up fingerprint again.", null)
                }
            }
    }

    private fun available() = Build.VERSION.SDK_INT >= 23 &&
        BiometricManager.from(activity).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS

    private fun status(): Map<String, Any?> {
        val enabled = prefs.contains("encrypted") && runCatching { store.containsAlias(alias) }.getOrDefault(false)
        if (!enabled && prefs.contains("encrypted")) clear()
        return mapOf("available" to available(), "enabled" to enabled,
            "email" to if (enabled) prefs.getString("email", null) else null)
    }

    private fun clear() {
        prefs.edit().clear().commit()
        if (store.containsAlias(alias)) store.deleteEntry(alias)
    }

    private fun enable(email: String, password: String, result: MethodChannel.Result) {
        clear()
        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setUserAuthenticationRequired(true)
        if (Build.VERSION.SDK_INT >= 30) spec.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
        else {
            @Suppress("DEPRECATION")
            spec.setUserAuthenticationValidityDurationSeconds(-1)
        }
        if (Build.VERSION.SDK_INT >= 24) spec.setInvalidatedByBiometricEnrollment(true)
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(spec.build())
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, generator.generateKey())
        authenticate(cipher, result, "Enable fingerprint sign-in") { authenticated ->
            val bytes = JSONObject().put("email", email).put("password", password).toString().toByteArray(Charsets.UTF_8)
            try {
                val encrypted = authenticated.doFinal(bytes)
                check(prefs.edit().putString("email", email)
                    .putString("iv", Base64.encodeToString(authenticated.iv, Base64.NO_WRAP))
                    .putString("encrypted", Base64.encodeToString(encrypted, Base64.NO_WRAP)).commit())
            } finally { bytes.fill(0) }
            true
        }
    }

    private fun unlock(result: MethodChannel.Result) {
        val key = store.getKey(alias, null) as SecretKey
        val encrypted = Base64.decode(requireNotNull(prefs.getString("encrypted", null)), Base64.NO_WRAP)
        val iv = Base64.decode(requireNotNull(prefs.getString("iv", null)), Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        authenticate(cipher, result, "Sign in to Farm Estates") { authenticated ->
            val bytes = authenticated.doFinal(encrypted)
            try {
                val json = JSONObject(String(bytes, Charsets.UTF_8))
                mapOf("email" to json.getString("email"), "password" to json.getString("password"))
            } finally { bytes.fill(0) }
        }
    }

    private fun authenticate(cipher: Cipher, result: MethodChannel.Result, title: String, work: (Cipher) -> Any) {
        pending = result
        prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(auth: BiometricPrompt.AuthenticationResult) {
                    val completion = pending ?: return
                    pending = null
                    try { completion.success(work(requireNotNull(auth.cryptoObject?.cipher))) }
                    catch (_: Exception) {
                        runCatching { clear() }
                        completion.error("invalidated", "Sign in with your password to set up fingerprint again.", null)
                    }
                    prompt = null
                }
                override fun onAuthenticationError(code: Int, message: CharSequence) {
                    val completion = pending ?: return
                    pending = null
                    prompt = null
                    if (code in listOf(BiometricPrompt.ERROR_CANCELED, BiometricPrompt.ERROR_USER_CANCELED, BiometricPrompt.ERROR_NEGATIVE_BUTTON))
                        completion.success(null)
                    else completion.error("authentication_failed", "Fingerprint unavailable or locked. Use your password and try again later.", null)
                }
            })
        val info = BiometricPrompt.PromptInfo.Builder().setTitle(title)
            .setSubtitle("Use your fingerprint or supported secure biometric")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .setNegativeButtonText("Use password").build()
        try { prompt!!.authenticate(info, BiometricPrompt.CryptoObject(cipher)) }
        catch (error: Exception) { pending = null; prompt = null; throw error }
    }

    fun dispose() {
        val completion = pending
        pending = null
        prompt?.cancelAuthentication()
        prompt = null
        completion?.success(null)
    }
}
