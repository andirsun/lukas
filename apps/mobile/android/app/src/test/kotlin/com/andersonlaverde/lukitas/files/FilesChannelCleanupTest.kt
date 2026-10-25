package com.andersonlaverde.lukitas.files

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File
import java.nio.ByteBuffer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

/** The copies made for the share sheet do not stay in the app's cache. */
@RunWith(RobolectricTestRunner::class)
class FilesChannelCleanupTest {
    private class Messenger : BinaryMessenger {
        var handler: BinaryMessenger.BinaryMessageHandler? = null

        override fun send(channel: String, message: ByteBuffer?) {}
        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
            this.handler = handler
        }
    }

    private fun leftover(activity: Activity): File {
        val folder = File(activity.cacheDir, "shared").apply { mkdirs() }
        return File(folder, "export.csv").apply { writeText("a,b") }
    }

    private fun waitUntilGone(file: File) {
        val end = System.currentTimeMillis() + 5_000
        while (file.exists() && System.currentTimeMillis() < end) Thread.sleep(20)
    }

    @Test
    fun aCopyLeftByAnEarlierRunIsDeletedWhenTheChannelStarts() {
        val activity = Robolectric.buildActivity(Activity::class.java).create().get()
        val left = leftover(activity)
        assertTrue(left.exists())
        FilesChannel(activity, Messenger())
        waitUntilGone(left)
        assertFalse(left.exists())
    }

    @Test
    fun theCopiesGoWhenTheChannelIsLetGo() {
        val activity = Robolectric.buildActivity(Activity::class.java).create().get()
        val channel = FilesChannel(activity, Messenger())
        val left = leftover(activity)
        channel.dispose()
        assertFalse(left.exists())
    }

    @Test
    fun clearSharedFromDartDeletesTheCopiesAndAnswers() {
        val activity = Robolectric.buildActivity(Activity::class.java).create().get()
        val messenger = Messenger()
        FilesChannel(activity, messenger)
        val left = leftover(activity)
        var answered = false
        val call = StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall("clearShared", null))
        // The engine hands a message over rewound.
        call.rewind()
        messenger.handler!!.onMessage(call) { reply ->
            // Success: the envelope's first byte is 0.
            assertEquals(0, reply!!.get(0).toInt())
            answered = true
        }
        val end = System.currentTimeMillis() + 5_000
        while (!answered && System.currentTimeMillis() < end) {
            org.robolectric.shadows.ShadowLooper.idleMainLooper()
            Thread.sleep(20)
        }
        assertTrue(answered)
        assertFalse(left.exists())
    }
}
