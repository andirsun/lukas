package com.andersonlaverde.lukitas.launch

import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * The app's own links (spec sections 7.1 and 7.2): `lukitas://add` opens the add sheet with the
 * keypad ready (the widget's ＋), `lukitas://capture` opens quick capture listening (the widget's 🎤
 * and the Quick Settings tile), `lukitas://due` opens home with the payments due today (the "Hoy
 * vence…" notice), `lukitas://progress` opens "Guarda tu progreso" (the guest warning). MainActivity keeps them from Flutter's router and hands them to Dart
 * (lib/launch/launch_links.dart), which opens them once the session has loaded.
 *
 * They reach the app only through [ALIAS], an activity-alias of `MainActivity` that is not exported
 * (AndroidManifest.xml): the widget and the tile start it as the app itself; no other app can,
 * so none can open the microphone. A link sent to the exported launcher activity is ignored.
 */
object LaunchLinks {
    const val SCHEME = "lukitas"
    val ADD: Uri = Uri.parse("lukitas://add")
    val CAPTURE: Uri = Uri.parse("lukitas://capture")

    /** The "Hoy vence…" notice (spec section 7.2): home, with the payments due today in view. */
    val DUE: Uri = Uri.parse("lukitas://due")

    /** The guest warning (spec section 7.2): "Guarda tu progreso". */
    val PROGRESS: Uri = Uri.parse("lukitas://progress")
    private val HOSTS = setOf("add", "capture", "due", "progress")

    /** The not-exported entry the links come through (an alias of `MainActivity`). */
    const val ALIAS = "com.andersonlaverde.lukitas.LaunchLinkAlias"

    /** What the widget's buttons and the tile start: this app's own link entry on [link]. */
    fun intent(context: Context, link: Uri): Intent =
        Intent(Intent.ACTION_VIEW, link)
            .setClassName(context, ALIAS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    /**
     * The `lukitas://add`, `capture`, `due` or `progress` link [intent] carries, or null. An activity
     * reopened from recents gets its first intent again: that one is not acted on twice.
     */
    fun linkOf(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        if (intent.component?.className != ALIAS) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val data = intent.data ?: return null
        if (data.scheme != SCHEME || data.host !in HOSTS) return null
        val path = data.path.orEmpty()
        if (path.isNotEmpty() && path != "/") return null
        return data.toString()
    }
}
