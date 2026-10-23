package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.glance.appwidget.testing.unit.assertHasStartActivityClickAction
import androidx.glance.appwidget.testing.unit.isLinearProgressIndicator
import androidx.glance.appwidget.testing.unit.runGlanceAppWidgetUnitTest
import androidx.glance.testing.unit.hasContentDescription
import androidx.glance.testing.unit.hasText
import androidx.test.core.app.ApplicationProvider
import com.andersonlaverde.lukitas.launch.LaunchLinks
import es.antonborri.home_widget.HomeWidgetGlanceState
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.Instant
import java.time.ZoneId

/** Glance rendering tests for each state of both widgets (spec section 7.1). */
@RunWith(RobolectricTestRunner::class)
class WidgetContentTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val zone = ZoneId.of("America/Bogota")
    private val now = Instant.parse("2026-10-22T20:00:00Z")

    private fun snapshot(
        remaining: Long = 150000000,
        spent: Long = 50000000,
        budgetTotal: Long = 200000000,
        updatedAt: Instant = now.minusSeconds(60),
        hideAmount: Boolean = false,
        mood: String = "happy",
    ) = WidgetSnapshot(
        signedIn = true,
        remaining = remaining,
        spent = spent,
        budgetTotal = budgetTotal,
        currency = "COP",
        locale = "es",
        month = "2026-10",
        mood = mood,
        updatedAt = updatedAt,
        hideAmount = hideAmount,
        theme = "dark",
    )

    private fun model(snapshot: WidgetSnapshot?) = widgetModel(context, snapshot, now, zone)

    @Test
    fun `small, signed in with budgets - Te quedan, the amount and ＋ to the add sheet`() =
        runGlanceAppWidgetUnitTest {
            setContext(context)
            provideComposable { SmallWidgetContent(model(snapshot())) }
            onNode(hasText("Te quedan")).assertExists()
            onNode(hasText("$1.500.000")).assertExists()
            onNode(hasContentDescription("Agregar gasto"))
                .assertHasStartActivityClickAction(LaunchLinks.intent(context, LaunchLinks.ADD))
            onNode(hasText("hace un rato")).assertDoesNotExist()
        }

    @Test
    fun `medium, signed in with budgets - Lukitas, the month, the progress, ＋ and 🎤`() =
        runGlanceAppWidgetUnitTest {
            setContext(context)
            provideComposable { MediumWidgetContent(model(snapshot())) }
            onNode(hasContentDescription("Lukitas")).assertExists()
            onNode(hasText("Octubre")).assertExists()
            onNode(hasText("Te quedan")).assertExists()
            onNode(hasText("$1.500.000")).assertExists()
            onNode(isLinearProgressIndicator(0.25f)).assertExists()
            onNode(hasContentDescription("Agregar gasto"))
                .assertHasStartActivityClickAction(LaunchLinks.intent(context, LaunchLinks.ADD))
            onNode(hasContentDescription("Decir o escribir un gasto"))
                .assertHasStartActivityClickAction(LaunchLinks.intent(context, LaunchLinks.CAPTURE))
        }

    @Test
    fun `without budgets - Gastado este mes, what was spent, no progress`() =
        runGlanceAppWidgetUnitTest {
            setContext(context)
            provideComposable {
                MediumWidgetContent(model(snapshot(remaining = -4200000, spent = 4200000, budgetTotal = 0)))
            }
            onNode(hasText("Gastado este mes")).assertExists()
            onNode(hasText("$42.000")).assertExists()
            onNode(hasText("Te quedan")).assertDoesNotExist()
        }

    @Test
    fun `small, without budgets - Gastado este mes`() = runGlanceAppWidgetUnitTest {
        setContext(context)
        provideComposable {
            SmallWidgetContent(model(snapshot(remaining = -4200000, spent = 4200000, budgetTotal = 0)))
        }
        onNode(hasText("Gastado este mes")).assertExists()
        onNode(hasText("$42.000")).assertExists()
    }

    @Test
    fun `signed out - Abre Lukitas para empezar, and no amount at all`() {
        for (draw in listOf<@androidx.compose.runtime.Composable (WidgetModel) -> Unit>(
            { SmallWidgetContent(it) },
            { MediumWidgetContent(it) },
        )) {
            runGlanceAppWidgetUnitTest {
                setContext(context)
                provideComposable { draw(model(WidgetSnapshot(signedIn = false, locale = "es"))) }
                onNode(hasText("Abre Lukitas para empezar")).assertExists()
                onNode(hasText("$")).assertDoesNotExist()
                onNode(hasContentDescription("Agregar gasto")).assertDoesNotExist()
            }
        }
    }

    @Test
    fun `offline - the last figure, with a subtle hace un rato`() = runGlanceAppWidgetUnitTest {
        setContext(context)
        provideComposable {
            MediumWidgetContent(
                model(snapshot(updatedAt = now.minusSeconds(3600)).copy(refreshFailedAt = now.minusSeconds(60))),
            )
        }
        onNode(hasText("$1.500.000")).assertExists()
        onNode(hasText("hace un rato")).assertExists()
    }

    @Test
    fun `amount hidden - nothing about the money on either size, read aloud as hidden`() {
        val over = snapshot(remaining = -50000000, spent = 250000000, hideAmount = true, mood = "worried")
        for (draw in listOf<@androidx.compose.runtime.Composable (WidgetModel) -> Unit>(
            { SmallWidgetContent(it) },
            { MediumWidgetContent(it) },
        )) {
            runGlanceAppWidgetUnitTest {
                setContext(context)
                provideComposable { draw(model(over)) }
                onNode(hasText("••••")).assertExists()
                onNode(hasContentDescription("Monto oculto")).assertExists()
                onNode(hasText("$")).assertDoesNotExist()
                onNode(hasText("Te pasaste")).assertDoesNotExist()
                onNode(hasText("Te quedan")).assertDoesNotExist()
                onNode(hasText("Este mes")).assertExists()
                onNode(hasContentDescription("del presupuesto")).assertDoesNotExist()
                onNode(isLinearProgressIndicator(1f)).assertDoesNotExist()
            }
        }
    }

    @Test
    fun `the bar is read aloud with its percentage`() = runGlanceAppWidgetUnitTest {
        setContext(context)
        provideComposable { MediumWidgetContent(model(snapshot())) }
        onNode(hasContentDescription("25 % del presupuesto gastado")).assertExists()
    }

    @Test
    fun `worried - Lukitas' worried face`() = runGlanceAppWidgetUnitTest {
        setContext(context)
        provideComposable { MediumWidgetContent(model(snapshot(mood = "worried"))) }
        onNode(hasContentDescription("Lukitas")).assertExists()
    }

    /** Review Focus 4, as the widget reads its stored state: what Dart writes at a sign-out. */
    @Test
    @Config(qualifiers = "es")
    fun `after sign out the widget never shows the previous figure`() {
        val prefs = WidgetSnapshot.preferences(context)
        prefs.edit().putString(WidgetSnapshot.KEY, snapshot().copy(updatedAt = Instant.now()).toJson()).commit()
        for (size in WidgetSize.entries) {
            runGlanceAppWidgetUnitTest {
                setContext(context)
                setState(HomeWidgetGlanceState(prefs))
                provideComposable { StoredWidgetContent(size) }
                onNode(hasText("$1.500.000")).assertExists()
            }
        }

        // lib/home/widget_snapshot.dart's signedOutSnapshot, as SessionController.signOut writes it.
        prefs.edit()
            .putString(WidgetSnapshot.KEY, """{"v":3,"signedIn":false,"hideAmount":false,"theme":"dark","locale":"es"}""")
            .commit()
        for (size in WidgetSize.entries) {
            runGlanceAppWidgetUnitTest {
                setContext(context)
                setState(HomeWidgetGlanceState(prefs))
                provideComposable { StoredWidgetContent(size) }
                onNode(hasText("Abre Lukitas para empezar")).assertExists()
                onNode(hasText("$1.500.000")).assertDoesNotExist()
                onNode(hasText("$")).assertDoesNotExist()
            }
        }

        // A phone still holding a version 1 snapshot (written before this version) shows no figure.
        prefs.edit()
            .putString(WidgetSnapshot.KEY, """{"v":1,"kind":"remaining","amount":"$1.500.000","month":"2026-10"}""")
            .commit()
        for (size in WidgetSize.entries) {
            runGlanceAppWidgetUnitTest {
                setContext(context)
                setState(HomeWidgetGlanceState(prefs))
                provideComposable { StoredWidgetContent(size) }
                onNode(hasText("Abre Lukitas para empezar")).assertExists()
                onNode(hasText("$1.500.000")).assertDoesNotExist()
            }
        }
    }
}
