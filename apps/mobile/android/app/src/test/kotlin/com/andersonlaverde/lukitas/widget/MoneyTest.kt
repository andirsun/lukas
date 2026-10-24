package com.andersonlaverde.lukitas.widget

import org.junit.Assert.assertEquals
import org.junit.Test

/** The same cases as test/money/format_test.dart: the widget writes money as the app does. */
class MoneyTest {
    private val nbsp = " "

    @Test
    fun `pesos the Colombian way, and with the code in English`() {
        assertEquals("$50.000", formatMoney(5000000, "COP", "es"))
        assertEquals("$4.300.000", formatMoney(430000000, "COP", "es"))
        assertEquals("COP${nbsp}50,000", formatMoney(5000000, "COP", "en"))
        assertEquals("$0", formatMoney(0, "COP", "es"))
    }

    @Test
    fun `euros and dollars by language`() {
        assertEquals("562,92$nbsp€", formatMoney(56292, "EUR", "es"))
        assertEquals("€562.92", formatMoney(56292, "EUR", "en"))
        assertEquals("€1,234.56", formatMoney(123456, "EUR", "en"))
        assertEquals("562,92${nbsp}US$", formatMoney(56292, "USD", "es"))
        assertEquals("$1,234.56", formatMoney(123456, "USD", "en"))
    }

    @Test
    fun `Spanish does not group four digits, except pesos`() {
        assertEquals("1234,56$nbsp€", formatMoney(123456, "EUR", "es"))
        assertEquals("12.345,00$nbsp€", formatMoney(1234500, "EUR", "es"))
        assertEquals("4.300.000,00$nbsp€", formatMoney(430000000, "EUR", "es"))
        assertEquals("$1.235", formatMoney(123456, "COP", "es"))
    }

    @Test
    fun `negatives use the real minus sign`() {
        assertEquals("−6,08$nbsp€", formatMoney(-608, "EUR", "es"))
        assertEquals("−€6.08", formatMoney(-608, "EUR", "en"))
        assertEquals("−$50.000", formatMoney(-5000000, "COP", "es"))
        assertEquals("−COP${nbsp}50,000", formatMoney(-5000000, "COP", "en"))
        assertEquals("$0", formatMoney(-5, "COP", "es"))
    }

    @Test
    fun `whole currencies round half away from zero`() {
        assertEquals("$2", formatMoney(150, "COP", "es"))
        assertEquals("$563", formatMoney(56292, "COP", "es"))
        assertEquals("−$2", formatMoney(-150, "COP", "es"))
        assertEquals("50.000${nbsp}CLP", formatMoney(5000000, "CLP", "es"))
        assertEquals("CLP${nbsp}50,000", formatMoney(5000000, "CLP", "en"))
    }
}
