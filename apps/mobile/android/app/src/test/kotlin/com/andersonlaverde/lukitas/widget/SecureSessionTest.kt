package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The refresh job reads the app's secure storage and must never change it: not on a Keystore
 * error, not on a value it cannot decrypt (Robolectric has no Android Keystore, so every decrypt
 * here fails, as a broken Keystore would).
 */
@RunWith(RobolectricTestRunner::class)
class SecureSessionTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    /** Every SharedPreferences file the plugin uses, as it was written by the app. */
    private val files = listOf(
        "FlutterSecureStorage",
        "FlutterSecureKeyStorage",
        "FlutterSecureStorageConfiguration:FlutterSecureStorage",
        "FlutterSecureStorageConfiguration",
    )

    private fun everything(): Map<String, Map<String, *>> =
        files.associateWith { context.getSharedPreferences(it, Context.MODE_PRIVATE).all.toMap() }

    /** The plugin's key prefix for the app's options (its default: Dart sends an empty one). */
    private val prefix = FlutterSecureStorageConfig(SecureStorageSession.DART_DEFAULT_OPTIONS).sharedPreferencesKeyPrefix

    @Before
    fun storeLikeTheApp() {
        // What a signed-in app leaves (values are ciphertexts nobody here can decrypt).
        context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE).edit()
            .putString("${prefix}_session.token", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
            .putString("${prefix}_session.guest", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=")
            .putString("${prefix}_setting.server", "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=")
            .commit()
        context.getSharedPreferences("FlutterSecureKeyStorage", Context.MODE_PRIVATE).edit()
            .putString("AESVGhpcyBpcyB0aGUga2V5IGZvciBhIHNlY3VyZSBzdG9yYWdlIEFFUyBLZXkK", "DDDD")
            .commit()
        context.getSharedPreferences("FlutterSecureStorageConfiguration:FlutterSecureStorage", Context.MODE_PRIVATE)
            .edit()
            .putString("FlutterSecureSAlgorithmKey", "RSA_ECB_OAEPwithSHA_256andMGF1Padding")
            .putString("FlutterSecureSAlgorithmStorage", "AES_GCM_NoPadding")
            .commit()
    }

    @Test
    fun `the worker never lets the plugin reset or migrate, and reads where the app writes`() {
        val config = FlutterSecureStorageConfig(SecureStorageSession.WORKER_OPTIONS)
        assertFalse(config.shouldDeleteOnFailure())
        assertFalse(config.shouldMigrateOnAlgorithmChange())
        val app = FlutterSecureStorageConfig(SecureStorageSession.DART_DEFAULT_OPTIONS)
        assertEquals(app.effectiveDataPrefsName, config.effectiveDataPrefsName)
        assertEquals(app.effectiveKeyStoragePrefsName, config.effectiveKeyStoragePrefsName)
        assertEquals(app.sharedPreferencesKeyPrefix, config.sharedPreferencesKeyPrefix)
        assertEquals(app.prefOptionKeyCipherAlgorithm, config.prefOptionKeyCipherAlgorithm)
        assertEquals(app.prefOptionStorageCipherAlgorithm, config.prefOptionStorageCipherAlgorithm)
        assertEquals(app.keyAliasSuffix, config.keyAliasSuffix)
    }

    @Test
    fun `a Keystore or decrypt failure reads nothing and leaves secure storage untouched`() {
        val before = everything()
        // The plugin's own initialize and read run (the Keystore key is said to be there) and fail.
        val session = SecureStorageSession(context, keystoreHasKey = { true })
        assertEquals("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", session.mark())
        assertNull(session.token())
        assertEquals(ServerSetting.Unreadable, session.server())
        assertEquals(before, everything())
    }

    @Test
    fun `no Keystore key at all - the plugin is not even started, nothing is created`() {
        val before = everything()
        val session = SecureStorageSession(context, keystoreHasKey = { false })
        assertNull(session.token())
        assertEquals(ServerSetting.Unreadable, session.server())
        assertEquals(before, everything())
    }

    @Test
    fun `missing pieces of the app's storage - nothing is read and nothing is written`() {
        context.getSharedPreferences("FlutterSecureKeyStorage", Context.MODE_PRIVATE).edit().clear().commit()
        val before = everything()
        assertNull(SecureStorageSession(context, keystoreHasKey = { true }).token())
        assertEquals(before, everything())
    }

    @Test
    fun `signed out and no server chosen read as such, without decrypting`() {
        context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE).edit().clear().commit()
        val session = SecureStorageSession(context, keystoreHasKey = { true })
        assertNull(session.mark())
        assertNull(session.token())
        assertEquals(ServerSetting.Default, session.server())
    }
}
