package com.andersonlaverde.lukitas.widget

import android.content.Context
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import com.it_nomads.fluttersecurestorage.SecurePreferencesCallback
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** The session the app keeps on the phone, as the refresh job reads it. */
interface SessionSource {
    /** The bearer token, or null when signed out (or unreadable). */
    fun token(): String?

    /**
     * Changes whenever the stored token is replaced or removed, without decrypting anything (the
     * stored ciphertext: a new write has a new IV); null when no token is stored. The refresh job
     * compares it before and after its request, so a sign-out (or another sign-in) meanwhile drops
     * what it fetched.
     */
    fun mark(): String?

    /** The server picked in Settings, or null for the app's default. */
    fun server(): String?
}

/**
 * [SessionSource] over the very storage the app writes with `flutter_secure_storage` (lib/api/
 * session.dart's SessionStore, lib/settings/settings_store.dart): the plugin's own Java classes,
 * with the same options Dart sends, read the same SharedPreferences file and decrypt with the same
 * Android Keystore key. There is never a second copy of the token.
 *
 * Nothing here ever writes: reading only, and only once a token is stored (so this never creates
 * the Keystore key the plugin would otherwise create on first use).
 */
class SecureStorageSession(private val context: Context) : SessionSource {
    private val config = FlutterSecureStorageConfig(DART_DEFAULT_OPTIONS)
    private val storage by lazy { FlutterSecureStorage(context) }

    private fun storedKey(key: String) = "${config.sharedPreferencesKeyPrefix}_$key"

    private fun raw(key: String): String? = context
        .getSharedPreferences(config.effectiveDataPrefsName, Context.MODE_PRIVATE)
        .getString(storedKey(key), null)

    override fun mark(): String? = raw(TOKEN_KEY)

    override fun token(): String? = read(TOKEN_KEY)?.takeIf { it.isNotEmpty() }

    override fun server(): String? = read(SERVER_KEY)?.takeIf { it.isNotEmpty() }

    /** [key] decrypted, or null when it is not stored or cannot be read. */
    private fun read(key: String): String? {
        if (raw(key) == null) return null
        return try {
            await<Void?> { storage.initialize(config, it) } ?: return null
            await<String?> { storage.read(storedKey(key), it) }?.value
        } catch (_: Exception) {
            null
        }
    }

    private class Answer<T>(val value: T)

    /**
     * Runs [call] and waits for its callback, which the plugin makes on this thread or another,
     * for at most [WAIT_SECONDS]. Null when it failed or took too long.
     */
    private fun <T> await(call: (SecurePreferencesCallback<T>) -> Unit): Answer<T>? {
        val done = CountDownLatch(1)
        var answer: Answer<T>? = null
        call(object : SecurePreferencesCallback<T> {
            override fun onSuccess(result: T) {
                answer = Answer(result)
                done.countDown()
            }

            override fun onError(e: Exception) {
                done.countDown()
            }
        })
        return if (done.await(WAIT_SECONDS, TimeUnit.SECONDS)) answer else null
    }

    companion object {
        /** lib/api/session.dart's `SessionStore.tokenKey`. */
        const val TOKEN_KEY = "session.token"

        /** lib/settings/settings_store.dart's `serverUrlKey`. */
        const val SERVER_KEY = "setting.server"

        private const val WAIT_SECONDS = 10L

        /**
         * What Dart sends with every call, `AndroidOptions.defaultOptions.toMap()` of
         * flutter_secure_storage 11.2.0 (the app uses `const FlutterSecureStorage()`).
         * test/tooling/widget_android_test.dart fails when the plugin's defaults change.
         */
        val DART_DEFAULT_OPTIONS: Map<String, Any> = mapOf(
            "resetOnError" to "true",
            "migrateOnAlgorithmChange" to "true",
            "migrateWithBackup" to "false",
            "enforceBiometrics" to "false",
            "requireBiometricsPerOperation" to "false",
            "keyCipherAlgorithm" to "RSA_ECB_OAEPwithSHA_256andMGF1Padding",
            "storageCipherAlgorithm" to "AES_GCM_NoPadding",
            "biometricType" to "biometricOrDeviceCredential",
            "requireBiometricConfirmation" to "true",
            "preferencesKeyPrefix" to "",
            "storageNamespace" to "",
            "biometricPromptTitle" to "Authenticate to access",
            "biometricPromptSubtitle" to "Use biometrics or device credentials",
            "biometricPromptNegativeButton" to "Cancel",
        )
    }
}
