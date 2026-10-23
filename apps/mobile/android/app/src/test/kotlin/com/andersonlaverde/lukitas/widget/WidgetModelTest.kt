package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.Instant
import java.time.ZoneId

/** What the widget says for each state (spec section 7.1), before it is drawn. */
@RunWith(RobolectricTestRunner::class)
class WidgetModelTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val zone = ZoneId.of("America/Bogota")
    private val now = Instant.parse("2026-10-22T20:00:00Z")

    private fun snapshot(
        remaining: Long = 150000000,
        spent: Long = 50000000,
        budgetTotal: Long = 200000000,
        currency: String = "COP",
        locale: String? = "es",
        month: String = "2026-10",
        mood: String = "happy",
        updatedAt: Instant = now.minusSeconds(60),
        hideAmount: Boolean = false,
        theme: String = "dark",
    ) = WidgetSnapshot(
        signedIn = true,
        remaining = remaining,
        spent = spent,
        budgetTotal = budgetTotal,
        currency = currency,
        locale = locale,
        month = month,
        mood = mood,
        updatedAt = updatedAt,
        hideAmount = hideAmount,
        theme = theme,
    )

    private fun figures(snapshot: WidgetSnapshot?) =
        widgetModel(context, snapshot, now, zone) as WidgetModel.Figures

    @Test
    fun `signed in with budgets it says what is left, with the month and its progress`() {
        val model = figures(snapshot())
        assertEquals("Te quedan", model.label)
        assertEquals("$1.500.000", model.amount)
        assertEquals(0.25f, model.progress!!, 0.0001f)
        assertEquals(Tone.GOOD, model.tone)
        assertEquals("Octubre", model.month)
        assertEquals(Mood.HAPPY, model.mood)
        assertNull(model.stale)
    }

    @Test
    fun `over the budgets it says by how much, in the over colour`() {
        val model = figures(snapshot(remaining = -50000000, spent = 250000000))
        assertEquals("Te pasaste", model.label)
        assertEquals("$500.000", model.amount)
        assertEquals(1f, model.progress!!, 0.0001f)
        assertEquals(Tone.OVER, model.tone)
    }

    @Test
    fun `a category near its limit makes Lukitas worried`() {
        val model = figures(snapshot(mood = "worried"))
        assertEquals(Mood.WORRIED, model.mood)
        assertEquals(Tone.NEAR, model.tone)
    }

    @Test
    fun `without budgets it says what was spent this month, with no progress`() {
        val model = figures(snapshot(remaining = -4200000, spent = 4200000, budgetTotal = 0))
        assertEquals("Gastado este mes", model.label)
        assertEquals("$42.000", model.amount)
        assertNull(model.progress)
    }

    @Test
    @Config(qualifiers = "es") // a Spanish phone: with no snapshot, the phone's language
    fun `signed out, or nothing written yet, or an older snapshot, it asks to open Lukitas`() {
        val signedOut = WidgetSnapshot(signedIn = false, locale = "es")
        for (snapshot in listOf(signedOut, null, WidgetSnapshot.parse("""{"v":1,"amount":"$1"}"""))) {
            val model = widgetModel(context, snapshot, now, zone)
            assertTrue("$snapshot", model is WidgetModel.SignedOut)
            assertEquals("Abre Lukitas para empezar", (model as WidgetModel.SignedOut).message)
        }
    }

    @Test
    fun `figures not refreshed for three hours say so, subtly`() {
        assertNull(figures(snapshot(updatedAt = now.minusSeconds(2 * 3600))).stale)
        assertEquals("hace un rato", figures(snapshot(updatedAt = now.minusSeconds(3 * 3600))).stale)
    }

    @Test
    fun `the hidden amount is dots, the label stays`() {
        val model = figures(snapshot(hideAmount = true))
        assertEquals("••••", model.amount)
        assertEquals("Te quedan", model.label)
    }

    @Test
    fun `in English, words and amounts follow the snapshot's language`() {
        val model = figures(snapshot(locale = "en"))
        assertEquals("Left", model.label)
        assertEquals("COP 1,500,000", model.amount)
        assertEquals("October", model.month)
        val signedOut = widgetModel(context, WidgetSnapshot(signedIn = false, locale = "en"), now, zone)
        assertEquals("Open Lukitas to get started", (signedOut as WidgetModel.SignedOut).message)
    }

    @Test
    fun `figures of an earlier month never say this month`() {
        assertEquals("Te quedaron en Septiembre", figures(snapshot(month = "2026-09")).label)
        assertEquals("Te pasaste en Septiembre", figures(snapshot(month = "2026-09", remaining = -1)).label)
        assertEquals(
            "Gastado en Septiembre",
            figures(snapshot(month = "2026-09", budgetTotal = 0)).label,
        )
    }

    @Test
    fun `the month changes at midnight in the phone's zone`() {
        // 2026-11-01 03:00 UTC is still October 31 in Bogotá.
        val model = widgetModel(context, snapshot(), Instant.parse("2026-11-01T03:00:00Z"), zone)
        assertEquals("Te quedan", (model as WidgetModel.Figures).label)
    }

    @Test
    fun `the theme is the app's choice, night when none`() {
        assertEquals(WidgetTheme.NIGHT, widgetModel(context, snapshot(theme = "dark"), now, zone).theme)
        assertEquals(WidgetTheme.DAY, widgetModel(context, snapshot(theme = "light"), now, zone).theme)
        assertEquals(WidgetTheme.SYSTEM, widgetModel(context, snapshot(theme = "system"), now, zone).theme)
        assertEquals(WidgetTheme.NIGHT, widgetModel(context, null, now, zone).theme)
        val signedOut = WidgetSnapshot(signedIn = false, theme = "light")
        assertEquals(WidgetTheme.DAY, widgetModel(context, signedOut, now, zone).theme)
    }

    @Test
    fun `the snapshot reads back what it wrote, and a signed-out one keeps no figure`() {
        val written = snapshot(updatedAt = Instant.parse("2026-10-22T15:30:00Z"))
        assertEquals(written, WidgetSnapshot.parse(written.toJson()))
        val signedOut = WidgetSnapshot.parse(
            """{"v":2,"signedIn":false,"hideAmount":true,"theme":"light","locale":"en"}""",
        )
        assertEquals(WidgetSnapshot(signedIn = false, hideAmount = true, theme = "light", locale = "en"), signedOut)
        // Signed in but missing a figure: never drawn as figures.
        assertEquals(false, WidgetSnapshot.parse("""{"v":2,"signedIn":true,"currency":"COP"}""")!!.signedIn)
    }
}
