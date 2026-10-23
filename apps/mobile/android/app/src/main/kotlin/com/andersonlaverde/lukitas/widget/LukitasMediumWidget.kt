package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * The medium widget (4×2, spec section 7.1): Lukitas' face for the month, "Te quedan" with its
 * progress bar, the month, ＋ and 🎤. It draws the same snapshot as [LukitasSmallWidget].
 */
class LukitasMediumWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { StoredWidgetContent(WidgetSize.MEDIUM) }
    }
}

/** Android's entry for [LukitasMediumWidget]. */
class LukitasMediumWidgetReceiver : HomeWidgetGlanceWidgetReceiver<LukitasMediumWidget>() {
    override val glanceAppWidget = LukitasMediumWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        RefreshScheduler.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        RefreshScheduler.cancelIfNoWidgets(context)
    }
}
