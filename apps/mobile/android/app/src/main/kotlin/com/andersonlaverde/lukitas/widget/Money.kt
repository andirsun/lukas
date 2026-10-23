package com.andersonlaverde.lukitas.widget

// Money the way the app writes it (lib/money/format.dart, itself the web's): the widget and its
// refresh job draw amounts with no Flutter running. MoneyTest runs the Dart tests' cases.

/** Every amount is stored in hundredths of the currency, whatever its ISO exponent. */
private const val MINOR_UNIT = 100L

/** Currencies shown without decimals; stored in hundredths like the rest. */
private val WHOLE_UNIT = setOf("COP", "CLP")

private const val MINUS = "−"
private const val NBSP = " "

private class Style(val symbol: String, val attached: Boolean)

private fun style(currency: String, spanish: Boolean): Style = when (currency) {
    // Colombians write pesos as "$50.000"; in English the code stays ("$50,000" reads as dollars).
    "COP" -> if (spanish) Style("$", attached = true) else Style("COP", attached = false)
    "EUR" -> Style("€", attached = !spanish)
    "USD" -> if (spanish) Style("US$", attached = false) else Style("$", attached = true)
    else -> Style(currency, attached = false)
}

/** [digits] with [separator] between groups of three; Spanish outside pesos leaves four digits alone. */
private fun grouped(digits: String, separator: String, minTwo: Boolean): String {
    if (digits.length <= 3 || (minTwo && digits.length == 4)) return digits
    val out = StringBuilder()
    val first = digits.length % 3
    if (first > 0) out.append(digits, 0, first)
    var i = first
    while (i < digits.length) {
        if (out.isNotEmpty()) out.append(separator)
        out.append(digits, i, i + 3)
        i += 3
    }
    return out.toString()
}

/** Formats integer minor units (hundredths) in [currency] for [locale] ("es" or "en"). */
fun formatMoney(cents: Long, currency: String, locale: String): String {
    val spanish = locale == "es"
    val style = style(currency, spanish)
    val whole = currency in WHOLE_UNIT
    val abs = kotlin.math.abs(cents)
    // Whole currencies round half away from zero, as Intl does.
    val units = if (whole) (abs + MINOR_UNIT / 2) / MINOR_UNIT else abs / MINOR_UNIT
    val fraction = (abs % MINOR_UNIT).toString().padStart(2, '0')
    val colombian = currency == "COP" && spanish
    val figure = StringBuilder(
        grouped(units.toString(), if (spanish) "." else ",", minTwo = spanish && !colombian),
    )
    if (!whole) figure.append(if (spanish) "," else ".").append(fraction)

    val zero = if (whole) units == 0L else abs == 0L
    val prefix = if (!zero && cents < 0) MINUS else ""
    // Spanish puts the symbol after the figure, except the Colombian peso's "$".
    if (spanish && !colombian) return "$prefix$figure$NBSP${style.symbol}"
    return "$prefix${style.symbol}${if (style.attached) "" else NBSP}$figure"
}

/** [formatMoney] for an [Int] amount. */
fun formatMoney(cents: Int, currency: String, locale: String): String =
    formatMoney(cents.toLong(), currency, locale)
