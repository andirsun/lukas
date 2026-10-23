package com.andersonlaverde.lukitas.widget

import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.time.ZoneId
import java.util.Locale

/** The month's figures from `GET /v1/summary` (apps/api/src/routes/summary.ts), in cents. */
data class SummaryFigures(
    val month: String,
    val budgetTotal: Long,
    val spent: Long,
    val remaining: Long,
    /** A category is near or over its limit (Lukitas is worried). */
    val worried: Boolean,
)

sealed interface SummaryResult {
    data class Ok(val figures: SummaryFigures) : SummaryResult

    /** 401: the server no longer knows the session. */
    data object Unauthorized : SummaryResult

    /** Offline, a timeout, a server error, an answer that cannot be read. */
    data object Failed : SummaryResult
}

/**
 * Asks the API for the month's summary as the app does (lib/api/client.dart): `<server>/api`, the
 * bearer token, and the phone's time zone and language on every request. With the platform's
 * HttpURLConnection: no HTTP library, nothing from Google.
 */
class SummaryFetcher(
    private val connectTimeoutMillis: Int = 10_000,
    private val readTimeoutMillis: Int = 20_000,
) {
    fun fetch(server: String, token: String): SummaryResult {
        val url = try {
            URL("${server.trimEnd('/')}/api/v1/summary")
        } catch (_: IOException) {
            return SummaryResult.Failed
        }
        if (url.protocol != "https" && url.protocol != "http") return SummaryResult.Failed
        val connection = try {
            url.openConnection() as HttpURLConnection
        } catch (_: IOException) {
            return SummaryResult.Failed
        }
        return try {
            connection.connectTimeout = connectTimeoutMillis
            connection.readTimeout = readTimeoutMillis
            connection.instanceFollowRedirects = false
            connection.setRequestProperty("Authorization", "Bearer $token")
            connection.setRequestProperty("Accept", "application/json")
            // Not activity: the API reads the session without sliding it, so a phone that only runs
            // this job does not keep a guest from the 60-day cleanup.
            connection.setRequestProperty("x-lukas-background", "1")
            connection.setRequestProperty("x-lukas-timezone", ZoneId.systemDefault().id)
            connection.setRequestProperty("x-lukas-locale", Locale.getDefault().toLanguageTag())
            when (connection.responseCode) {
                200 -> parse(connection.inputStream.bufferedReader().use { it.readText() })
                401 -> SummaryResult.Unauthorized
                else -> SummaryResult.Failed
            }
        } catch (_: IOException) {
            SummaryResult.Failed
        } finally {
            connection.disconnect()
        }
    }

    private fun parse(body: String): SummaryResult = try {
        val doc = JSONObject(body)
        val categories = doc.optJSONArray("categories")
        val worried = categories != null && (0 until categories.length()).any {
            categories.getJSONObject(it).optString("state", "ok") != "ok"
        }
        SummaryResult.Ok(
            SummaryFigures(
                month = doc.getString("month"),
                budgetTotal = doc.getLong("budgetTotal"),
                spent = doc.getLong("spent"),
                remaining = doc.getLong("remaining"),
                worried = worried,
            ),
        )
    } catch (_: JSONException) {
        SummaryResult.Failed
    }
}
