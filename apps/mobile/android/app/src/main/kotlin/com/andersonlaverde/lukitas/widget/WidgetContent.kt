package com.andersonlaverde.lukitas.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.Action
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.andersonlaverde.lukitas.MainActivity
import com.andersonlaverde.lukitas.R
import com.andersonlaverde.lukitas.launch.LaunchLinks
import es.antonborri.home_widget.HomeWidgetGlanceState
import java.time.Instant
import java.time.ZoneId

/** The two widgets: small (2×1) and medium (4×2). */
enum class WidgetSize { SMALL, MEDIUM }

/**
 * The colours the widget uses, from the app's tokens (lib/theme/tokens.g.dart, generated from
 * docs/design/system/project/tokens.json): night, then day. test/tooling/widget_android_test.dart
 * checks every value against the tokens.
 */
object WidgetPalette {
    // name to (night, day), as ARGB.
    val tokens: Map<String, Pair<Long, Long>> = mapOf(
        "surface" to (0xFF241F48 to 0xFFFFFFFF),
        "ink" to (0xFFF3F0FF to 0xFF221A47),
        "inkMuted" to (0xFFB9B2E0 to 0xFF5B5285),
        "brand" to (0xFF7C4DFF to 0xFF7B3DF0),
        "onBrand" to (0xFFFFFFFF to 0xFFFFFFFF),
        "stroke" to (0xFF2D2660 to 0xFFE6DEFC),
        "good" to (0xFF7CFFB2 to 0xFF0B7A46),
        "near" to (0xFFFFB547 to 0xFFA85A00),
        "over" to (0xFFFF5C7A to 0xFFC2194A),
    )

    /** [name]'s colour in [theme]: fixed for night or day, following the phone for "system". */
    fun color(name: String, theme: WidgetTheme): ColorProvider {
        val (night, day) = tokens.getValue(name)
        return when (theme) {
            WidgetTheme.NIGHT -> ColorProvider(Color(night))
            WidgetTheme.DAY -> ColorProvider(Color(day))
            WidgetTheme.SYSTEM -> ColorProvider(day = Color(day), night = Color(night))
        }
    }
}

private fun toneColor(tone: Tone): String = when (tone) {
    Tone.GOOD -> "good"
    Tone.NEAR -> "near"
    Tone.OVER -> "over"
}

/** Opens the app on home (a tap anywhere but the buttons). */
@Composable
private fun openApp(): Action = actionStartActivity<MainActivity>()

@Composable
private fun linkAction(link: android.net.Uri): Action =
    actionStartActivity(LaunchLinks.intent(LocalContext.current, link))

/** A round button: ＋ (filled) or 🎤 (outlined in brand, as on home). */
@Composable
private fun RoundButton(icon: Int, label: String, filled: Boolean, theme: WidgetTheme, action: Action) {
    val brand = WidgetPalette.color("brand", theme)
    Box(
        modifier = GlanceModifier
            .size(44.dp)
            .cornerRadius(22.dp)
            .background(if (filled) brand else WidgetPalette.color("stroke", theme))
            .semantics { contentDescription = label }
            .clickable(action),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            provider = ImageProvider(icon),
            contentDescription = null,
            modifier = GlanceModifier.size(24.dp),
            colorFilter = ColorFilter.tint(if (filled) WidgetPalette.color("onBrand", theme) else brand),
        )
    }
}

