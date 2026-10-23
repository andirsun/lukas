package com.andersonlaverde.lukitas.notices

import android.content.Context

/**
 * What the two notices' jobs need to know, kept where Kotlin can read it (the app's Settings live
 * in flutter_secure_storage, which a background job has no business reading): the two switches,
 * the profile's time zone and the language the notices are written in. The app writes them when it
 * schedules or cancels (lib/notices). Nothing secret: the session token is never copied here.
 */
class NoticeSettings(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    /** "Hoy vence…" is on: the job posts and schedules the next day. */
    var dueEnabled: Boolean
        get() = preferences.getBoolean(DUE, false)
        set(value) = put { putBoolean(DUE, value) }

    /** The guest warning is on. */
    var guestEnabled: Boolean
        get() = preferences.getBoolean(GUEST, false)
        set(value) = put { putBoolean(GUEST, value) }

    /** The profile's IANA zone, as last learned; null when never. */
    var zone: String?
        get() = preferences.getString(ZONE, null)
        set(value) = put { if (value == null) remove(ZONE) else putString(ZONE, value) }

    /** `es` or `en` (the app's choice); null follows the phone. */
    var language: String?
        get() = preferences.getString(LANGUAGE, null)
        set(value) = put { if (value == null) remove(LANGUAGE) else putString(LANGUAGE, value) }

    /** The local day (`YYYY-MM-DD`, in the profile's zone) "Hoy vence…" was last posted for. */
    var lastDueDay: String?
        get() = preferences.getString(LAST_DUE_DAY, null)
        set(value) = put { if (value == null) remove(LAST_DUE_DAY) else putString(LAST_DUE_DAY, value) }

    fun clear() {
        preferences.edit().clear().commit()
    }

    // commit(): a job that starts a moment later must find what was just chosen.
    private fun put(change: android.content.SharedPreferences.Editor.() -> Unit) {
        preferences.edit().apply(change).commit()
    }

    private companion object {
        const val FILE = "lukitas.notices"
        const val DUE = "due"
        const val GUEST = "guest"
        const val ZONE = "zone"
        const val LANGUAGE = "language"
        const val LAST_DUE_DAY = "lastDueDay"
    }
}
