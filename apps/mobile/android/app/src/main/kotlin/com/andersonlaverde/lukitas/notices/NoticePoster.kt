package com.andersonlaverde.lukitas.notices

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.andersonlaverde.lukitas.R
import com.andersonlaverde.lukitas.launch.LaunchLinks

/**
 * Posts the two notices with the platform's own notification API. The permission is never asked
 * here (a background job has no screen to ask on): when the person has not allowed notifications,
 * nothing is posted.
 */
class NoticePoster(private val context: Context) {
    /** Whether notices can be posted now (the permission, and the phone's own switch). */
    fun canPost(): Boolean = context.getSystemService(NotificationManager::class.java)
        ?.areNotificationsEnabled() == true

    /** "Hoy vence…" for [names]; false when notifications are not allowed. */
    fun postDue(names: List<String>, language: String?): Boolean = post(
        channel = NoticeChannels.DUE,
        id = DUE_ID,
        text = NoticeText.due(context, names, language),
        language = language,
        // Home, through the app's own not-exported link entry: the widget opens the app the same way.
        tap = LaunchLinks.intent(context, LaunchLinks.DUE),
        category = Notification.CATEGORY_REMINDER,
    )

    /** The 45-day warning; false when notifications are not allowed. */
    fun postGuestWarning(language: String?): Boolean = post(
        channel = NoticeChannels.GUEST,
        id = GUEST_ID,
        text = NoticeText.guestWarning(context, language),
        language = language,
        // "Guarda tu progreso", the screen that adds the email the warning is about.
        tap = LaunchLinks.intent(context, LaunchLinks.PROGRESS),
        category = Notification.CATEGORY_STATUS,
    )

    private fun post(channel: String, id: Int, text: String, language: String?, tap: Intent, category: String): Boolean {
        if (text.isEmpty()) return false
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        if (!manager.areNotificationsEnabled()) return false
        NoticeChannels.ensure(context)
        val tapped = PendingIntent.getActivity(
            context,
            id,
            tap,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_notice)
            .setContentTitle(NoticeText.localized(context, language).getString(R.string.notice_title))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setCategory(category)
            .setContentIntent(tapped)
            .setAutoCancel(true)
            .build()
        manager.notify(id, notification)
        return true
    }

    companion object {
        const val DUE_ID = 1601
        const val GUEST_ID = 1602
    }
}
