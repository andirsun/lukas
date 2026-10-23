package com.andersonlaverde.lukitas.passkeys

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.CancellationSignal
import androidx.credentials.CreateCredentialResponse
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Passkeys through Android's Credential Manager, on the `lukitas/passkeys` channel (lib/api/passkeys.dart).
 *
 * Only `androidx.credentials:credentials` is used, never `credentials-play-services-auth`: on Android 14
 * (API 34) and newer the library talks to the platform's own Credential Manager, and the person's
 * passkey provider (Proton Pass, Bitwarden, KeePassDX, Samsung Pass, Google Password Manager…) answers.
 * Below API 34 it would need Play Services, so passkeys are simply not offered there.
 *
 * Methods: `isSupported` → Boolean; `get(requestJson)` → the assertion as JSON; `getAvailable(requestJson)`
 * → the same, but only for a passkey the provider can offer at once (nothing is shown when there
 * is none: `no_credential`); `create(requestJson)` → the attestation as JSON. Errors: `cancelled`
 * (the person closed the prompt), `no_credential` (no passkey for this server), `unsupported`,
 * `failed`.
 */
class PasskeyChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "lukitas/passkeys")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "get" -> withRequest(call, result) { get(it, result, immediate = false) }
            "getAvailable" -> withRequest(call, result) { get(it, result, immediate = true) }
            "create" -> withRequest(call, result) { create(it, result) }
            else -> result.notImplemented()
        }
    }

    private fun withRequest(call: MethodCall, result: MethodChannel.Result, run: (String) -> Unit) {
        val json = call.arguments as? String
        when {
            json == null -> result.error("failed", "Missing WebAuthn options", null)
            !isSupported() -> result.error("unsupported", "Passkeys need Android 14 and a provider", null)
            else -> run(json)
        }
    }

    /** Android 14+ with at least one credential provider installed. */
    private fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        val providers = activity.packageManager.queryIntentServices(
            Intent(CREDENTIAL_PROVIDER_SERVICE),
            PackageManager.ResolveInfoFlags.of(0),
        )
        return providers.isNotEmpty()
    }

    private fun get(requestJson: String, result: MethodChannel.Result, immediate: Boolean) {
        val request = GetCredentialRequest(
            listOf(GetPublicKeyCredentialOption(requestJson)),
            preferImmediatelyAvailableCredentials = immediate,
        )
        CredentialManager.create(activity).getCredentialAsync(
            activity,
            request,
            CancellationSignal(),
            activity.mainExecutor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    val credential = response.credential
                    if (credential is PublicKeyCredential) {
                        result.success(credential.authenticationResponseJson)
                    } else {
                        result.error("failed", "Not a passkey: ${credential.type}", null)
                    }
                }

                override fun onError(e: GetCredentialException) {
                    when (e) {
                        is GetCredentialCancellationException -> result.error("cancelled", e.message, null)
                        is NoCredentialException -> result.error("no_credential", e.message, null)
                        else -> result.error("failed", "${e.type}: ${e.message}", null)
                    }
                }
            },
        )
    }

    private fun create(requestJson: String, result: MethodChannel.Result) {
        CredentialManager.create(activity).createCredentialAsync(
            activity,
            CreatePublicKeyCredentialRequest(requestJson),
            CancellationSignal(),
            activity.mainExecutor,
            object : CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException> {
                override fun onResult(response: CreateCredentialResponse) {
                    if (response is CreatePublicKeyCredentialResponse) {
                        result.success(response.registrationResponseJson)
                    } else {
                        result.error("failed", "Not a passkey: ${response.type}", null)
                    }
                }

                override fun onError(e: CreateCredentialException) {
                    when (e) {
                        is CreateCredentialCancellationException -> result.error("cancelled", e.message, null)
                        else -> result.error("failed", "${e.type}: ${e.message}", null)
                    }
                }
            },
        )
    }

    companion object {
        /** The action a credential provider's service declares (android.service.credentials). */
        private const val CREDENTIAL_PROVIDER_SERVICE = "android.service.credentials.CredentialProviderService"
    }
}
