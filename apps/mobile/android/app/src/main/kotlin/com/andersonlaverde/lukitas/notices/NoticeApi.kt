package com.andersonlaverde.lukitas.notices

import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale

sealed interface ApiResult<out T> {
    data class Ok<T>(val value: T) : ApiResult<T>

    /** 401: the server no longer knows the session. */
    data object Unauthorized : ApiResult<Nothing>

    /** Offline, a timeout, a server error, an answer that cannot be read. */
    data object Failed : ApiResult<Nothing>
}

/** What the notices need of `GET /v1/me`. */
data class NoticeProfile(
    /** The profile's IANA zone: where "today" is read. */
    val timezone: String?,
    /** A guest: no email yet. */
    val anonymous: Boolean,
)

/**
 * The two reads the notices make, as the app does (lib/api/client.dart): `<server>/api`, the bearer
 * token, and the phone's time zone and language on every request. With the platform's
 * HttpURLConnection: no HTTP library, nothing from Google. They only read: a notice never changes
 * anything on the server, and `x-lukas-background: 1` keeps them from counting as activity.
 */
class NoticeApi(
    private val connectTimeoutMillis: Int = 10_000,
    private val readTimeoutMillis: Int = 20_000,
) {
    /** `GET /v1/me`: the zone and whether the account is a guest. */
    fun profile(server: String, token: String): ApiResult<NoticeProfile> =
        when (val answer = get(server, token, "/v1/me")) {
            is ApiResult.Ok -> try {
                val doc = JSONObject(answer.value)
                ApiResult.Ok(
                    NoticeProfile(
                        timezone = doc.optString("timezone").takeIf { it.isNotEmpty() },
                        anonymous = doc.getBoolean("isAnonymous"),
                    ),
                )
            } catch (_: JSONException) {
                ApiResult.Failed
            }
            ApiResult.Unauthorized -> ApiResult.Unauthorized
            ApiResult.Failed -> ApiResult.Failed
        }

    /**
     * The names of the recurring payments still pending on [today], from
     * `GET /v1/transactions?status=pending&month=` (the month of [today], in the profile's zone),
     * oldest first. The list comes newest first and in pages (cursor, at most 200 each): paging
     * stops once a page reaches days before today.
     */
    fun dueToday(server: String, token: String, today: LocalDate): ApiResult<List<String>> {
        val month = today.toString().take(7)
        val due = mutableListOf<Pair<String, String>>()
        var cursor: String? = null
        repeat(MAX_PAGES) {
            val query = "status=pending&month=$month&limit=$PAGE_SIZE" + (cursor?.let { "&cursor=$it" } ?: "")
            val body = when (val answer = get(server, token, "/v1/transactions?$query")) {
                is ApiResult.Ok -> answer.value
                ApiResult.Unauthorized -> return ApiResult.Unauthorized
                ApiResult.Failed -> return ApiResult.Failed
            }
            try {
                val doc = JSONObject(body)
                val items = doc.getJSONArray("items")
                var oldest: String? = null
                for (i in 0 until items.length()) {
                    val item = items.getJSONObject(i)
                    val date = item.getString("date")
                    oldest = date
                    if (date == today.toString() &&
                        item.optString("status") == "pending" &&
                        !item.isNull("recurrenceId") &&
                        item.optString("recurrenceId").isNotEmpty()
                    ) {
                        due += item.optString("createdAt") to item.getString("name")
                    }
                }
                val next = if (doc.isNull("nextCursor")) null else doc.getString("nextCursor")
                // Newest first: once a page reaches an earlier day, nothing due today is left.
                if (next == null || oldest == null || oldest < today.toString()) {
                    return ApiResult.Ok(due.sortedWith(compareBy({ it.first }, { it.second })).map { it.second })
                }
                cursor = next
            } catch (_: JSONException) {
                return ApiResult.Failed
            }
        }
        return ApiResult.Failed
    }

    private fun get(server: String, token: String, path: String): ApiResult<String> {
        val url = try {
            URL("${server.trimEnd('/')}/api$path")
        } catch (_: IOException) {
            return ApiResult.Failed
        }
        if (url.protocol != "https" && url.protocol != "http") return ApiResult.Failed
        val connection = try {
            url.openConnection() as HttpURLConnection
        } catch (_: IOException) {
            return ApiResult.Failed
        }
        return try {
            connection.connectTimeout = connectTimeoutMillis
            connection.readTimeout = readTimeoutMillis
            connection.instanceFollowRedirects = false
            connection.setRequestProperty("Authorization", "Bearer $token")
            connection.setRequestProperty("Accept", "application/json")
            // A job the person did not start is not activity: the API reads the session without
            // sliding it (x-lukas-background), so these reads never postpone the guest cleanup.
            connection.setRequestProperty("x-lukas-background", "1")
            connection.setRequestProperty("x-lukas-timezone", ZoneId.systemDefault().id)
            connection.setRequestProperty("x-lukas-locale", Locale.getDefault().toLanguageTag())
            when (connection.responseCode) {
                200 -> ApiResult.Ok(connection.inputStream.bufferedReader().use { it.readText() })
                401 -> ApiResult.Unauthorized
                else -> ApiResult.Failed
            }
        } catch (_: IOException) {
            ApiResult.Failed
        } finally {
            connection.disconnect()
        }
    }

    private companion object {
        /** The API's largest page. */
        const val PAGE_SIZE = 200
        const val MAX_PAGES = 10
    }
}
