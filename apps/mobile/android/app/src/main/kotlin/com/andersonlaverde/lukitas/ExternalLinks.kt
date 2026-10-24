package com.andersonlaverde.lukitas

import android.content.Intent
import android.net.Uri

/**
 * What the app asks the phone to open for it (lib/settings/url_opener.dart, the `openUrl` call of the
 * `lukitas/device` channel): a web page (`http`, `https`: "Más en la web") or an email to write
 * (`mailto`: "Comentarios e ideas"). Nothing else: a `javascript:`, `intent:`, `file:`, `content:`,
 * `tel:`, `sms:` or `market:` address is refused, whoever sent it, so the channel is no way to start
 * an arbitrary activity.
 */
object ExternalLinks {
    /** The address's scheme in lower case, or null when it has none that is well formed. */
    fun schemeOf(address: String): String? {
        val colon = address.indexOf(':')
        if (colon <= 0) return null
        val scheme = address.substring(0, colon)
        // A leading space or control character is not a scheme: it is refused whole.
        if (!scheme[0].isAsciiLetter() || !scheme.all { it.isAsciiLetter() || it.isAsciiDigit() || it in "+-." }) {
            return null
        }
        return scheme.lowercase()
    }

    /** The intent that opens [address], or null when the app does not open that kind of address. */
    fun intentFor(address: String?): Intent? {
        if (address == null) return null
        return when (schemeOf(address)) {
            "http", "https" -> Intent(Intent.ACTION_VIEW, Uri.parse(address)).addCategory(Intent.CATEGORY_BROWSABLE)
            "mailto" -> mailIntent(address)
            else -> null
        }
    }

    /**
     * A message to write: the email apps (and only they: the intent's data is a bare `mailto:`) get the
     * address, the subject and the body as extras, decoded. Any other header the link carries
     * (`cc`, `bcc`, `attach`...) is dropped: a link cannot add recipients or files.
     */
    private fun mailIntent(address: String): Intent {
        val spec = address.substring("mailto:".length)
        val query = spec.indexOf('?')
        val to = Uri.decode(if (query < 0) spec else spec.substring(0, query)).trim()
        val headers = if (query < 0) emptyList() else spec.substring(query + 1).split('&')
        fun header(name: String): String? = headers
            .map { it.substringBefore('=') to it.substringAfter('=', "") }
            .firstOrNull { Uri.decode(it.first).equals(name, ignoreCase = true) }
            ?.let { Uri.decode(it.second) }
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
        if (to.isNotEmpty()) intent.putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
        header("subject")?.let { intent.putExtra(Intent.EXTRA_SUBJECT, it) }
        header("body")?.let { intent.putExtra(Intent.EXTRA_TEXT, it) }
        return intent
    }

    private fun Char.isAsciiLetter() = this in 'a'..'z' || this in 'A'..'Z'

    private fun Char.isAsciiDigit() = this in '0'..'9'
}
