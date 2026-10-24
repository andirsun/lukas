package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

/** Redraws every Lukitas widget from the stored snapshot, as home_widget's receiver does. */
object WidgetUpdates {
    suspend fun redrawAll(context: Context) {
        val manager = GlanceAppWidgetManager(context)
        val widgets: List<GlanceAppWidget> = listOf(LukitasSmallWidget(), LukitasMediumWidget())
        for (widget in widgets) {
            for (id in manager.getGlanceIds(widget.javaClass)) {
                // The state is home_widget's SharedPreferences: touching it makes Glance read it again.
                updateAppWidgetState<HomeWidgetGlanceState>(context, HomeWidgetGlanceStateDefinition(), id) { it }
                widget.update(context, id)
            }
        }
    }
}
