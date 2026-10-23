package com.andersonlaverde.lukitas.notices

import android.content.Context
import com.andersonlaverde.lukitas.R
import java.util.Locale

/**
 * The words of the two notices, from the Android string resources (values/ is Spanish, values-en/
 * English), in the language the app is set to; null follows the phone.
 */
object NoticeText {
    /** The Context whose resources speak [language] (`es` or `en`); [context] itself for any other. */
    fun localized(context: Context, language: String?): Context {
        if (language != "es" && language != "en") return context
        val configuration = android.content.res.Configuration(context.resources.configuration)
        configuration.setLocale(Locale(language))
        return context.createConfigurationContext(configuration)
    }

    /** "Hoy vencen Arriendo y Spotify" / "Rent and Spotify are due today". */
    fun due(context: Context, names: List<String>, language: String?): String {
        val speaking = localized(context, language)
        val clean = names.map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        if (clean.isEmpty()) return ""
        val resource = if (clean.size == 1) R.string.notice_due_one else R.string.notice_due_many
        return speaking.getString(resource, join(speaking, clean))
    }

    /** The guest warning, 15 days before the server forgets an inactive guest. */
    fun guestWarning(context: Context, language: String?): String =
        localized(context, language).getString(R.string.notice_guest)

    /** "A", "A y B", "A, B y C". */
    private fun join(context: Context, names: List<String>): String {
        if (names.size == 1) return names[0]
        val and = context.getString(if (startsWithI(names.last())) R.string.notice_and_i else R.string.notice_and)
        return names.dropLast(1).joinToString(", ") + " $and " + names.last()
    }

    /**
     * Spanish says "e" instead of "y" before the sound i: Internet, Hipoteca, Ítaca; not before a
     * glide, as in Hielo or Iatrogenia. (English has the same word for both, so this is harmless
     * there.)
     */
    private fun startsWithI(name: String): Boolean {
        val word = name.trim().lowercase(Locale.ROOT).trimStart { !it.isLetterOrDigit() }
        val glide = "aeouáéóú"
        return when {
            word.startsWith("hi") -> word.getOrNull(2)?.let { it !in glide } ?: true
            word.startsWith("í") -> true
            word.startsWith("i") -> word.getOrNull(1)?.let { it !in glide } ?: true
            else -> false
        }
    }
}
