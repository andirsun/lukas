package com.andersonlaverde.lukitas.notices

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import com.andersonlaverde.lukitas.R

/**
 * One notification channel per notice, so each can be silenced on its own in the phone's settings.
 * Their names are the phone's language (that is where they are read); the notices' words follow the
 * app's own language choice ([NoticeText]).
 */
object NoticeChannels {
    const val DUE = "payments_due"
    const val GUEST = "guest_warning"

    /** Creates the channels, or renames them for the phone's language; nothing else changes. */
    fun ensure(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(DUE, context.getString(R.string.notice_channel_due), NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = context.getString(R.string.notice_channel_due_description) },
        )
        manager.createNotificationChannel(
            NotificationChannel(GUEST, context.getString(R.string.notice_channel_guest), NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = context.getString(R.string.notice_channel_guest_description) },
        )
    }
}
