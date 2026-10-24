package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * The small widget (2×1, spec section 7.1): "Te quedan" and ＋. It draws the snapshot the app and
 * the refresh job keep in home_widget's SharedPreferences ([WidgetSnapshot]).
 */
class LukitasSmallWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { StoredWidgetContent(WidgetSize.SMALL) }
    }
}

/** Android's entry for [LukitasSmallWidget]; the app asks it to redraw (lib/home/widget_snapshot.dart). */
class LukitasSmallWidgetReceiver : HomeWidgetGlanceWidgetReceiver<LukitasSmallWidget>() {
    override val glanceAppWidget = LukitasSmallWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        RefreshScheduler.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        RefreshScheduler.cancelIfNoWidgets(context)
    }
}
