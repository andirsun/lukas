package com.andersonlaverde.lukitas.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONException
import org.json.JSONObject
import java.time.Instant
import java.time.format.DateTimeParseException

/**
 * What the widget draws, as the app writes it (lib/home/widget_snapshot.dart, which documents the
 * shape) and the refresh job too ([RefreshWorker]): one JSON document, version 2, under [KEY] in
 * home_widget's SharedPreferences file [PREFS].
 *
 * Amounts are cents, as the API sends them. A snapshot that is missing, of another version, signed
 * out, or missing a figure reads as signed out: "Abre Lukitas para empezar", never a stale figure.
 */
data class WidgetSnapshot(
    val signedIn: Boolean,
    val remaining: Long = 0,
    val spent: Long = 0,
    val budgetTotal: Long = 0,
    val currency: String = "",
    /** "es" or "en": the widget's words and how amounts are written. Null: the phone's. */
    val locale: String? = null,
    /** `YYYY-MM`. */
    val month: String = "",
    /** "happy" or "worried". */
    val mood: String = "happy",
    val updatedAt: Instant? = null,
    val hideAmount: Boolean = false,
    /** "dark", "light" or "system": the theme picked in the app. */
    val theme: String = "dark",
    /**
     * When the refresh job last failed to reach the server (offline, a server error), if after
     * [updatedAt]: the figures are then marked "hace un rato". Written by [RefreshWorker] only; the
     * app's writes drop it (their figures are fresh) and its choice patches keep it.
     */
    val refreshFailedAt: Instant? = null,
) {
    fun toJson(): String {
        val doc = JSONObject()
            .put("v", VERSION)
            .put("signedIn", signedIn)
            .put("hideAmount", hideAmount)
            .put("theme", theme)
        if (locale != null) doc.put("locale", locale)
        if (signedIn) {
            doc.put("remaining", remaining)
                .put("spent", spent)
                .put("budgetTotal", budgetTotal)
                .put("currency", currency)
                .put("month", month)
                .put("mood", mood)
                .put("updatedAt", updatedAt?.toString())
            if (refreshFailedAt != null) doc.put("refreshFailedAt", refreshFailedAt.toString())
        }
        return doc.toString()
    }

    companion object {
        const val PREFS = "HomeWidgetPreferences"
        const val KEY = "lukitas.widget.snapshot"
        const val VERSION = 2

        /** The snapshot in [json], or null when there is none of this version. */
        fun parse(json: String?): WidgetSnapshot? {
            if (json == null) return null
            val doc = try {
                JSONObject(json)
            } catch (_: JSONException) {
                return null
            }
            if (doc.optInt("v", -1) != VERSION) return null
            val hideAmount = doc.optBoolean("hideAmount", false)
            val theme = doc.optString("theme", "dark")
            val locale = doc.optString("locale", "").takeIf { it == "es" || it == "en" }
            val signedOut = WidgetSnapshot(
                signedIn = false,
                locale = locale,
                hideAmount = hideAmount,
                theme = theme,
            )
            if (!doc.optBoolean("signedIn", false)) return signedOut
            val figures = listOf("remaining", "spent", "budgetTotal", "currency", "month")
            if (figures.any { !doc.has(it) || doc.isNull(it) }) return signedOut
            return try {
                WidgetSnapshot(
                    signedIn = true,
                    remaining = doc.getLong("remaining"),
                    spent = doc.getLong("spent"),
                    budgetTotal = doc.getLong("budgetTotal"),
                    currency = doc.getString("currency"),
                    locale = locale,
                    month = doc.getString("month"),
                    mood = doc.optString("mood", "happy"),
                    updatedAt = instant(doc.optString("updatedAt", "")),
                    refreshFailedAt = instant(doc.optString("refreshFailedAt", "")),
                    hideAmount = hideAmount,
                    theme = theme,
                )
            } catch (_: JSONException) {
                signedOut
            }
        }

        private fun instant(text: String): Instant? = try {
            Instant.parse(text)
        } catch (_: DateTimeParseException) {
            null
        }

        fun preferences(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        /** What is stored now (null: nothing of this version). */
        fun read(context: Context): WidgetSnapshot? = parse(preferences(context).getString(KEY, null))
    }
}