@Composable
private fun SignedOutContent(model: WidgetModel.SignedOut, face: Boolean) {
    val theme = model.theme
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetPalette.color("surface", theme))
            .cornerRadius(20.dp)
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .clickable(openApp()),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (face) {
            Image(
                provider = ImageProvider(R.drawable.lukitas_happy),
                contentDescription = LocalContext.current.getString(R.string.widget_lukitas),
                modifier = GlanceModifier.size(64.dp),
            )
            Spacer(GlanceModifier.width(12.dp))
        }
        Text(
            text = model.message,
            maxLines = 2,
            style = TextStyle(
                color = WidgetPalette.color("ink", theme),
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
private fun Figure(model: WidgetModel.Figures, amountSize: Int, labelLines: Int = 1) {
    val theme = model.theme
    Text(
        text = model.label,
        maxLines = labelLines,
        style = TextStyle(color = WidgetPalette.color("inkMuted", theme), fontSize = 12.sp),
    )
    Text(
        text = model.amount,
        maxLines = 1,
        modifier = model.amountDescription?.let { description ->
            GlanceModifier.semantics { contentDescription = description }
        } ?: GlanceModifier,
        style = TextStyle(
            color = WidgetPalette.color("ink", theme),
            fontSize = amountSize.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}

@Composable
private fun Stale(model: WidgetModel.Figures) {
    val stale = model.stale ?: return
    Text(
        text = stale,
        maxLines = 1,
        style = TextStyle(color = WidgetPalette.color("inkMuted", model.theme), fontSize = 10.sp),
    )
}

/** Small (2×1): "Te quedan" and ＋. */
@Composable
fun SmallWidgetContent(model: WidgetModel) {
    if (model is WidgetModel.SignedOut) return SignedOutContent(model, face = false)
    model as WidgetModel.Figures
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetPalette.color("surface", model.theme))
            .cornerRadius(20.dp)
            .padding(horizontal = 14.dp, vertical = 8.dp)
            .clickable(openApp()),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
            // Two lines for the label: "Gastado este mes" does not fit two cells on one.
            Figure(model, amountSize = 20, labelLines = 2)
            Stale(model)
        }
        Spacer(GlanceModifier.width(8.dp))
        RoundButton(
            icon = R.drawable.ic_widget_add,
            label = model.addLabel,
            filled = true,
            theme = model.theme,
            action = linkAction(LaunchLinks.ADD),
        )
    }
}

/** Medium (4×2): Lukitas' face, the month, "Te quedan" with its progress bar, ＋ and 🎤. */
@Composable
fun MediumWidgetContent(model: WidgetModel) {
    if (model is WidgetModel.SignedOut) return SignedOutContent(model, face = true)
    model as WidgetModel.Figures
    val context = LocalContext.current
    val theme = model.theme
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetPalette.color("surface", theme))
            .cornerRadius(20.dp)
            .padding(12.dp)
            .clickable(openApp()),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(
                if (model.mood == Mood.WORRIED) R.drawable.lukitas_worried else R.drawable.lukitas_happy,
            ),
            contentDescription = context.getString(R.string.widget_lukitas),
            modifier = GlanceModifier.size(64.dp),
        )
        Spacer(GlanceModifier.width(10.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                text = model.month,
                maxLines = 1,
                style = TextStyle(
                    color = WidgetPalette.color("brand", theme),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                ),
            )
            Figure(model, amountSize = 24)
            val progress = model.progress
            if (progress != null) {
                Spacer(GlanceModifier.height(6.dp))
                LinearProgressIndicator(
                    progress = progress,
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .cornerRadius(3.dp)
                        .semantics { contentDescription = model.progressDescription.orEmpty() },
                    color = WidgetPalette.color(toneColor(model.tone), theme),
                    backgroundColor = WidgetPalette.color("stroke", theme),
                )
            }
            Stale(model)
        }
        Spacer(GlanceModifier.width(10.dp))
        Column(verticalAlignment = Alignment.CenterVertically) {
            RoundButton(
                icon = R.drawable.ic_widget_add,
                label = model.addLabel,
                filled = true,
                theme = theme,
                action = linkAction(LaunchLinks.ADD),
            )
            Spacer(GlanceModifier.height(8.dp))
            RoundButton(
                icon = R.drawable.ic_widget_mic,
                label = model.captureLabel,
                filled = false,
                theme = theme,
                action = linkAction(LaunchLinks.CAPTURE),
            )
        }
    }
}

/** The widget of [size] for what is stored now (home_widget's state: its SharedPreferences). */
@Composable
fun StoredWidgetContent(size: WidgetSize) {
    val preferences = currentState<HomeWidgetGlanceState>().preferences
    val snapshot = WidgetSnapshot.parse(preferences.getString(WidgetSnapshot.KEY, null))
    val model = widgetModel(LocalContext.current, snapshot, Instant.now(), ZoneId.systemDefault())
    when (size) {
        WidgetSize.SMALL -> SmallWidgetContent(model)
        WidgetSize.MEDIUM -> MediumWidgetContent(model)
    }
}
