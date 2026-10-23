package com.andersonlaverde.lukitas.widget

import android.content.Context
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import com.it_nomads.fluttersecurestorage.NamespacedConfigSource
import com.it_nomads.fluttersecurestorage.SecurePreferencesCallback
import java.security.KeyStore
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** The server picked in Settings, as the refresh job finds it. */
sealed interface ServerSetting {
    /** Nothing chosen: the app's default server. */
    data object Default : ServerSetting

    data class Chosen(val url: String) : ServerSetting

    /** Something is stored but cannot be read: the job must not guess (nor send the token). */
    data object Unreadable : ServerSetting
}

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

    fun server(): ServerSetting
}

/** Whether the Android Keystore holds [alias] (a read: nothing is created). */
private fun androidKeystoreHasAlias(alias: String): Boolean = try {
    KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.containsAlias(alias)
} catch (_: Exception) {
    false
}

/**
 * [SessionSource] over the very storage the app writes with `flutter_secure_storage` (lib/api/
 * session.dart's SessionStore, lib/settings/settings_store.dart): the plugin's own Java classes
 * read the same SharedPreferences files and decrypt with the same Android Keystore key. There is
 * never a second copy of the token.
 *
 * It never writes, so a background run can never cost the person their session (a guest's token
 * is their only way back):
 * - the plugin runs with [WORKER_OPTIONS]: `resetOnError` and `migrateOnAlgorithmChange` off, so
 *   a Keystore or decrypt error is just an error (the plugin's own paths that delete or migrate
 *   stay closed); the app, with its own options, deals with such a store at its next start;
 * - the plugin is started only when everything it would otherwise create is already there (the
 *   algorithm markers, the wrapped data key, the Keystore key): a missing piece reads as
 *   unreadable instead.
 */
class SecureStorageSession(
    private val context: Context,
    private val keystoreHasKey: (String) -> Boolean = ::androidKeystoreHasAlias,
) : SessionSource {
    private val config = FlutterSecureStorageConfig(WORKER_OPTIONS)
    private val storage by lazy { FlutterSecureStorage(context) }

    private fun storedKey(key: String) = "${config.sharedPreferencesKeyPrefix}_$key"

    private fun raw(key: String): String? = context
        .getSharedPreferences(config.effectiveDataPrefsName, Context.MODE_PRIVATE)
        .getString(storedKey(key), null)

    override fun mark(): String? = raw(TOKEN_KEY)

    override fun token(): String? = read(TOKEN_KEY)?.takeIf { it.isNotEmpty() }

    override fun server(): ServerSetting {
        if (raw(SERVER_KEY) == null) return ServerSetting.Default
        val url = read(SERVER_KEY)?.takeIf { it.isNotEmpty() } ?: return ServerSetting.Unreadable
        return ServerSetting.Chosen(url)
    }

    /**
     * Whether the plugin can start without creating anything: the algorithms the app's data is
     * under are recorded and are the ones it uses, the wrapped data key is stored, and the
     * Keystore key that unwraps it exists. Reads only.
     */
    private fun everythingInPlace(): Boolean {
        val markers = NamespacedConfigSource(context, config.effectiveDataPrefsName)
        if (markers.getString(KEY_ALGORITHM_MARKER, null) != config.prefOptionKeyCipherAlgorithm) return false
        if (markers.getString(STORAGE_ALGORITHM_MARKER, null) != config.prefOptionStorageCipherAlgorithm) return false
        val keys = context.getSharedPreferences(config.effectiveKeyStoragePrefsName, Context.MODE_PRIVATE)
        if (!keys.contains(WRAPPED_KEY_PREF)) return false
        return keystoreHasKey("${context.packageName}$KEYSTORE_ALIAS${config.keyAliasSuffix}")
    }

    /** [key] decrypted, or null when it is not stored or cannot be read. */
    private fun read(key: String): String? {
        if (raw(key) == null || !everythingInPlace()) return null
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

        // Where flutter_secure_storage 11.2.0 keeps what it needs (StorageCipherFactory,
        // StorageCipherImplementationGCM, KeyCipherImplementationRSAOAEP; not public there).
        private const val KEY_ALGORITHM_MARKER = "FlutterSecureSAlgorithmKey"
        private const val STORAGE_ALGORITHM_MARKER = "FlutterSecureSAlgorithmStorage"
        private const val WRAPPED_KEY_PREF = "AESVGhpcyBpcyB0aGUga2V5IGZvciBhIHNlY3VyZSBzdG9yYWdlIEFFUyBLZXkK"
        private const val KEYSTORE_ALIAS = ".FlutterSecureStoragePluginKeyOAEP"

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

        /**
         * The worker's options: the app's (so the same files and keys are read), with the two
         * that can write turned off. A decrypt or Keystore error then fails closed.
         */
        val WORKER_OPTIONS: Map<String, Any> = DART_DEFAULT_OPTIONS + mapOf(
            "resetOnError" to "false",
            "migrateOnAlgorithmChange" to "false",
        )
    }
}
